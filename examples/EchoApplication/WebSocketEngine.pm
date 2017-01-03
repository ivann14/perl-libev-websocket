package WebSocketEngine;

use strict;
use warnings;

use lib '../../lib';

use parent 'AbstractWebSocketEngine';


sub process_text_data {
    my ( $self, $text, $client ) = @_;

    WebSocketClientWriter::send_text_to_client( $text, $client );

    # Fragmentation example
    #WebSocketClientWriter::send_text_to_client( $text, $client, 0 );
    #WebSocketClientWriter::send_continuation_to_client( " echoed", $client, 1 );
}

sub on_after_write {
    my ( $self, $client ) = @_;
	if ( not defined $client->write_buffer->peek ) {
	     $self->clients_metadatas->{ $client->id }->write_watcher->stop;
	}
}

sub on_after_read {
    my ( $self, $client ) = @_;
	if ( defined $client->write_buffer->peek ) {
		$self->clients_metadatas->{ $client->id }->write_watcher->start;
	}
}

1;