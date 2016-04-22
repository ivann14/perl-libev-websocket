package ReadJob;

use strict;
use warnings;

use lib '..';

use parent 'AbstractJob';

use WebSocketClientWriter;

sub new {
    my ( $class, %args ) = @_;
    my %self : shared;
    $self{clients} = $args{clients};
    $self{data}    = $args{data};

    bless( \%self, $class );

    return ( \%self );
}


sub clients {
    my ($self) = @_;
    return $self->{clients};
}


sub data {
    my ($self) = @_;
    return $self->{clients};
}



sub DoJob {
    my ($self) = @_;
    my $writer = WebSocketClientWriter->new->send_text_to_clients( $self->{data}, $self->{clients} );
}

1;
