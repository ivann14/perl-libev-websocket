package ChatEngine;

use strict;
use warnings;

use lib '../../lib';

use parent 'AbstractWebSocketEngine';
use WriteToAllClientsJob;

sub process_text_data {
    my ( $self, $text, $client ) = @_;
    return WriteToAllClientsJob->new( data => $text, clients => $self->clients );
}

1;