package ReadJob;

use strict;
use warnings;

use lib '..';

use parent 'AbstractJob';

use threads;
use threads::shared;
use WebSocketClientWriter;

sub new {
    my $class = shift;

    return $class->SUPER::new(@_);
}

sub DoJob {
    my ($self) = @_;
    my $writer = WebSocketClientWriter->new( clients => $self->{clients} );
    $writer->write_to_all_clients( $self->{data} );
}

1;
