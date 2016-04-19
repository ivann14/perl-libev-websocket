package PingReceivedJob;

use strict;
use warnings;

use parent 'AbstractJob';

use WebSocketClientWriter;

sub new {
    my $class = shift;
    my %args  = @_;

    my %self : shared;

    $self{client}  = $args{client};
    $self{data}    = $args{data};

    bless( \%self, $class );

    return ( \%self );
}

sub DoJob {
    my ($self) = @_;
    WebSocketClientWriter->new->write_to_client( $self->{client}->id,
        $self->{data} );
}

1;
