package WebSocketClientWriter;

use strict;
use warnings;

use Protocol::WebSocket;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless { clients => $args{clients} }, $class;

    return $self;
}

sub write_to_client {
    my ( $self, $client_id, $text ) = @_;
    my $frame = Protocol::WebSocket::Frame->new($text);
    $self->send_frame_to_client( $client_id, $frame );
}

sub write_to_all_clients {
    my ( $self, $text, $clients ) = @_;

    $clients = $clients || $self->{clients};
    my $frame = Protocol::WebSocket::Frame->new($text);

    $clients->map_action(
        sub {
            my ( $id, $client ) = @_;
            $self->send_frame_to_client( $id, $frame );
        }
    );
}

sub send_frame_to_client {
    my ( $self, $client_id, $frame ) = @_;

    my $clients = $self->{clients};
    my $client  = $clients->get_value($client_id);
    $self->enqueue_frame_for_client ( $client, $frame );
}

sub enqueue_frame_for_client {
    my ( $self, $client, $frame ) = @_;
    $client->writeBuffer->enqueue($frame);
}

sub ping_client {
    my ( $self, $client ) = @_;

    my $frameToSend = Protocol::WebSocket::Frame->new( type => 'ping' );
    $frameToSend->append('ping');

    $client->writeBuffer->insert( 0, $frameToSend );
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
