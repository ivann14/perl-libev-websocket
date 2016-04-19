package WebSocketServer;

use strict;
use warnings;

use 5.018;
use threads;
use threads::shared;
use EV;
use Protocol::WebSocket;
use WebSocketClient;
use WebSocketEngine;
use WebSocketIOManager;
use WebSocketAuthorizationHelper;
use ThreadSafeHash;
use ThreadWorkers;

sub new {
    my ( $class, %args ) = @_;

    my %hash;
    my $self = bless {
        socket                   => $args{socket},
        websocket_engine         => $args{websocket_engine},
        clients                  => shared_clone( ThreadSafeHash->new() ),
        clients_metadatas        => {},
        number_of_thread_workers => 0,
        loop                     => $args{loop} || EV::default_loop,
    }, $class;

    $self->websocket_engine->set_loop( $self->{loop} );
    $self->websocket_engine->set_clients( $self->clients );
    $self->websocket_engine->set_clients_metadatas( $self->clients_metadatas );

    return $self;
}

sub websocket_engine {
    my ($self) = @_;
    return $self->{websocket_engine};
}

sub clients {
    my ($self) = @_;
    return $self->{clients};
}

sub clients_metadatas {
    my ($self) = @_;
    return $self->{clients_metadatas};
}

sub get_client_by_id {
    my ( $self, $client_id ) = @_;
    return $self->clients->GetValue($client_id);
}

sub run_server {
    my ($self) = shift;

    ThreadWorkers::init_thread_workers( $self->{number_of_thread_workers} );

    my $authHelper = WebSocketAuthorizationHelper->new(
    	engine => $self->websocket_engine
    );

    my $w = $self->{loop}->io(
        $self->{socket},
        EV::READ,
        sub {
            my $connection = $self->{socket}->accept();
            if ($connection) {

                # When client connects, create event that listens
                my $w_io_read = $self->{loop}->io_ns(
                    $connection,
                    EV::READ,
                    sub {
                        my ( $w_io, $revents ) = @_;
                        my $client = $self->get_client_by_id( $w_io->data );

                        my $io_manager = WebSocketIOManager->new();
                        my $buffer     = $io_manager->read_from_fh( $w_io->fh );

                        if ($buffer) {
                  # Change the time when the client was active for the last time
                            $client->set_last_active( time() );

                            # If client has been authorize, then read data
                            if ( $authHelper->is_handshake_finished($client) ) {
                                $io_manager->process_websocket_data(
                                    $self->websocket_engine, $buffer, $client );
                            }
                            else {
                                # Authorize him first
                                $authHelper->authorize_client( $client,
                                    $buffer );
                            }
                        }
                    }
                );

                # Event handler for writing into client stream
                my $w_io_write = $self->{loop}->io_ns(
                    $connection,
                    EV::WRITE,
                    sub {
                        my ( $w_io, $revents ) = @_;
                        my $client = $self->get_client_by_id( $w_io->data );

                        #Get message from client buffer and write
                        WebSocketIOManager->new()
                          ->send_buffered_data_to_connection( $client,
                            $w_io->fh, $self->websocket_engine );
                    }
                );

                $authHelper->remember_client( $w_io_read, $w_io_write );
            }
        }
    );

    $self->{loop}->run;
}

1;

