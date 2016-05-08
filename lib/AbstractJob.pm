package AbstractJob;

use strict;
use warnings;

use threads;
use threads::shared;

sub DoJob {
    die "This method must be overridden by a subclass of __PACKAGE__";
}

1;
__END__

=head1 NAME

AbstractJob - Asynchronous job

=head1 SYNOPSIS
	
	use parent 'AbstractJob';

	sub new {
		my $class = shift;
		my %self : shared;
		bless( \%self, $class );
		return ( \%self );
	}

	sub DoJob {
		my ($self) = @_;
		#Implement custom routine that can run asynchronously
	}

=head1 DESCRIPTION

This class serves as abstraction for creating custom jobs that can run asynchronously in another thread. These custom jobs can be used in customized class which derives from AbstractWebSocketEngine. 
  
=head2 Methods

=over 12

=item C<DoJob>

Routine that can run asynchronously, inside another thread.

=back
