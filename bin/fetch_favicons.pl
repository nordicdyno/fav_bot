#!/usr/bin/env perl
use strict;
use warnings;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
use Getopt::Long;
use MyFavRobot::Cmd;
use MyFavRobot::Utils;

my $n_parallel = 4;
my %opt;
GetOptions( \%opt, 
    "n-parallel|n=s",
    "store-dir=s", "out-dir=s", "--url-source=s", "help",
    ) or (print_help() && die "Get options error");

if ($opt{help}) { 
    print_help(); exit;
}

my @required_params = ('store-dir', 'out-dir', 'url-source');
my @not_found_params = grep { not exists $opt{$_} } @required_params; 
if (@not_found_params) {
    print "params must be specified on command line: ", 
        join(', ', @not_found_params), "\n";
    print_help();
    exit 1;
}

if( exists $opt{'n-parallel'} && ($opt{'n-parallel'} =~ m/^(\d+)$/) ) {
    $n_parallel = int($1);
}
my $url_file = $opt{'url-source'};
die "can't find urls file: $url_file" unless -f $url_file;

open( my $fh, '<', $url_file) or die "Can't read file '$url_file'. $!";
my @uris = MyFavRobot::Utils::parse_base_urls_fh( $fh );
close $fh;

my $cmd = MyFavRobot::Cmd->new({
        allow_schemes          => [qw(http https)], 
        img_origin_store_dir   => $opt{'store-dir'},
        img_result_store_dir   => $opt{'out-dir'},
    });

$cmd->run(
    uris     => \@uris,
    parallel => $n_parallel,
);
exit;
=pod
=cut

sub print_help {
    print <<"END_HELP";
Usage: 
  fetch_favicons.pl --store-dir=<store-original-images-dir>  --out-dir=<result-dir>
                    --url-source=<file-with-grabed-domain-uris> 
                    [ --n-parallel=N ]
   options:
    --store-dir     - dir where to store original favicon's images (for simple debug)
                      (TODO : use /tmp dir by default)
    --out-dir       - dir where to store result png 16x16 files

    --n-parallel     - count of forks (default=4)
END_HELP
}

