package PongJob;

use strict;
use warnings;

use lib '../lib';

use parent 'AbstractJob';

use WebSocketClientWriter;

sub new {
    my ( $class, %args ) = @_;
    my %self : shared;
    $self{client} = $args{client};
    $self{data}   = $args{data};

    bless( \%self, $class );

    return ( \%self );
}

sub DoJob {
    my ($self) = @_;
    print "Pong received from client with id " . $self->{client}->id . "and data " . $self->{data} . "\n"; 
}

1;
