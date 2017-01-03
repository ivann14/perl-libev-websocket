#!/usr/bin/perl -w

use lib '../lib';
use strict;

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
    die  $text;
};

sub process_binary_data {
    my ( $self, $text, $client ) = @_;
    die  "bin";
};

sub process_pong_data {
    my ( $self, $text, $client ) = @_;
    die 'pong';
};

sub process_ping_data {
    my ( $self, $bytes, $client ) = @_;
    die 'ping';
};

sub process_client_disconnecting {
    my ( $self, $client, $code, $reason ) = @_;
    
    if (defined $code && defined $reason) {
	die $code . $reason;
    }

    die 'close';
};

package tests;
use strict;
use Test::More tests => 6;
use Test::Exception;

# Prepare data
my $engine = FakeWebSocketEngine->new;
my $client = WebSocketClient->new;
my $result;

# Test processing websocket data
# Text frame
my $fh = FileHandle->new("DummyData/textFrame.dat", "r");
my ($data, $bytes_read) = WebSocketIOManager::read_from_socket($fh, undef);
my $frame = Protocol::WebSocket::Frame->new();
$frame->append($data);
throws_ok (sub { WebSocketIOManager::process_websocket_data($engine, $frame, $client) }, '/Hello/',
   'processing websocket data with text frame, correct WebSocketEngine subroutine was called with correct input');

# Ping frame
$fh = FileHandle->new("DummyData/pingFrame.dat", "r");
($data, $bytes_read) = WebSocketIOManager::read_from_socket($fh, undef);
my $frame1 = Protocol::WebSocket::Frame->new();
$frame1->append($data);
throws_ok (sub { WebSocketIOManager::process_websocket_data($engine, $frame1, $client) }, '/ping/',
   'processing websocket data with text frame, correct WebSocketEngine subroutine was called with correct input');

# Pong frame
$fh = FileHandle->new("DummyData/pongFrame.dat", "r");
($data, $bytes_read) = WebSocketIOManager::read_from_socket($fh, undef);
my $frame2 = Protocol::WebSocket::Frame->new();
$frame2->append($data);
throws_ok (sub { WebSocketIOManager::process_websocket_data($engine, $frame2, $client) }, '/pong/',
   'processing websocket data with text frame, correct WebSocketEngine subroutine was called with correct input');

# Close frame
$fh = FileHandle->new("DummyData/closeFrame.dat", "r");
($data, $bytes_read) = WebSocketIOManager::read_from_socket($fh, undef);
my $frame3 = Protocol::WebSocket::Frame->new();
$frame3->append($data);
throws_ok (sub { WebSocketIOManager::process_websocket_data($engine, $frame3, $client) }, '/close/',
   'processing websocket data with text frame, correct WebSocketEngine subroutine was called with correct input');

# Binary frame
$fh = FileHandle->new("DummyData/binaryFrame.dat", "r");
($data, $bytes_read) = WebSocketIOManager::read_from_socket($fh, undef);
my $frame4 = Protocol::WebSocket::Frame->new();
$frame4->append($data);
throws_ok (sub { WebSocketIOManager::process_websocket_data($engine, $frame4, $client) }, '/bin/',
   'processing websocket data with text frame, correct WebSocketEngine subroutine was called with correct input');


# Close frame wih code and reason
my $body = pack('na*', '1005');
$body .= Encode::encode ('UTF-8', "test");

my $frame5 = Protocol::WebSocket::Frame->new(buffer => $body, opcode=> 8, type=> 'close');

my $frame6 = Protocol::WebSocket::Frame->new;
$frame6->append($frame5->to_bytes);
throws_ok (sub { WebSocketIOManager::process_websocket_data($engine, $frame6, $client) }, '/1005test/',
   'processing websocket data with text frame, correct WebSocketEngine subroutine was called with correct input');