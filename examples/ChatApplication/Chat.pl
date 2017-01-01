use strict;
use warnings;

use lib '../../lib';

use WebSocketServer;
use ChatEngine;
use IO::Socket;

my $port = 2222;
my $ip   = "0.0.0.0";

my $socket = IO::Socket::INET->new(
    Proto     => 'tcp',
    LocalPort => $port,
    LocalHost => $ip,
    Listen    => 5,
    Reuse     => 1,
    Type      => SOCK_STREAM,
    Blocking  => 0,
);

WebSocketServer->new(
    socket           => $socket,
    websocket_engine => ChatEngine->new(
        ping_after_seconds_of_inactivity => 120,
        close_after_no_pong              => 100
    ),
    prefer_read => 1,
    number_of_thread_workers => 1,
)->run_server();