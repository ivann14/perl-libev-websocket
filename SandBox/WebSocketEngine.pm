package WebSocketEngine;

use strict;
use warnings;

use lib '..';

use parent 'AbstractWebSocketEngine';
use ReadJob;

sub new {
    my $class = shift;

    return $class->SUPER::new(@_);
}

sub process_text_data {
    my ( $self, $text, $client ) = @_;
    my $job = ReadJob->new( data => $text, clients => $self->clients );
    return $job;
}

1;
