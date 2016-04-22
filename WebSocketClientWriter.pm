package WebSocketClientWriter;

use strict;
use warnings;

use Protocol::WebSocket;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless { }, $class;

    return $self;
}

sub send_text_to_client {
    my ( $self, $client, $text ) = @_;

    my $frame = Protocol::WebSocket::Frame->new($text);
    $self->enqueue_frame_for_client ( $client, $frame );
}

sub send_text_to_clients {
    my ( $self, $text, $clients ) = @_;

		unless (defined $clients) {
		die "ThreadSafeHash with WebSocketClients was not supplied."
	}


    my $frame = Protocol::WebSocket::Frame->new($text);

    $clients->map_action(
        sub {
            my ( $id, $client ) = @_;
		 $client->write_buffer->enqueue($frame);
        }
    );
}

sub enqueue_frame_for_client {
    my ( $self, $client, $frame ) = @_;

	unless (defined $client) {
		die "WebSocketClient was not supplied."
	}

    $client->write_buffer->enqueue($frame);
}

sub ping_client {
    my ( $self, $client ) = @_;

		unless (defined $client) {
		die "WebSocketClient was not supplied."
	}


    my $frame_to_send = Protocol::WebSocket::Frame->new( type => 'ping' );
    $frame_to_send->append('ping');

    $client->write_buffer->insert( 0, $frame_to_send );
}

sub close_client {
    my ( $self, $client, $code, $reason ) = @_;

    $client->set_closing(1);
    $client->empty_write_buffer();

    $code   = $code   || 1000;
    $reason = $reason || '';

    my $data = pack( "na*", $code, $reason );
    my $type = { close => $data };
    my $frame = new Protocol::WebSocket::Frame( type => 'close' );

    $frame->append($data);

    $self->enqueue_frame_for_client ( $client, $frame );
}

1;
