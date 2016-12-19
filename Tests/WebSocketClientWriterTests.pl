#!/usr/bin/perl -w

use lib '../lib';

use Test::More tests => 20;
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

ok( WebSocketClientWriter::send_text_to_client( 'test message', $client ), 'writing to client' );

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

ok( WebSocketClientWriter::send_text_to_clients('test message to all', $thread_safe_hash), 'writing to all clients, two clients are in supplied hash' );

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

