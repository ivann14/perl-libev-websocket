use WebSocketServer;
use WebSocketIOManager;
use WebSocketEngine;
use IO::Socket;

my $port = 2222;
my $ip   = "0.0.0.0";

# Inet IPv6
my $server = IO::Socket::INET->new(
    Proto     => "tcp",
    LocalPort => $port,
    LocalHost => $ip,
    Listen    => 1,
    Reuse     => 1,
    Type      => SOCK_STREAM,
    Blocking  => 0,
) or die "Error creating socket $!";

my $server = WebSocketServer->new(
    server                           => $server,
    websocket_engine                 => WebSocketEngine->new(),
    number_of_thread_workers         => 2,
    close_after_no_pong              => 20,
    ping_after_seconds_of_inactivity => 20,
);

$server->run_server();
