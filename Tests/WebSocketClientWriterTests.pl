#!/usr/bin/perl -w
use lib "/home/ivann/Downloads/PerlSocket/";
use Test::More tests => 19;
use Thread::Queue;
use WebSocketClient;
use ThreadSafeHash;
use WebSocketClientWriter;
use Data::Dumper;

my $thread_safe_hash : shared = ThreadSafeHash->new;
ok( defined $thread_safe_hash, 'thread safe hash is defined' );

my $client : shared = WebSocketClient->new( id => 5 );
ok( defined $client,                 'client is defined' );
ok( $client->isa('WebSocketClient'), 'and it is the WebSocketClient class' );
ok( $thread_safe_hash->Add( $client->id(), $client ),
    'add client to thread safe hash' );

my $writer = WebSocketClientWriter->new( clients => $thread_safe_hash );
ok( defined $writer, 'new() returned something to variable' );
ok(
    $client->isa('WebSocketClientWriter'),
    'and it is the WebSocketClientWriter class'
);

ok( $writer->write_to_client( 5, "test message" ), 'writing to client' );

my $frame;
ok( $frame = $client->writeBuffer->dequeue(), 'checking client buffer' );
ok( defined $frame, 'buffer contains data' );
ok(
    $frame->isa('Protocol::WebSocket::Frame'),
    'and it is the Protocol::WebSocket::Frame class'
);

my $client2 : shared = WebSocketClient->new( id => 6 );
ok( defined $client2,                 'client is defined' );
ok( $client2->isa('WebSocketClient'), 'and it is the WebSocketClient class' );
ok(
    $thread_safe_hash->Add( $client2->id(), $client2 ),
    'add another client to thread safe hash'
);

ok( $writer->write_to_all_clients("test message"), 'writing to all clients' );

ok( $frame = $client->writeBuffer->dequeue(), 'checking client buffer' );
ok( defined $frame, 'buffer contains data' );
ok(
    $frame->isa('Protocol::WebSocket::Frame'),
    'and it is the Protocol::WebSocket::Frame class'
);

my $frame2;
ok( $frame2 = $client2->writeBuffer->dequeue(),
    'checking another client buffer' );
ok( defined $frame2, 'another buffer contains data' );
ok(
    $frame2->isa('Protocol::WebSocket::Frame'),
    'and it is the Protocol::WebSocket::Frame class'
);

print Dumper($thread_safe_hash);
