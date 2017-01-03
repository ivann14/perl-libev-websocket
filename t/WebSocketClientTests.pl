#!/usr/bin/perl -w

use lib '../lib';

use strict;
use warnings;

use Test::More tests => 22;
use WebSocketClient;
use ThreadSafeHash;

my $client : shared =
  WebSocketClient->new( id => 5, resource_name => 'test', last_active => '15:45' );

ok( defined $client, 'new() returned something to shared variable' );
ok( $client->isa('WebSocketClient'), 'and it is the right class' );

ok( defined $client->write_buffer, 'client->write_buffer returned something' );
ok( $client->write_buffer->isa('Thread::Queue'), 'and it is the right class' );

ok( defined $client->id, 'client->id returned something' );
is( $client->id(), 5, 'client->id has correct value' );

ok( defined $client->closing, 'client->closing returned something' );
is( $client->closing, 0, 'client->closing has correct default value' );

ok( defined $client->resource_name, 'client->resource_name returned something' );
is( $client->resource_name, 'test', 'client->closing has correct value' );

ok( defined $client->last_active, 'client->resource_name returned something' );
is( $client->last_active, '15:45', 'client->last_active has correct value' );

$client->set_resource_name ('otherTest');
is( $client->resource_name, 'otherTest', 'client->set_resource_name correctly sets value' );

$client->set_last_active ('12:00');
is( $client->last_active, '12:00', 'client->set_last_active correctly sets value' );

$client->set_closing ('1');
is( $client->closing, '1', 'client->set_closing correctly sets value' );

#Testing WebSocketClient inside a ThreadSafeHash instance
my $thread_safe_hash = ThreadSafeHash->new;
ok( $thread_safe_hash->add( $client->id, $client ),
    'add client to thread safe hash' );
is( $thread_safe_hash->contains( $client->id ),
    1, 'hash contains client with given id' );
is( $thread_safe_hash->get_value(0),
    undef, 'hash return undef for id that does not exist' );

my ( $tKey, $tValue );

$thread_safe_hash->map_action(
    sub {
        my ( $key, $value ) = @_;
        $tKey   = $key;
        $tValue = $value;
    }
);

is( $tKey,   5, 'map_action works fine' );
is( $tValue, $client, 'map_action works fine' );

ok ( $thread_safe_hash->remove(5), 'remove client with id 5' );
is( $thread_safe_hash->contains(5),
    0, 'hash does not contain client with id 5' );
