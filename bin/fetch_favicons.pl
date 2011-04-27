#!/usr/bin/env perl
use strict;
use warnings;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
use Getopt::Long;
use MyFavRobot::Cmd;
use MyFavRobot::Utils;

my %opt;
GetOptions( \%opt, 
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
exit;

$cmd->run(
    uris     => \@uris,
    parallel => 2,
);
exit;
=pod
=cut

sub print_help {
    print <<"END_HELP";
Usage: 
  fetch_favicons.pl --store-dir=<store-original-images-dir>  --out-dir=<result-dir>
                    --url-source=<file-with-grabed-domain-uris> 

END_HELP
}

