#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use Test::More;
use Data::Dumper;

use Protocol::WebSocket::Frame;
use Encode;


my $pingBytes = Protocol::WebSocket::Frame->new(buffer => "World", type => "ping", fin => 1 )->to_bytes;
my $pingBytes2 = Protocol::WebSocket::Frame->new(buffer => "World", type => "ping", fin => 1 )->to_bytes;

my $txtMsge = Protocol::WebSocket::Frame->new(buffer => "Ivannis", type => "text", fin => 1 )->to_bytes;

my $firstBytes= Protocol::WebSocket::Frame->new(buffer => "Nata", type => "text", fin => 0 )->to_bytes;
my $secondBytes = Protocol::WebSocket::Frame->new(buffer => "lia", type => "continuation", fin => 0 )->to_bytes;
my $thirdBytes = Protocol::WebSocket::Frame->new(buffer => "lia", type => "continuation", fin => 1 )->to_bytes;
my $fourthBytes = Protocol::WebSocket::Frame->new(buffer => "lia", type => "continuation", fin => 0 )->to_bytes;
my $fifthBytes = Protocol::WebSocket::Frame->new(buffer => "lia", type => "continuation", fin => 0 )->to_bytes;
my $sixthBytes = Protocol::WebSocket::Frame->new(buffer => "lia", type => "continuation", fin => 0 )->to_bytes;


my $f = WebSocketFrame->new();
$f->append($firstBytes);

my ($fin, $opcode, $data) = $f->next_bytes;
is $fin, 0, "ma byt 0";
is $opcode, 1, "ma byt 0";
is $data, 'Nata', "ma byt Nata";
print Dumper($f->{fragments});