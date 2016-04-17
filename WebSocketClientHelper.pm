package WebSocketClientHelper;

use strict;
use warnings;

sub completely_remove_client {
    my ( $clients, $clients_metadatas, $client ) = @_;

    delete $clients_metadatas->{ $client->id };

    $clients->Remove( $client->id );

}

1;
