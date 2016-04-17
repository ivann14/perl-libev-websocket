package ThreadSafeHash;

use Data::Dumper;
use strict;
use warnings;

our $VERSION = '3.07';
$VERSION = eval $VERSION;

use threads::shared 1.21;

# Carp errors from threads::shared calls should complain about caller
our @CARP_NOT = ("threads::shared");

sub new {
    my $class = shift;
    my %hash;
    my $thread_lock : shared = shared_clone( {} );
    my %self = (
        'hash' => \%hash,
        'lock' => $thread_lock
    );
    return bless( \%self, $class );
}

sub thread_lock {
    my ($self) = @_;
    return $self->{'lock'};
}

sub Add {
    my ( $self, $key, $value ) = @_;
    my $lock = $self->thread_lock;
    lock($lock);
    my $hash = $self->Hash();
    $hash->{$key} = $value;
}

sub Contains {
    my ( $self, $key ) = @_;

    my $lock = $self->thread_lock;
    lock($lock);
    my $hash = $self->Hash();
    if ( exists $hash->{$key} ) {
        return 1;
    }

    return 0;
}

sub Remove {
    my ( $self, $key ) = @_;

    my $lock = $self->thread_lock;
    lock($lock);
    my $hash = $self->Hash();
    delete $hash->{$key};
}

sub GetValue {
    my ( $self, $key ) = @_;
    my $lock = $self->thread_lock;
    lock($lock);
    return $self->Hash()->{$key};
}

sub MapAction {
    my ( $self, $action ) = @_;
    my $lock = $self->thread_lock;
    lock($lock);
    my $hash = $self->Hash();
    keys %{ $hash
    };   # reset the internal iterator so a prior each() doesn't affect the loop

    while ( my ( $k, $v ) = each %{$hash} ) {
        $action->( $k, $v );
    }
}

sub Hash {
    my ($self) = @_;
    return $self->{'hash'};
}
