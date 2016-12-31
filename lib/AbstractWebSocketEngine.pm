package AbstractWebSocketEngine;

use strict;
use warnings;

use PingReceivedJob;
use WebSocketClient;
use WebSocketClientMetadata;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
        ping_after_seconds_of_inactivity =>
          $args{ping_after_seconds_of_inactivity} || 150,
        close_after_no_pong => $args{close_after_no_pong} || 150
    }, $class;

    return $self;
}

sub set_loop {
    my ( $self, $loop ) = @_;
    $self->{loop} = $loop;
}

sub loop {
    my ($self) = @_;
    return $self->{loop};
}

sub clients {
    my ($self) = @_;
    return $self->{clients};
}

sub clients_metadatas {
    my ($self) = @_;
    return $self->{clients_metadatas};
}

sub set_clients {
    my ( $self, $clients ) = @_;
    $self->{clients} = $clients;
}

sub set_clients_metadatas {
    my ( $self, $metadatas ) = @_;
    $self->{clients_metadatas} = $metadatas;
}

sub ping_after_seconds_of_inactivity {
    my ($self) = @_;
    return $self->{ping_after_seconds_of_inactivity};
}

sub close_after_no_pong {
    my ($self) = @_;
    return $self->{close_after_no_pong};
}

sub process_text_data {
    my ( $self, $text, $client ) = @_;
}

sub process_binary_data {
    my ( $self, $data, $client ) = @_;
}

sub on_after_read {
    my ( $self, $client ) = @_;
}

sub on_after_write {
    my ( $self, $client ) = @_;
}

sub process_pong_data {
    my ( $self, $data, $client ) = @_;

    if ( $data eq "ping" ) {

        # Reset pinged time, after pong is received
        $client->set_pinged(undef);
    }
}

sub process_ping_data {
    my ( $self, $data, $client ) = @_;

    my $job = PingReceivedJob->new( data => $data, client->$client );
    return $job;
}

sub process_client_disconnecting {
    my ( $self, $client ) = @_;

    WebSocketClientWriter::close_client($client);
}

sub process_client_connection_is_closed {
    my ( $self, $client, $fh) = @_;
    
    $fh->close;

    # Stop watchers, so the pending events are destroyed
    $self->clients_metadatas->{ $client->id }->write_watcher->stop;
    $self->clients_metadatas->{ $client->id }->read_watcher->stop;
    $self->clients_metadatas->{ $client->id }->prepare_write_watcher->stop;

    delete $self->clients_metadatas->{ $client->id };
    $self->clients->remove( $client->id );
}

sub close_client_or_keep_alive {
    my ( $self, $currentClient ) = @_;
    if ( defined $currentClient->pinged
        && ( $currentClient->pinged + $self->close_after_no_pong ) < time() )
    {
        WebSocketClientWriter::->close_client($currentClient);
    }

    if (
        !$currentClient->pinged
        && ( $currentClient->last_active +
            $self->ping_after_seconds_of_inactivity ) < time()
      )
    {
        WebSocketClientWriter::->ping_client($currentClient);
    }
}

sub authenticate_client {
    my ( $self, $client, $request ) = @_;

    return 1;
}

1;
__END__

=head1 NAME

AbstractWebSocketEngine - Implementation of cruacial methods for running WebSocketServer

=head1 SYNOPSIS

	use parent 'AbstractWebSocketEngine';

	sub new {
		my $class = shift;
		return $class->SUPER::new(@_);
	}

	sub process_text_data {
		#Custom code for handling text data from client
	}

	sub authenticate_client {
		#Custom code for handling client authentication
	}



=head1 DESCRIPTION

This class serves as an abstraction for creating custom WebSocketServer implementation. All methods that start with the name process, can return instances of classes that derive from AbstractJob class and can run asynchronously.
  
=head2 Methods

=over 12

=item C<new>

Constructor. You can 

=item C<loop>

Contains instance of currently running LibEV loop.

=item C<client>

Contains instance of ThreadSafeHash with current clients.

=item C<clients_metadatas>

Contains hash with clients metadatas.

=item C<ping_after_seconds_of_inactivity>

Number of seconds after which inactive client will be pinged from serve.

=item C<close_after_no_pong>

Number of seconds after which client will be disconnected from server after not receiving a pong frame from the client.

=item C<process_text_data>

Method for customization, that will be raised after receiving text frame from the client. UTF-8 encoded text and WebSocketClient instance are supplied as parameters.
Can return instance of class derived from AbstractJob.
 
=item C<process_binary_data>

Method for customization, that will be raised after receiving binary frame from the client. Binary data and WebSocketClient instance are supplied as parameters.
Can return instance of class derived from AbstractJob.


=item C<process_pong_data>

Method for customization, that will be raised after receiving pong frame from the client. Data from pong frame and WebSocketClient instance are supplied as parameters.
Can return instance of class derived from AbstractJob.
Contains default implementation.

=item C<process_ping_data>

Method for customization, that will be raised after receiving ping frame from the client. Data from ping frame and WebSocketClient instance are supplied as parameters.
Can return instance of class derived from AbstractJob.
Contains default implementation.

=item C<process_client_disconnecting>

Method for customization, that will be raised after receiving close frame from the client. WebSocketClient instance is supplied as parameter.
Can return instance of class derived from AbstractJob, which DoJob method will be run asynchronously.
Contains default implementation.

=item C<close_client_or_keep_alive>

Method for customization, that will be raised every time the file handle for client is available for writing and there is nothing to write. Can be used for pinging or closing client.
contains default implementation.

=item C<authenticate_client>

Method for customization, that will be raised every time the client is accepted and whole handshake request is read. 
Return true, if the client is authenticated and we can start receiving messages from the client.
Return false, if the client is authenticated. Client will be disconnected from the server.
Takes 2 parameters. Handshake request and websocket client. 

=item C<process_client_connection_is_closed>

Method for customization, that will be raised everytime the client is disconnected from the server. 
Can return instance of class derived from AbstractJob.
Contains default implementation.


=back


