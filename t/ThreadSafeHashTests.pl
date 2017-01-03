#!/usr/bin/perl -w

use lib '../lib';

use strict;
use warnings;

use threads;
use threads::shared;

use Test::More tests => 10;
use ThreadSafeHash;

my $thread_safe_hash : shared = shared_clone( ThreadSafeHash->new );

ok( defined $thread_safe_hash, 'new() returned something to shared variable' );
ok( $thread_safe_hash->isa('ThreadSafeHash'), 'and it is the right class' );

ok( $thread_safe_hash->add( 5, 6 ), 'add value 6 to wth key 5' );
is( $thread_safe_hash->contains(5),
    1, 'hash contains value where key equals 5' );
is( $thread_safe_hash->get_value(5),
    6, 'hash contains correct value where key equals 5' );
is( $thread_safe_hash->get_value(0),
    undef, 'hash does not contain value for given key, undef is returned' );

my ( $tKey, $tValue );

$thread_safe_hash->map_action(
    sub {
        my ( $key, $value ) = @_;
        $tKey   = $key;
        $tValue = $value;
    }
);

is( $tKey,   5, 'map_action subroutine runned fine for key in hash' );
is( $tValue, 6, 'map_action subroutine runned fine for value in hash' );

is( $thread_safe_hash->remove(5),
    6, 'remove key value pair where key equals 5' );
is( $thread_safe_hash->contains(5),
    0, 'hash does not contain value where key equals 5' );

