#!/usr/bin/perl -w

use lib '../lib';

use threads;
use Thread::Queue;

use WebSocketIOManager;
use Protocol::WebSocket;

package FakeWebSocketEngine;
use parent 'AbstractWebSocketEngine';

sub new {
    my $class = shift;

    return $class->SUPER::new(@_);
};

sub process_text_data {
    my ( $self, $text, $client ) = @_;
    return $text;
};

sub process_binary_data {
    my ( $self, $text, $client ) = @_;
    return 24;
};

sub process_pong_data {
    my ( $self, $text, $client ) = @_;
    return $text;
};

sub process_ping_data {
    my ( $self, $bytes, $client ) = @_;
    return $bytes;
};

sub process_client_disconnecting {
    my ( $self, $bytes, $client ) = @_;
    return 42;
};


sub process_continuation_data {
    my ( $self, $bytes, $client, $opcode, $fin ) = @_;
    return $bytes;
};

package tests;
use Test::More tests => 20;

my $io_manager = WebSocketIOManager->new;
my $engine = FakeWebSocketEngine->new;
my $client = WebSocketClient->new;

# Continuation frame
my $frame = Protocol::WebSocket::Frame->new( buffer => "buffer", type => "continuation", fin => 0);
$frame->append("some text");
#should disconnect

# Fragmentation tests
my $firstFragmentationFrame = Protocol::WebSocket::Frame->new( buffer => "first", type => "text", fin => 0);
my $secondFragmentationFrame = Protocol::WebSocket::Frame->new( buffer => "second", type => "continuation", fin => 0);
my $thirdFragmentationFrame_final = Protocol::WebSocket::Frame->new( buffer => "third", type => "continuation", fin => 1);


is( $io_manager->process_websocket_data($engine, $firstFragmentationFrame, $client), "first",
   'processing websocket data with binary frame, correct WebSocketEngine method was called' );

is( $client->continuation_opcode, 0x01,
   'client has correctly set continuation opcode for client when continuation frame arrived' );

is( $io_manager->process_websocket_data($engine, $secondFragmentationFrame, $client), "second",
   'processing websocket data with binary frame, correct WebSocketEngine method was called' );

is( $client->continuation_opcode, 0x01,
   'client has still correctly set continuation opcode for client when continuation frame arrived' );

is( $io_manager->process_websocket_data($engine, $thirdFragmentationFrame_final, $client), "third",
   'processing websocket data with binary frame, correct WebSocketEngine method was called' );

is( $client->continuation_opcode, undef,
   'client has still correctly set continuation opcode for client when continuation frame arrived' );


# Fragmentation with control frame inside
$firstFragmentationFrame = Protocol::WebSocket::Frame->new( buffer => "first", type => "text", fin => 0);
$secondFragmentationFrame = Protocol::WebSocket::Frame->new( buffer => "second", type => "continuation", fin => 0);
$thirdFragmentationFrame_final = Protocol::WebSocket::Frame->new( buffer => "third", type => "continuation", fin => 1);
my $ping_frame = Protocol::WebSocket::Frame->new( buffer => "ping", type => "ping");


is( $io_manager->process_websocket_data($engine, $firstFragmentationFrame, $client), "first",
   'processing websocket data with continuation frame, correct WebSocketEngine method was called' );

is( $client->continuation_opcode, 0x01,
   'client has correctly set continuation opcode for client when continuation frame arrived' );

is( $io_manager->process_websocket_data($engine, $secondFragmentationFrame, $client), "second",
   'processing websocket data with continuation frame, correct WebSocketEngine method was called' );

is( $client->continuation_opcode, 0x01,
   'client has still correctly set continuation opcode for client when continuation frame arrived' );

is( $io_manager->process_websocket_data($engine, $ping_frame, $client), "ping",
   'processing websocket ping, should not effect processing of fragmentation' );

is( $client->continuation_opcode, 0x01,
   'client has still correctly set continuation opcode for client when continuation frame arrived' );

is( $io_manager->process_websocket_data($engine, $thirdFragmentationFrame_final, $client), "third",
   'processing websocket data with continuation frame, correct WebSocketEngine method was called' );

is( $client->continuation_opcode, undef,
   'client has still correctly set continuation opcode for client when continuation frame arrived' );