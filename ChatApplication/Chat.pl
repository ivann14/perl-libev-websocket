use strict;
use warnings;

use lib '../lib';

use WebSocketServer;
use WebSocketEngine;
use IO::Socket;

my $port = 2222;
my $ip   = "0.0.0.0";

my $socket = IO::Socket::INET->new(
    Proto     => "tcp",
    LocalPort => $port,
    LocalHost => $ip,
    Listen    => 5,
    Reuse     => 5,
    Type      => SOCK_STREAM,
    Blocking  => 0,
) or die "Error creating socket $!";

my $server = WebSocketServer->new(
    socket           => $socket,
    websocket_engine => WebSocketEngine->new(
        close_after_no_pong              => 10,
        ping_after_seconds_of_inactivity => 10
    ),
    number_of_thread_workers => 2,
);

$server->run_server();
