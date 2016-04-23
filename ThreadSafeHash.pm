package ThreadSafeHash;

use strict;
use warnings;

use threads;
use threads::shared;

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

sub add {
    my ( $self, $key, $value ) = @_;
    my $lock = $self->{'lock'};
    lock($lock);
    my $hash = $self->internal_hash();
    $hash->{$key} = $value;
}

sub contains {
    my ( $self, $key ) = @_;

    my $lock = $self->{'lock'};
    lock($lock);
    my $hash = $self->internal_hash();
    if ( exists $hash->{$key} ) {
        return 1;
    }

    return 0;
}

sub remove {
    my ( $self, $key ) = @_;

    my $lock = $self->{'lock'};
    lock($lock);
    my $hash = $self->internal_hash();
    delete $hash->{$key};
}

sub get_value {
    my ( $self, $key ) = @_;
    my $lock = $self->{'lock'};
    lock($lock);
    return $self->internal_hash()->{$key};
}

sub map_action {
    my ( $self, $action ) = @_;
    my $lock = $self->{'lock'};
    lock($lock);
    my $hash = $self->internal_hash();
    keys %{ $hash };   # reset the internal iterator so a prior each() doesn't affect the loop

    while ( my ( $k, $v ) = each %{$hash} ) {
        $action->( $k, $v );
    }
}

sub internal_hash {
    my ($self) = @_;
    return $self->{'hash'};
}

1;
__END__

=head1 NAME

ThreadSafeHash - Thread safe hash

=head1 SYNOPSIS
	
	my $hash : shared = shared_clone (ThreadSafeinternal_hash ->new );
	$hash -> add ("key", "some shared value");
	$hash -> contains ("key");
	my $value = $hash -> get_value("key");
	$hash -> remove ("key");
	$hash -> map_action ( sub {
		my ( $key, $value ) = @_;
		$value = "changed value";
	});

=head1 DESCRIPTION

Hash that can be safely shared between threads.
  
=head2 Methods

=over 12

=item C<new>

Constructor.

=item C<add>

Adds value with given key to hash.

=item C<remove>

Removes key value pair from the hash.

=item C<get_value>

Returns value for given key.

=item C<map_action>

Runs given subroutine with two parameters (key and value), thread safely for each key value pair in hash.

=item C<internal_hash>

Returns hash internally used by the instance of this class.

=back



