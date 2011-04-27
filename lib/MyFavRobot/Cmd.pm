package MyFavRobot;
use strict;
use warnings;

use MyFavRobot;
#use MyFavRobot::Utils;
use Parallel::ForkManager;
my $DEFAULT_PARALLEL = 1;

sub run {
    my %opt = @_;
    # opts checks
    my $uri = $opt{uris};
    if (!$uri && (ref $uri ne 'ARRAY)) {
        die "nothing to fetch";
    }
    my $max_parallel = $DEFAULT_PARALLEL;
    if (defined $opt{parallel} && $opt_parallel =~ /^\d+$/) {
        $max_parallel = $opt{parallel};
    }

    my $fm = new Parallel::ForkManager($max_parallel);
    # parallel processing
    for my $uri (@uris) {
    # process_uri
        my $pid = $fm->start and next;
        my $worker = MyFavRobot->new( 
            base_uri      => $uri->clone,
            img_origin_store_dir   => $img_origin_store_dir,
            img_result_store_dir   => $img_result_store_dir,
        );
        $worker->process_uri();
        $fm->finish
    
    }
    $fm->wait_all_children;
}

1;
