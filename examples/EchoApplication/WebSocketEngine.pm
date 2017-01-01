package WebSocketEngine;

use strict;
use warnings;

use lib '../../lib';

use parent 'AbstractWebSocketEngine';
use ReadJob;

sub new {
    my $class = shift;

    return $class->SUPER::new(@_);
}

sub process_text_data {
    my ( $self, $text, $client ) = @_;

    return ReadJob->new( data => $text, client => $client );
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