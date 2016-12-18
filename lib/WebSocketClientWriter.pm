package WebSocketClientWriter;

use strict;
use warnings;

use WebSocketMessage;

sub send_text_to_client {
    my ( $text, $client ) = @_;

    my $message = WebSocketMessage->new( buffer => $text, type => 'text' );
    enqueue_message_for_client( $client, $message );

    return 1;
}

sub send_text_to_clients {
    my ( $text, $clients ) = @_;

    unless ( defined $clients ) {
        die "ThreadSafeHash with WebSocketClients was not supplied.";
    }

    my $message = WebSocketMessage->new( buffer => $text, type => 'text' );

    $clients->map_action(
       sub {
             my ( $id, $client ) = @_;
             enqueue_message_for_client($client, $message);
       });
}

sub send_handshake_response_to_client {
    my ( $text, $client ) = @_;

    my $message = WebSocketMessage->new( buffer => $text, type => 'handshake' );
    enqueue_message_for_client( $client, $message );
}

sub enqueue_message_for_client {
    my ( $client, $message ) = @_;

    unless ( defined $client ) {
        die "WebSocketClient was not supplied.";
    }

    unless ( defined $message ) {
        die "WebSocket frame was not supplied.";
    }

    $client->write_buffer->enqueue($message);
}

sub ping_client {
    my ( $client, $data ) = @_;

    unless ( defined $client ) {
        die "WebSocketClient was not supplied.";
    }
	
    my $text = $data || 'ping';
    my $message_to_send = WebSocketMessage->new( buffer => $text, type => 'ping' );
    
    $client->write_buffer->insert( 0, $message_to_send );
}


sub send_pong_to_client {
    my ( $client, $text ) = @_;

    my $message = WebSocketMessage->new( buffer => $text, type => 'pong' );
    $client->write_buffer->insert( 0, $message );
}

sub close_client_immediately {
    my ( $client, $code, $reason ) = @_;
    $client->empty_write_buffer();
    close_client( $client, $code, $reason );
}

sub close_client {
    my ( $client, $code, $reason ) = @_;

    $client->set_closing(1);

    $code   = $code   || 1000;
    $reason = $reason || '';

    my $data = pack( "na*", $code, $reason );
    my $type = { close => $data };
    my $message = WebSocketMessage->new( buffer => $data, type => 'close' );

    enqueue_message_for_client( $client, $message );
}

1;
__END__

=head1 NAME

WebSocketClientWriter - Enqueues WebSocket messages into client's write buffer

=head1 SYNOPSIS
	WebSocketClientWriter::send_text_to_client("Message", $client);
	WebSocketClientWriter::send_text_to_clients("Message for all", $clients);
	WebSocketClientWriter::ping_client($client);
	WebSocketClientWriter::ping_client($text, $client);
	WebSocketClientWriter::close_client($client);

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

Removes enqueued frames in client's write buffer and then enqueues WebSocket close message. Should be used if client initiates closing handshake.

=item C<send_handshake_response_to_client>

Inserts a WebSocket handshake response into client's write buffer.

=back
