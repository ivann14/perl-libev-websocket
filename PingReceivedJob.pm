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
__END__

=head1 NAME

PingReceivedJob - Asynchronous job that is run after receiving ping frame from the client

=head1 SYNOPSIS
	
	my $job : shared = shared_clone( PingReceivedJob->new );
	ThreadWorkers::enqueue_job($job);

=head1 DESCRIPTION

Responds client with pong frame.
  
=head2 Methods

=over 12

=item C<DoJob>

Can asynchronously respond client with pong frame.

=back


