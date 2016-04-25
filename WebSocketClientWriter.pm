package WebSocketClientWriter;

use strict;
use warnings;

use Protocol::WebSocket;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {}, $class;

    return $self;
}

sub send_text_to_client {
    my ( $self, $text, $client ) = @_;

    my $frame = Protocol::WebSocket::Frame->new($text);
    $self->enqueue_frame_for_client( $client, $frame );
}

sub send_text_to_clients {
    my ( $self, $text, $clients ) = @_;

    unless ( defined $clients ) {
        die "ThreadSafeHash with WebSocketClients was not supplied.";
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

    unless ( defined $client ) {
        die "WebSocketClient was not supplied.";
    }

    $client->write_buffer->enqueue($frame);
}

sub ping_client {
    my ( $self, $client, $data ) = @_;

    unless ( defined $client ) {
        die "WebSocketClient was not supplied.";
    }

    my $frame_to_send = Protocol::WebSocket::Frame->new( type => 'ping' );
    my $text = $data || 'ping';
    $frame_to_send->append($text);

    $client->write_buffer->insert( 0, $frame_to_send );
}

sub close_client_immediately {
    my ( $self, $client, $code, $reason ) = @_;
    $client->empty_write_buffer();
    $self->close_client( $client, $code, $reason );
}

sub close_client {
    my ( $self, $client, $code, $reason ) = @_;

    $client->set_closing(1);

    $code   = $code   || 1000;
    $reason = $reason || '';

    my $data = pack( "na*", $code, $reason );
    my $type = { close => $data };
    my $frame = new Protocol::WebSocket::Frame( type => 'close' );

    $frame->append($data);

    $self->enqueue_frame_for_client( $client, $frame );
}

1;
__END__

=head1 NAME

WebSocketClientWriter - Enqueues WebSocket frames into client's write buffer

=head1 SYNOPSIS
	$writer = WebSocketClientWriter->new;
	$writer->send_text_to_client("Message", $client);
	$writer->send_text_to_clients("Message for all", $clients);
	$writer->ping_client($client);
	$writer->close_client($client);

$server->run_server();

=head1 DESCRIPTION

This class enqueues WebSocket frames into client's write buffer.
  
=head2 Methods

=over 12

=item C<new>

Constructor.

=item C<send_text_to_client>

Enqueues WebSocket text frame with given text into client's write buffer.

=item C<send_text_to_client>

Enqueues WebSocket text frame with given text into all clients write buffer.

=item C<ping_client>

Inserts a ping frame into client's write buffer.

=item C<close_client>

Enqueues WebSocket close frame with client's write buffer.

=item C<close_client_immediately>

Removes enqueued frames in client's write buffer and then enqueues WebSocket close frame.

=back
