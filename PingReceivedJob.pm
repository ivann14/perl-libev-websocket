package PingReceivedJob;

use strict;
use warnings;

use AbstractJob;
use parent 'AbstractJob';
use threads;
use threads::shared;
use WebSocketClientWriter;

sub new {
    my $class = shift;
    my $args  = @_;

    my $self = $class->SUPER::new($args);
    $self->{client} = $args->{client};
    return $self;
}

sub DoJob {
    my ($self) = @_;
    WebSocketClientWriter->new->write_to_client( $self->{client}->id,
        $self->{data} );
}

1;
