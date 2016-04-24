package WebSocketIOManager;

use strict;
use warnings;
use threads;
use threads::shared;
use AbstractWebSocketEngine;
use Protocol::WebSocket;

sub new {
    my ( $class, %args ) = @_;

    return bless {}, $class;
}

sub read_from_socket {
    my ( $self, $file_handle, $size ) = @_;
	
	$size = $size || 1024;
    my $buffer;
    sysread( $file_handle, $buffer, $size );

    return $buffer;
}

sub process_websocket_data {
    my ( $self, $engine, $data, $client ) = @_;

    if ( $client->closing ) {
        return;
    }

    my $frame = Protocol::WebSocket::Frame->new();
    $frame->append($data);
    my $bytes;
    while ( defined( $bytes = eval { $frame->next_bytes } ) ) {
        my $job : shared = shared_clone( {} );
        if ( $frame->is_binary ) {
            $engine->process_binary_data->( $self, $bytes, $client );
        }
        elsif ( $frame->is_text ) {
            $job =
              $engine->process_text_data( Encode::decode( 'UTF-8', $bytes ),
                $client );
        }
        elsif ( $frame->is_pong ) {
            $job = $engine->process_pong_data( $bytes, $client );
        }
        elsif ( $frame->is_ping ) {
            $job = $engine->process_ping_data->( $self, $bytes, $client );
        }
        elsif ( $frame->is_close ) {
            $job = $engine->process_client_disconnecting($client);
        }
            ThreadWorkers::enqueue_job($job);
    }
}

sub send_buffered_data_to_socket {
    my ( $self, $client, $fh, $engine ) = @_;
    my $buf         = $client->write_buffer;
    my $msg_to_send = $buf->dequeue_nb();

    if ($msg_to_send) {
        print $fh $msg_to_send->to_bytes;

        if ( $msg_to_send->is_close ) {
            $fh->close();
		my $job : shared = shared_clone ({ }); 
            $job = $engine->process_client_connection_is_closed ($client);
		ThreadWorkers::enqueue_job ($job);
        }

        if ( $msg_to_send->is_ping ) {
            $client->set_pinged( time() );
        }
    }
    else {
        $engine->close_client_or_keep_alive($client);
    }
}

1;
__END__

=head1 NAME

WebSocketIOManager - Manages work with the socket

=head1 SYNOPSIS
	
	my $io_manager = WebSocketIOManager->new;
	my $data = $io_manager->read_from_socket ( $socket, $size_to_read );
	$io_manager->process_websocket_data( $engine, $data, $client );	
	$io_manager-> send_buffered_data_to_socket( $weboscket_client, $socket, $abstract_websocket_engine );

=head1 DESCRIPTION

This class is used for managing (reading/writing) the client's socket.
  
=head2 Methods

=over 12

=item C<read_from_socket>

Returns data read from supplied socket.

=item C<process_websocket_data>

Takes 3 parameters. Instance that derives from AbstractWebSocketEngine, websocket client and read data from the socket. Then recognizes sent data and calls AbstractWebSocketEngine's appropriate method.

=item C<send_buffered_data_to_connection>

Takes 3 parameters. Instance that derives from AbstractWebSocketEngine, client to whom data from his buffer will be sent and client's socket. 

=back