#!/usr/bin/perl -w

use lib '../lib';

use strict;
use warnings;

use Test::More tests => 11;
use WebSocketMessage;
use ThreadSafeHash;

my $text_message = WebSocketMessage->new( type => "text", buffer => "some text" );

ok( defined $text_message, 'new() returned something' );
ok( $text_message->isa('WebSocketMessage'), 'and it is the right class' );
ok( $text_message->is_text, 'and it has correct type' );


my $ping_message = WebSocketMessage->new( type => "ping", buffer => "some text" );

ok( defined $ping_message, 'new() returned something' );
ok( $ping_message->is_ping, 'it is ping' );

my $pong_message = WebSocketMessage->new( type => "pong", buffer => "some text" );

ok( defined $pong_message, 'new() returned something' );
ok( $pong_message->is_pong, 'it is pong' );

my $close_message = WebSocketMessage->new( type => "close", buffer => "some text" );

ok( defined $close_message, 'new() returned something' );
ok( $close_message->is_close, 'it is close' );


my $handshake_message = WebSocketMessage->new( type => "handshake", buffer => "some text" );

ok( defined $pong_message, 'new() returned something' );
ok( $handshake_message->is_handshake, 'it is handshake' );


