package WebSocketAuthorizationHelper;

use Data::GUID;
use Protocol::WebSocket;

use WebSocketClientMetadata;
use WebSocketClientWriter;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
        engine            => $args{engine},
        clients           => $args{client}            || $args{engine}->clients,
        clients_metadatas => $args{clients_metadatas} || $args{engine}->clients_metadatas
    }, $class;

    return $self;
}

sub engine {
    my ($self) = @_;
    return $self->{engine};
}

sub clients {
    my ($self) = @_;
    return $self->{clients};
}

sub clients_metadatas {
    my ($self) = @_;
    return $self->{clients_metadatas};
}

sub authorize_client {
    my ( $self, $client, $buffer ) = @_;

    my $handshake = $self->clients_metadatas->{ $client->id }->handshake;
    if ( !$handshake->is_done ) {
        $handshake->parse($buffer);

        if ( $handshake->error ) {
            WebSocketClientWriter->new->close_client( $client, 1002 );
        }
        if ( $handshake->is_done ) {
            $client->set_resource_name( $handshake->req->{'resource_name'} );

            if (
                $self->engine->authenticate_client (
                    $client, $handshake->req
                )
              )
            {

                WebSocketClientWriter->new( clients => $self->clients )
                  ->write_to_client( $client->id, $handshake->to_string );
                $self->clients_metadatas->{ $client->id }->write_watcher->start;
            }
            else {
                WebSocketClientWriter->new( clients => $self->clients )
                  ->close_client( $client->id, 1008 );
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

    $self->clients->Add( $accepted_client->id, $accepted_client );
    $self->clients_metadatas->{ $accepted_client->id } =
      $accepted_client_metadata;

    $w_io_read->start;
}

sub is_handshake_finished {
    my ( $self, $client ) = @_;

    my $metadata = $self->clients_metadatas->{ $client->id };

    if ( $metadata && $metadata->handshake->is_done ) {
        return 1;
    }

    return 0;
}

1;
