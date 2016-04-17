#!/usr/bin/perl -w
use lib "/home/ivann/Downloads/PerlSocket/";
use threads;
use threads::shared;
use Test::More tests => 11;
use ThreadSafeHash;
use ReadJob;
use Data::Dumper;

my $thread_safe_hash : shared = shared_clone( ThreadSafeHash->new );

ok( defined $thread_safe_hash, 'new() returned something to shared variable' );
ok( $thread_safe_hash->isa('ThreadSafeHash'), 'and it is the right class' );

ok( $thread_safe_hash->Add( 5, 6 ), 'add value 6 to wth key 5' );
is( $thread_safe_hash->Contains(5),
    1, 'hash contains value where key equals 5' );
is( $thread_safe_hash->GetValue(5),
    6, 'hash contains correct value where key equals 5' );
is( $thread_safe_hash->GetValue(0),
    undef, 'hash does not contain value for given key, undef is returned' );

my ( $tKey, $tValue );

$thread_safe_hash->MapAction(
    sub {
        my ( $key, $value ) = @_;
        $tKey   = $key;
        $tValue = $value;
    }
);

is( $tKey,   5, 'MapAction subroutine runned fine for key in hash' );
is( $tValue, 6, 'MapAction subroutine runned fine for value in hash' );

is( $thread_safe_hash->Remove(5),
    6, 'remove key value pair where key equals 5' );
is( $thread_safe_hash->Contains(5),
    0, 'hash does not contain value where key equals 5' );

my $thr3 = threads->create(
    sub {
        my $lock = $thread_safe_hash->thread_lock;
        lock($lock);
        my $hash = $thread_safe_hash->Hash();
        for ( my $i = 100 ; $i <= 200 ; $i++ ) {
            $hash->{$i} = 1;
        }
    }
);

my $thr4 = threads->create(
    sub {
        my $lock = $thread_safe_hash->thread_lock;
        lock($lock);
        my $hash = $thread_safe_hash->Hash();
        for ( my $i = 100 ; $i <= 200 ; $i++ ) {
            $hash->{$i} = 2;
        }
    }
);

$thr3->join();
$thr4->join();

$check = 0;
my $hash = $thread_safe_hash->Hash();
for ( my $i = 100 ; $i <= 200 ; $i++ ) {
    if ( $hash->{$i} == 1 ) {
        $check = 1;
    }
}
print Dumper($thread_safe_hash);

is( $check, 0, 'thread lock is working ok' );
