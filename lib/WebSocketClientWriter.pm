package WebSocketClientWriter;

use strict;
use warnings;

use WebSocketMessage;

sub send_text_to_client {
    my ( $text, $client, $is_final_part ) = @_;

    my $message = WebSocketMessage->new( buffer => $text, type => 'text', is_final_part => $is_final_part );
    enqueue_message_for_client( $client, $message );
}

sub send_text_to_clients {
    my ( $text, $clients, $is_final_part ) = @_;

    unless ( defined $clients ) {
        die "ThreadSafeHash with WebSocketClients was not supplied.";
    }

    my $message = WebSocketMessage->new( buffer => $text, type => 'text', is_final_part => $is_final_part );

    $clients->map_action(
       sub {
             my ( $id, $client ) = @_;
             enqueue_message_for_client($client, $message);
       });
}

sub send_binary_to_client {
    my ( $data, $client, $is_final_part ) = @_;

    my $message = WebSocketMessage->new( buffer => $data, type => 'binary', is_final_part => $is_final_part );
    enqueue_message_for_client( $client, $message );

}

sub send_binary_to_clients {
    my ( $data, $clients, $is_final_part ) = @_;

    unless ( defined $clients ) {
        die "ThreadSafeHash with WebSocketClients was not supplied.";
    }

    my $message = WebSocketMessage->new( buffer => $data, type => 'binary', is_final_part => $is_final_part );

    $clients->map_action(
       sub {
             my ( $id, $client ) = @_;
             enqueue_message_for_client($client, $message);
       });
}

sub send_continuation_to_client {
    my ( $data, $client, $is_final_part ) = @_;

    my $message = WebSocketMessage->new( buffer => $data, type => 'continuation', is_final_part => $is_final_part );
    enqueue_message_for_client( $client, $message );

}

sub send_continuation_to_clients {
    my ( $data, $clients, $is_final_part ) = @_;

    unless ( defined $clients ) {
        die "ThreadSafeHash with WebSocketClients was not supplied.";
    }

    my $message = WebSocketMessage->new( buffer => $data, type => 'continuation', is_final_part => $is_final_part );

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
    my ( $client, $message, $immediately ) = @_;

    unless ( defined $client ) {
        die "WebSocketClient was not supplied.\n";
    }

    unless ( defined $message ) {
        die "WebSocket frame was not supplied.\n";
    }

    if ($immediately) {
	$client->write_buffer->insert( 0, $message ) ;
    }else{
        $client->write_buffer->enqueue($message);
    }
}

sub ping_client {
    my ( $client, $data ) = @_;

    unless ( defined $client ) {
        die "WebSocketClient was not supplied.";
    }
	
    my $text = $data || 'ping';
    my $message = WebSocketMessage->new( buffer => $text, type => 'ping' );
    
    enqueue_message_for_client( $client, $message, 1);
}


sub send_pong_to_client {
    my ( $client, $text ) = @_;

    my $message = WebSocketMessage->new( buffer => $text, type => 'pong' );
    enqueue_message_for_client( $client, $message, 1);
}

sub close_client_immediately {
    my ( $client, $code, $reason ) = @_;

    close_client( $client, $code, $reason, 1);
}

sub close_client {
    my ( $client, $code, $reason, $immediately ) = @_;

    $client->set_closing(1);

    $code   = $code   || 1000;
    $reason = $reason || '';

    my $data = pack( "na*", $code, $reason );
    my $type = { close => $data };
    my $message = WebSocketMessage->new( buffer => $data, type => 'close' );

    enqueue_message_for_client( $client, $message, $immediately );
}

1;
__END__

=head1 NAME

WebSocketClientWriter - Enqueues WebSocket messages into client's write buffer. If needed you can send fragments by setting the last argument of the subroutine to 1.

=head1 SYNOPSIS
	WebSocketClientWriter::send_text_to_client("Hello is going to be", $client, 0);
	WebSocketClientWriter::send_text_to_client("continued with World", $client, 1);
	WebSocketClientWriter::send_binary_to_client($data, $client);
	WebSocketClientWriter::send_text_to_clients("Message for all", $clients);
	WebSocketClientWriter::ping_client($client);
	WebSocketClientWriter::ping_client($text, $client);
	WebSocketClientWriter::close_client($client);

=head1 DESCRIPTION

This class enqueues WebSocket messages into client's write buffer.
  
=head2 Methods

=over 12

=item C<send_text_to_client>

Enqueues WebSocket text message with given text into client's write buffer.

=item C<send_text_to_clients>

Enqueues WebSocket text message with given text into all clients write buffer.

=item C<send_binary_to_client>

Enqueues WebSocket binary message with given binary data into client's write buffer.

=item C<send_binary_to_clients>

Enqueues WebSocket binary message with given binary data into all clients write buffer.

=item C<send_continuation_to_client>

Enqueues a continuation message with given data into client's write buffer.

=item C<send_continuation_to_clients>

Enqueues WebSocket continuation message with given data into all clients write buffer.

=item C<ping_client>

Inserts WebSocket ping message into client's write buffer.

=item C<send_pong_to_client>

Inserts WebSocket pong message into client's write buffer.

=item C<close_client>

Enqueues WebSocket close message with client's write buffer.

=item C<close_client_immediately>

Removes enqueued frames in client's write buffer and then enqueues WebSocket close message. Should be used if client initiates closing handshake.

=item C<send_handshake_response_to_client>

Inserts a WebSocket handshake response into client's write buffer.

=back
