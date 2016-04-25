package ThreadWorkers;

use strict;
use warnings;

use threads;
use threads::shared;
use UNIVERSAL::can;
use Thread::Queue;

my $jobQueue : shared;
my $process_async : shared = 0;

sub init_thread_workers {
    my ($number_of_workers) = @_;

    if ( $number_of_workers > 0 ) {
        $process_async = 1;
    }

    $jobQueue = shared_clone( Thread::Queue->new() );

    for ( my $i = 0 ; $i < $number_of_workers ; $i++ ) {
        my $thr = threads->create(
            sub {
                while ( defined( my $item = $jobQueue->dequeue() ) ) {
                    $item->DoJob();
                }
            }
        );
    }
}

sub enqueue_job {
    my ($job) = @_;

    if ( UNIVERSAL::can( $job, 'can' ) && $job->can('DoJob') ) {

        if ($process_async) {
            $jobQueue->enqueue($job);
        }
        else {
            $job->DoJob();
        }
    }
}

1;
__END__

=head1 NAME

ThreadWorkers - Threads that can run jobs asynchronously

=head1 SYNOPSIS
	
	my $job : shared; #Object that derives from AbstractJob
	ThreadWorkers::init_thread_workers ($number_of_running_threads);
	ThreadWorkers::enqueue_job ($job);

=head1 DESCRIPTION

Static class which initializes number of running threads and ThreadQueue used for storing job instances.
  
=head2 Methods

=over 12

=item C<init_thread_workers>

Starts number of threads, supplied as parameter.

=item C<enqueue_job>

Enqueues instance of a job that will be run asynchronously.
If given object does not implement DoJob method, exception is thrown.

=back

