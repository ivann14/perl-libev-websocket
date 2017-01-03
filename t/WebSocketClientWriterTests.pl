#!/usr/bin/perl -w

use lib '../lib';

use strict;
use warnings;

use Test::More tests => 28;
use threads;
use threads::shared;
use WebSocketClient;
use ThreadSafeHash;
use WebSocketClientWriter;
use WebSocketMessage;

my $thread_safe_hash : shared = shared_clone( ThreadSafeHash->new );
ok( defined $thread_safe_hash, 'thread safe hash is defined' );

my $client : shared = WebSocketClient->new( id => 5 );
ok( defined $client,                 'client is defined' );
ok( $client->isa('WebSocketClient'), 'and it is the WebSocketClient class' );
ok( $thread_safe_hash->add( $client->id(), $client ),
    'add client to thread safe hash' );

WebSocketClientWriter::send_text_to_client( 'test message', $client ); print "Writing to client.\n";

my $message;
ok( $message = $client->write_buffer->dequeue(), 'checking client buffer' );
ok( defined $message, 'buffer contains data' );
ok(
    $message->isa('WebSocketMessage'),
    'and it is the WebSocketMessage class'
);

my $result = Protocol::WebSocket::Frame->new;
$result->append($message->get_data);
is( $result->next_bytes, 'test message', 'message with correct data was inserted into client\'s buffer' );

my $client2 : shared = WebSocketClient->new( id => 6 );
$thread_safe_hash->add( $client2->id, $client2 );

WebSocketClientWriter::send_text_to_clients('test message to all', $thread_safe_hash); print "Writing to all clients.\n";

ok( $message = $client->write_buffer->dequeue(), 'checking first client\'s buffer' );
ok( defined $message, 'buffer contains data' );
ok(
    $message->isa('WebSocketMessage'),
    'and it is the WebSocketMessage class'
);

$result = Protocol::WebSocket::Frame->new;
$result->append($message->get_data);
is( $result->next_bytes, 'test message to all', 'message with correct data was inserted into first client\'s buffer' );

my $message2;
ok( $message2 = $client2->write_buffer->dequeue(),
    'checking second client\'s buffer' );
ok( defined $message2, 'buffer contains data' );
ok(
    $message2->isa('WebSocketMessage'),
    'and it is the WebSocketMessage class'
);

$result = Protocol::WebSocket::Frame->new;
$result->append($message2->get_data);
is( $result->next_bytes, 'test message to all', 'message with correct data was inserted into second client\'s buffer' );

my $client3 = WebSocketClient->new( id => 14 );

print "Sending binary to client.\n";
my $data = "\x20" x 100;
WebSocketClientWriter::send_binary_to_client( $data, $client3 );
ok( $client3->write_buffer->peek->is_binary, 'first message is binary' );

$client3->empty_write_buffer;
print "Sending text fragment to client.\n";
WebSocketClientWriter::send_text_to_client( 'test', $client3, 0 );
$client3->write_buffer->peek->get_data;
ok( $client3->write_buffer->peek->is_text, 'fragment is text' );
is( $client3->write_buffer->peek->is_final_part, 0, 'message is not final part of continuation frames' );

$client3->empty_write_buffer;
print "Sending continuation to client.\n";
my $data1 = "\x20" x 100;
WebSocketClientWriter::send_continuation_to_client( $data1, $client3, 0 );
ok( $client3->write_buffer->peek->is_continuation, 'message is continuation' );
is( $client3->write_buffer->peek->is_final_part, 0, 'message is not final part of continuation frames' );

WebSocketClientWriter::send_text_to_client( 'test message', $client3 );
WebSocketClientWriter::send_text_to_client( 'test message', $client3 );
print "Writing to client twice text.\n";

print "Pinging client.\n";
WebSocketClientWriter::ping_client( $client3, 'pingtest' );
ok( $client3->write_buffer->peek->is_ping, 'first message is ping' );

print "Send pong to client.\n";
WebSocketClientWriter::send_pong_to_client( $client3, 'pongtest' );
ok( $client3->write_buffer->peek->is_pong, 'first message is pong' );

print "Send close to client.\n";
WebSocketClientWriter::close_client( $client3, 1000 );
ok( $client3->write_buffer->peek->is_pong, 'first message is not close' );

print "Send close immediately to client.\n";
WebSocketClientWriter::close_client_immediately( $client3, 1000 );
ok( $client3->write_buffer->peek->is_close, 'first message is close' );

print "Enqueue message.\n";
WebSocketClientWriter::enqueue_message_for_client( $client3, "message" );
ok( $client3->write_buffer->peek->is_close, 'first message is still close' );

print "Enqueue message to first place.\n";
WebSocketClientWriter::enqueue_message_for_client( $client3, "message", 1 );
is( $client3->write_buffer->peek, "message", 'first message correctly inserted' );

print "Enqueue handshake.\n";
$client3->empty_write_buffer;
WebSocketClientWriter::send_handshake_response_to_client( "message", $client3 );
ok( $client3->write_buffer->peek->is_handshake, 'message is handshake' );
