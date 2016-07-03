#!/usr/bin/perl -w

use lib '../lib';

use Test::More tests => 20;
use threads;
use threads::shared;
use WebSocketClient;
use ThreadSafeHash;
use WebSocketClientWriter;
use Protocol::WebSocket::Frame;


my $thread_safe_hash : shared = shared_clone( ThreadSafeHash->new );
ok( defined $thread_safe_hash, 'thread safe hash is defined' );

my $client : shared = WebSocketClient->new( id => 5 );
ok( defined $client,                 'client is defined' );
ok( $client->isa('WebSocketClient'), 'and it is the WebSocketClient class' );
ok( $thread_safe_hash->add( $client->id(), $client ),
    'add client to thread safe hash' );

my $writer = WebSocketClientWriter->new;
ok( defined $writer, 'new returned something to variable' );
ok(
    $writer->isa('WebSocketClientWriter'),
    'and it is the WebSocketClientWriter class'
);

ok( $writer->send_text_to_client( 'test message', $client ), 'writing to client' );

my $frame;
ok( $frame = $client->write_buffer->dequeue(), 'checking client buffer' );
ok( defined $frame, 'buffer contains data' );
ok(
    $frame->isa('Protocol::WebSocket::Frame'),
    'and it is the Protocol::WebSocket::Frame class'
);

my $result = Protocol::WebSocket::Frame->new;
$result->append($frame->to_bytes);
is( $result->next_bytes, 'test message', 'frame with correct data was inserted into client\'s buffer' );

my $client2 : shared = WebSocketClient->new( id => 6 );
$thread_safe_hash->add( $client2->id, $client2 );

ok( $writer->send_text_to_clients('test message to all', $thread_safe_hash), 'writing to all clients, two clients are in supplied hash' );

ok( $frame = $client->write_buffer->dequeue(), 'checking first client\'s buffer' );
ok( defined $frame, 'buffer contains data' );
ok(
    $frame->isa('Protocol::WebSocket::Frame'),
    'and it is the Protocol::WebSocket::Frame class'
);

$result = Protocol::WebSocket::Frame->new;
$result->append($frame->to_bytes);
is( $result->next_bytes, 'test message to all', 'frame with correct data was inserted into first client\'s buffer' );

my $frame2;
ok( $frame2 = $client2->write_buffer->dequeue(),
    'checking second client\'s buffer' );
ok( defined $frame2, 'buffer contains data' );
ok(
    $frame2->isa('Protocol::WebSocket::Frame'),
    'and it is the Protocol::WebSocket::Frame class'
);

$result = Protocol::WebSocket::Frame->new;
$result->append($frame2->to_bytes);
is( $result->next_bytes, 'test message to all', 'frame with correct data was inserted into second client\'s buffer' );

