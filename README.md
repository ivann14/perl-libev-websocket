# WebSocket server empowered by libev

This server enables programmers to create applications based on WebSocket protocol without deeper knowledge of the WebSocket protocol.

# Synopsis

    package WebSocketEngine;
    
    use parent 'AbstractWebSocketEngine';
    
    sub process_text_data {
        my ( $self, $text, $client ) = @_;
    
        WebSocketClientWriter::send_text_to_client( $text, $client );
    }
    
    package EchoServer;
    
    my $socket = IO::Socket::INET->new(
        Proto     => "tcp",
        LocalPort => $port,
        LocalHost => $ip,
        Listen    => SOMAXCONN,
        Reuse     => 1,
        Type      => SOCK_STREAM,
        Blocking  => 0,
    );
    
    WebSocketServer->new(
        socket           => $socket,
        websocket_engine => WebSocketEngine->new(
            close_after_no_pong              => 100,
            ping_after_seconds_of_inactivity => 60
        ),
    )->run_server();

# Description

To create application based on this library, you need to check the documentation of the WebSocketServer module and AbstractWebSocketEngine module.
Then you need to implement your own class derived from AbstractWebSocketEngine.
You can override almost all the methods from the AbstractWebSocketEngine class. To know which methods to override and what effect they will have on your application you need to check 
documentation inside AbstractWebSocketEngine.

# Examples

Contains two applications to show basic possibilities of the library.
Firstly you can see Echo server that echoes client's messages. In the WebSocketEngine class you can see performance optimization by
starting and stoping libev's watcher objects.
In the Chat application you can see the usage of the worker thread, because iterating through all connected clients may block the event loop
and decrease performance of the application.

