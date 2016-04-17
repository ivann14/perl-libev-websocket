package ThreadWorkers;

use 5.018;
use threads;
use threads::shared;
use Thread::Queue;
use ReadJob;

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
    if ($process_async) {
        $jobQueue->enqueue($job);
    }
    else {
        $job->DoJob();
    }
}

1;
