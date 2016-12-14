package WebSocketClientWriter;

use strict;
use warnings;

use WebSocketMessage;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {}, $class;

    return $self;
}

sub send_text_to_client {
    my ( $self, $text, $client ) = @_;

    my $message = WebSocketMessage->new( buffer => $text, type => 'text' );
    $self->enqueue_message_for_client( $client, $message );

    return 1;
}

sub send_text_to_clients {
    my ( $self, $text, $clients ) = @_;

    unless ( defined $clients ) {
        die "ThreadSafeHash with WebSocketClients was not supplied.";
    }

    my $message = WebSocketMessage->new( buffer => $text, type => 'text' );

    $clients->map_action(
       sub {
             my ( $id, $client ) = @_;
             $self-> enqueue_message_for_client($client, $message);
       });

    return 1;
}

sub send_handshake_response_to_client {
    my ( $self, $text, $client ) = @_;

    my $message = WebSocketMessage->new( buffer => $text, type => 'handshake' );
    $self->enqueue_message_for_client( $client, $message );

    return 1;
}

sub enqueue_message_for_client {
    my ( $self, $client, $message ) = @_;

    unless ( defined $client ) {
        die "WebSocketClient was not supplied.";
    }

    unless ( defined $message ) {
        die "WebSocket frame was not supplied.";
    }

    $client->write_buffer->enqueue($message);
}

sub ping_client {
    my ( $self, $client, $data ) = @_;

    unless ( defined $client ) {
        die "WebSocketClient was not supplied.";
    }
	
    my $text = $data || 'ping';
    my $message_to_send = WebSocketMessage->new( buffer => $text, type => 'ping' );
    
    $client->write_buffer->insert( 0, $message_to_send );
}


sub send_pong_to_client {
    my ( $self, $client, $text ) = @_;

    my $message = WebSocketMessage->new( buffer => $text, type => 'pong' );
    $client->write_buffer->insert( 0, $message );

    return 1;
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
    my $message = WebSocketMessage->new( buffer => $data, type => 'close' );

    $self->enqueue_message_for_client( $client, $message );
}

1;
__END__

=head1 NAME

WebSocketClientWriter - Enqueues WebSocket messages into client's write buffer

=head1 SYNOPSIS
	$writer = WebSocketClientWriter->new;
	$writer->send_text_to_client("Message", $client);
	$writer->send_text_to_clients("Message for all", $clients);
	$writer->ping_client($client);
	$writer->ping_client($text, $client);
	$writer->close_client($client);

=head1 DESCRIPTION

This class enqueues WebSocket messages into client's write buffer.
  
=head2 Methods

=over 12

=item C<new>

Constructor.

=item C<send_text_to_client>

Enqueues WebSocket text message with given text into client's write buffer.

=item C<send_text_to_clients>

Enqueues WebSocket text message with given text into all clients write buffer.

=item C<ping_client>

Inserts a ping message into client's write buffer.

=item C<send_pong_to_client>

Inserts a pong message into client's write buffer.

=item C<close_client>

Enqueues WebSocket close message with client's write buffer.

=item C<close_client_immediately>

Removes enqueued frames in client's write buffer and then enqueues WebSocket close message.

=item C<send_handshake_response_to_client>

Inserts a WebSocket handshake response into client's write buffer.

=back
