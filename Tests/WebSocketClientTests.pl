#!/usr/bin/perl -w

use lib '..';

use Test::More tests => 19;
use Thread::Queue;
use WebSocketClient;
use Protocol::WebSocket::Handshake::Server;
use ThreadSafeHash;

my $thread_safe_hash : shared = ThreadSafeHash->new;
ok( defined $thread_safe_hash, 'thread safe hash is defined' );

my $handshake = Protocol::WebSocket::Handshake::Server->new();
my $client : shared =
  WebSocketClient->new( id => 5, handshake => $handshake );

ok( defined $client, 'new() returned something to shared variable' );
ok( $client->isa('WebSocketClient'), 'and it is the right class' );

ok( defined $client->handshake,      'client->handshake returned something' );
ok( $client->handshake()->isa('Protocol::WebSocket::Handshake::Server'),
    'and it is the right class' );
is( $client->handshake(), $handshake, 'client->handshake has correct value' );

ok( defined $client->writeBuffer, 'client->writeBuffer returned something' );
ok( $client->writeBuffer()->isa('Thread::Queue'), 'and it is the right class' );

ok( defined $client->id, 'client->id returned something' );
is( $client->id(), 5, 'client->id has correct value' );

ok( defined $client->closing, 'client->closing returned something' );
is( $client->closing, 0, 'client->closing has correct default value' );

ok( $thread_safe_hash->Add( $client->id(), $client ),
    'add client to thread safe hash' );
is( $thread_safe_hash->Contains( $client->id() ),
    1, 'hash contains client with given id' );
is( $thread_safe_hash->GetValue(0),
    undef, 'hash return undef for id that does not exist' );

my ( $tKey, $tValue );

$thread_safe_hash->MapAction(
    sub {
        my ( $key, $value ) = @_;
        $tKey   = $key;
        $tValue = $value;
    }
);

is( $tKey,   5, 'MapAction works fine' );
is( $tValue, $client, 'MapAction works fine' );

ok ( $thread_safe_hash->Remove(5), 'remove client with id 5' );
is( $thread_safe_hash->Contains(5),
    0, 'hash does not contain client with id 5' );
