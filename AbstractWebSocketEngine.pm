package AbstractWebSocketEngine;

use strict;
use warnings;

use WebSocketClient;
use ReadJob;
use PingReceivedJob;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
        clients           => $args{clients},
        clients_metadatas => $args{clients_metadatas},
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

sub process_pong_data {
    my ( $self, $data, $client ) = @_;

    $client->set_pinged("");
}

sub process_ping_data {
    my ( $self, $data, $client ) = @_;

    my $job = PingReceivedJob->new( data => $data, client->$client );
}


sub process_client_disconnected {
    my ( $self, $client ) = @_;

    delete $self->clients_metadatas->{ $client->id };
    $self->clients->Remove( $client->id );
}


sub pong_received {
    my ( $self, $bytes, $client ) = @_;

    # Reset pinged time, after pong is received
    $client->set_pinged("");
}


sub close_client_or_keep_alive {
    my ( $self, $currentClient ) = @_;
    if ( $currentClient->pinged
        && ( $currentClient->pinged + $self->close_after_no_pong ) < time() )
    {
        WebSocketClientWriter->new->close_client($currentClient);
    }

    if (
        !$currentClient->pinged
        && ( $currentClient->last_active +
            $self->ping_after_seconds_of_inactivity ) < time()
      )
    {
        WebSocketClientWriter->new->ping_client($currentClient);
    }
}


sub process_client_disconnecting {
    my ( $self, $client ) = @_;

    WebSocketClientWriter->new->close_client($client);
}


sub process_client_authentication {
    my ( $self, $client, $request ) = @_;

    return 1;
}

1;
