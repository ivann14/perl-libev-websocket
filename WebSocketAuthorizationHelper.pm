package WebSocketAuthorizationHelper;

use Data::GUID;
use Protocol::WebSocket;

use WebSocketClientMetadata;
use WebSocketClientWriter;
use WebSocketRequest;


sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
        engine            => $args{engine} || die "Supply instance of class that derives from AbstractWebSocketEngine.",
    }, $class;

    return $self;
}

sub engine {
    my ($self) = @_;
    return $self->{engine};
}

sub authorize_client {
    my ( $self, $client, $buffer ) = @_;

    my $handshake = $self->engine->clients_metadatas->{ $client->id }->handshake;
    if ( !$handshake->is_done ) {
        $handshake->parse($buffer);

        if ( $handshake->error ) {
		#Handshake is corrupted fail the connection immediately
            $self->engine->process_client_connection_is_closed ($client);
        }
        if ( $handshake->is_done ) {
		my $request = WebSocketRequest->new ($handshake->req);
            $client->set_resource_name( $request->resource_name );
		my $authenticated = $self->engine->authenticate_client ( $client, $request );
            
 		#If not authenticated set response status to 401, client will fail connection because status was not 101
		if (!$authenticated) {
			$handshake->res->{'status'} = "401";
		}
	    my $writer = WebSocketClientWriter->new;
	    $writer->send_text_to_client( $client, $handshake->to_string );
	    $self->engine->clients_metadatas->{ $client->id }->write_watcher->start;

		#Close connection if not authenticated, because client will fail the connection because of 401 status code
	    if (!$authenticated) {
		$self->engine->process_client_connection_is_closed ($client);
	    }
        }
    }
}

sub remember_client {
    my ( $self, $w_io_read, $w_io_write ) = @_;

    my $client_id = Data::GUID->new->as_string;
    $w_io_read->data($client_id);
    $w_io_write->data($client_id);

    my $accepted_client = WebSocketClient->new( id => $client_id );
    my $accepted_client_metadata = WebSocketClientMetadata->new(
        id            => $client_id,
        read_watcher  => $w_io_read,
        write_watcher => $w_io_write
    );

    $self->engine->clients->add( $accepted_client->id, $accepted_client );
    $self->engine->clients_metadatas->{ $accepted_client->id } =
      $accepted_client_metadata;

    $w_io_read->start;
}

sub is_handshake_finished {
    my ( $self, $client ) = @_;

    my $metadata = $self->engine->clients_metadatas->{ $client->id };

    if ( $metadata && $metadata->handshake->is_done ) {
        return 1;
    }

    return 0;
}

1;
__END__

=head1 NAME

WebSocketAuthorizationHelper - Authorization helper

=head1 SYNOPSIS
	my $helper = WebSocketAuthorizationHelper->new ($AbstractWebSocketEngine_instance);
	$helper->remember_client ($watcher_read, $watcher_write);
	$helper->is_handshake_finished ($client);
	$helper->authorize_client ($websocket_client, $data_read_from_socket);

=head1 DESCRIPTION

This class serves for authorization incoming clients and saving them in thread safe collection.
  
=head2 Methods

=over 12

=item C<new>

Constructor. Supply instance of the class that derives from AbstractWebSocketEngine, so the incoming clients can be safed in thread safe collection and customization of authentication process via supplied instance.

=item C<remember_client>

Takes read and write watcher of accepted client's filehandle.
Creates from them instance of WebSocketClientMetadata and WebSocketClient saves them inside supplied AbstractWebSocketEngine instance. So the event loop can listen for the incoming handshake. 

=item C<is_handshake_finished>

Returns true, if the handshake is finnished (the whole WebSocket request arrived) for given client.

=item C<authorize_client>

For given client and data from file handle, tries to create the whole websocket request and if it is ok response is send. The whole request may not be read if the tcp socket is non blocking. Thats why read parts are saved until the whole request is constructed. After the whole request is read, then customized authentication method from AbstractWebSocket instance is called.


=back


