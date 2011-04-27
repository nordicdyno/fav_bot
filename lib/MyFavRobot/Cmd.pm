package MyFavRobot::Cmd;
use strict;
use warnings;
use Parallel::ForkManager;
use Carp;

use MyFavRobot;
use MyFavRobot::Utils;
use base qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( qw( 
    img_origin_store_dir 
    img_result_store_dir 
    allow_schemes 
) );

my $DEFAULT_PARALLEL = 1;

sub run {
    my $self = shift;
    my %opt = @_;
    # opts checks
    my $uri = $opt{uris};
    if (!$uri && (ref $uri ne 'ARRAY')) {
        die "nothing to fetch";
    }
    my @uris = @{ $uri };

    my $max_parallel = $DEFAULT_PARALLEL;
    if (defined $opt{parallel} && $opt{parallel} =~ /^\d+$/) {
        $max_parallel = $opt{parallel};
    }

    my $fm = new Parallel::ForkManager($max_parallel);
    # parallel processing
    for my $uri (@uris) {
    # process_uri
        my $pid = $fm->start and next;
        my $worker = MyFavRobot->new( 
            base_uri      => $uri->clone,
            allow_schemes => $self->get_allow_schemes,
            img_origin_store_dir   => $self->get_img_origin_store_dir,
            img_result_store_dir   => $self->get_img_result_store_dir,
        );
        $worker->process_uri();
        $fm->finish;
    
    }
    $fm->wait_all_children;
}

1;
