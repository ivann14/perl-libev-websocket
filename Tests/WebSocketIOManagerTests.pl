#!/usr/bin/perl -w

use lib '../lib';

use FileHandle;
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

package tests;
use Test::More tests => 8;

# Prepare data
my $engine = FakeWebSocketEngine->new;
my $client = WebSocketClient->new;
my $result;

# Test processing websocket data
# Text frame
my $fh = FileHandle->new("DummyData/textFrame.dat", "r");
my $data = WebSocketIOManager::read_from_socket($fh, undef);
$frame = Protocol::WebSocket::Frame->new();
$frame->append($data);
is( $io_manager->process_websocket_data($engine, $frame, $client), 'Hello',
   'processing websocket data with text frame, correct WebSocketEngine subroutine was called with correct input' );

# Ping frame
$fh = FileHandle->new("DummyData/pingFrame.dat", "r");
$data = WebSocketIOManager::read_from_socket($fh, undef);
$frame = Protocol::WebSocket::Frame->new();
$frame->append($data);
is( $io_manager->process_websocket_data($engine, $frame, $client), 'Hello',
   'processing websocket data with ping frame, correct WebSocketEngine method was called with correct input' );

# Pong frame
$fh = FileHandle->new("DummyData/pongFrame.dat", "r");
$data = WebSocketIOManager::read_from_socket($fh, undef);
$frame = Protocol::WebSocket::Frame->new();
$frame->append($data);
is( $io_manager->process_websocket_data($engine, $frame, $client), 'Hello',
   'processing websocket data with pong frame, correct WebSocketEngine method was called with correct input' );

# Close frame
$fh = FileHandle->new("DummyData/closeFrame.dat", "r");
$data = WebSocketIOManager::read_from_socket($fh, undef);
$frame = Protocol::WebSocket::Frame->new();
$frame->append($data);
is( $io_manager->process_websocket_data($engine, $frame, $client), 42,
   'processing websocket data with close frame, correct WebSocketEngine method was called' );

# Binary frame
$fh = FileHandle->new("DummyData/binaryFrame.dat", "r");
$data = WebSocketIOManager::read_from_socket($fh, undef);
$frame = Protocol::WebSocket::Frame->new();
$frame->append($data);
is( $io_manager->process_websocket_data($engine, $frame, $client), 24,
   'processing websocket data with binary frame, correct WebSocketEngine method was called' );