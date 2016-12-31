package WebSocketIOManager;

use strict;
use warnings;

use Encode ();
use threads;
use threads::shared;

use AbstractWebSocketEngine;
use Protocol::WebSocket;

sub read_from_socket {
    my ( $file_handle, $size ) = @_;

    $size = $size || 1024;
    my $buffer;
    my $bytes_read = sysread( $file_handle, $buffer, $size );
	
    return $buffer, $bytes_read;
}


sub process_websocket_data {
    my ( $engine, $frame, $client ) = @_;

    if ( $client->closing ) {
        return undef;
    }

    my $bytes;

    while ( defined( $bytes = eval { $frame->next_bytes } ) ) {
        my $job : shared = shared_clone( {} );

        if ( $frame->is_binary ) {
           $job = 
		$engine->process_binary_data( $bytes, $client );
        }
        elsif ( $frame->is_text ) {
            $job =
              $engine->process_text_data( Encode::decode('UTF-8', $bytes), $client );
        }
        elsif ( $frame->is_pong ) {
            $job = $engine->process_pong_data( $bytes, $client );
        }
        elsif ( $frame->is_ping ) {
            $job = $engine->process_ping_data( $bytes, $client );
        }
        elsif ( $frame->is_close ) {
            $job = $engine->process_client_disconnecting($client);
        }
        
        if ($job) {
	    ThreadWorkers::enqueue_job($job);
	}
    }
}


sub send_buffered_data_to_socket {
    my ( $client, $fh, $engine ) = @_;

	if (defined (my $msg_to_send = $client->write_buffer->dequeue_nb() )){

		syswrite ( $fh, $msg_to_send->get_data );

		if ( $msg_to_send->is_close ) {
			$engine->process_client_connection_is_closed($client, $fh);
		}

		if ( $msg_to_send->is_ping ) {
			$client->set_pinged( time() );
		}
	} else {
		$engine->close_client_or_keep_alive($client);
	}
}

1;
__END__

=head1 NAME

WebSocketIOManager - Manages work with the socket

=head1 SYNOPSIS
	
	my ($data, $bytes_read) = WebSocketIOManager::read_from_socket ( $socket, $size_to_read );
	WebSocketIOManager::process_websocket_data( $engine, $data, $client );	
	WebSocketIOManager::send_buffered_data_to_socket( $weboscket_client, $socket, $abstract_websocket_engine );

=head1 DESCRIPTION

This class is used for managing (reading/writing) the client's socket.
  
=head2 Methods

=over 12

=item C<read_from_socket>

Returns data read from the supplied socket and number of bytes read.

=item C<process_websocket_data>

Takes 3 parameters. Instance that derives from AbstractWebSocketEngine, websocket client and webSocket frame read from the socket. Then recognizes sent data and calls AbstractWebSocketEngine's appropriate method.

=item C<send_buffered_data_to_connection>

Takes 3 parameters. Instance that derives from AbstractWebSocketEngine, client to whom data from his buffer will be sent and client's socket. 

=back
