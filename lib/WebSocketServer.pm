package WebSocketServer;

use strict;
use warnings;

use 5.018;
use threads;
use threads::shared;
use EV;
use Protocol::WebSocket;
use WebSocketClient;
use WebSocketClientMetadata;
use AbstractWebSocketEngine;
use WebSocketIOManager;
use WebSocketAuthorizationHelper;
use ThreadSafeHash;
use ThreadWorkers;
use WebSocketClientMetadata;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
        socket           => $args{socket},
        websocket_engine => $args{websocket_engine},
        clients => $args{clients} || shared_clone( ThreadSafeHash->new() ),
        clients_metadatas => $args{clients_metadatas} || {},
        number_of_thread_workers => $args{number_of_thread_workers} || 0,
        loop => $args{loop} || EV::default_loop,
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
    return $self->clients->get_value($client_id);
}

sub run_server {
    my ($self) = shift;

    ThreadWorkers::init_thread_workers( $self->{number_of_thread_workers} );

    my $authHelper =
      WebSocketAuthorizationHelper->new( engine => $self->websocket_engine );

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

                        if ( $client->closing ) {
                            $w_io->stop();
                            return;
                        }

                        my $io_manager = WebSocketIOManager->new();
                        my $buffer = $io_manager->read_from_socket( $w_io->fh );

                        if ($buffer) {

                            # Change the time when the client was active for the last time
                            $client->set_last_active( time() );

                            # If client has been authorize, then read data
                            if ( $authHelper->is_handshake_finished($client) ) {

				# Append data from socket to build WebSocket frame
    				my $frame = $self->clients_metadatas->{$client->id}->frame;
				$frame->append($buffer);

                                my $job = $io_manager->process_websocket_data( $self->websocket_engine, $frame, $client );
                                if ($job) {
                                    ThreadWorkers::enqueue_job($job);
                                }
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
                          ->send_buffered_data_to_socket( $client,
                            $w_io->fh, $self->websocket_engine );

			if ($self->clients_metadatas->{$client->id}) {
				$self->clients_metadatas->{$client->id}->prepare_write_watcher->start;
				$self->clients_metadatas->{$client->id}->write_watcher->stop;
			}
                    }
                );

                $authHelper->remember_client( $w_io_read, $w_io_write );
            }
        }
    );

    $self->{loop}->run;
}

1;
__END__

=head1 NAME

WebSocketServer - WebSocket server

=head1 SYNOPSIS
	my $socket = IO::Socket::INET->new(
		Proto     => "tcp",
		LocalPort => $port,
		LocalHost => $ip,
		Listen    => 5,
		Reuse     => 5,
		Type      => SOCK_STREAM,
		Blocking  => 0,
	) or die "Error creating socket $!";

	my $server = WebSocketServer->new(
    		socket                           => $socket,
    		websocket_engine                 => Abstract_WebSocketEngine_Instance->new,
    		number_of_thread_workers         => 2,
	);

$server->run_server();

=head1 DESCRIPTION

This class is websocket server. Listens and accepts clients on given custom socket. Can be customized by passing instace of the class that derives from AbstractWebSocketEngine class as parameter.
  
=head2 Methods

=over 12

=item C<new>

Constructor. Takes 2 parameters. Instace of the class that derives from AbstractWebSocketEngine and socket.

=item C<clients>

Returns ThreadSafeHash with currently connected WebSocket clients.

=item C<clients_metadatas>

Returns hash with metadatas about currently connected WebSocket clients.

=item C<get_client_by_id>

Returns WebSocketClient by given id. 

=item C<run_server>

Starts WebSocketServer. Server is now listening on given socket and accepting clients connections.

=back
