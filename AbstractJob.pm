package AbstractJob;

use threads;
use threads::shared;
use Thread::Queue;

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

# should be shareable
sub data {
    my ($self) = @_;
    return $self->{data};
}

sub DoJob {

    #die "This method must be overridden by a subclass of __PACKAGE__";
}

1;
