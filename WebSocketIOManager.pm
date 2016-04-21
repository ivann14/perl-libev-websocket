package WebSocketIOManager;

use strict;
use warnings;
use threads;
use threads::shared;
use UNIVERSAL::can;
use Thread::Queue;
use AbstractWebSocketEngine;

use Protocol::WebSocket;

sub new {
    my ( $class, %args ) = @_;

    return bless {}, $class;
}

sub read_from_fh {
    my ( $self, $file_handle ) = @_;

    my $buffer;
    sysread( $file_handle, $buffer, 1024 );

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
        if ( UNIVERSAL::can( $job, 'can' ) && $job->can('DoJob') ) {
            ThreadWorkers::enqueue_job($job);
        }
    }
}

sub send_buffered_data_to_connection {
    my ( $self, $client, $fh, $engine ) = @_;
    my $buf         = $client->writeBuffer;
    my $msg_to_send = $buf->dequeue_nb();

    if ($msg_to_send) {
        print $fh $msg_to_send->to_bytes;

        if ( $msg_to_send->is_close ) {
            $fh->close();
            $engine->client_connection_is_closed ($client);
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
