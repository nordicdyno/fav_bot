#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use MyFavRobot;
use MyFavRobot::Utils;

my $cmd = MyFavRobot::Cmd->new(
        allow_schemes          => [qw(http https)], 
        img_origin_store_dir   => $img_origin_store_dir,
        img_result_store_dir   => $img_result_store_dir,
);

$cmd->run(
    uris     => \@uris,
    parallel => 2,
);

