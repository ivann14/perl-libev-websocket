#!/usr/bin/perl -w
use lib "/home/ivann/Downloads/PerlSocket/";
use threads;
use threads::shared;
use Test::More tests => 10;
use ThreadSafeHash;
use WebSocketClient;
use WebSocketContext;

my $context = WebSocketContext->new();

ok( defined $context,                 'new() returned something' );
ok( $context->isa('WebSocketContext'), 'and it is the right class' );
ok( defined $context->connected_clients,
    'context->conencted_clients returned something' );
ok( $client->handshake()->isa('ThreadSafeHash'), 'and it is the right class' );
