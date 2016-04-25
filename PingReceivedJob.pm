package PingReceivedJob;

use strict;
use warnings;

use parent 'AbstractJob';

use WebSocketClientWriter;

sub new {
    my $class = shift;
    my %args  = @_;

    my %self : shared;

    $self{client} = $args{client} || die "Supply WebSocketClient.";
    $self{data}   = $args{data}   || die "Supply data to be sent.";

    bless( \%self, $class );

    return ( \%self );
}

sub DoJob {
    my ($self) = @_;
    WebSocketClientWriter->new->send_text_to_client( $self->{client},
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

=item C<new>

Constructor. Supply client to which pong will be sent and data that will be sent in pong frame.

=item C<DoJob>

Can asynchronously respond to client with pong frame.

=back


