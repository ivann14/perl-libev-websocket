package WriteToAllClientsJob;

use strict;
use warnings;

use lib '../../lib';

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

sub DoJob {
    my ($self) = @_;
      WebSocketClientWriter::send_text_to_clients( $self->{data},
         $self->{clients} );
}

1;
