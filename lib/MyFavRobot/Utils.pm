package MyFavRobot::Utils;

use strict;
use warnings;
use LWP::UserAgent;
use URI;
use URI::file;
use List::MoreUtils qw(any all none notall);

our $VERSION = '0.01';

# TODO: raname method?
sub found_base_uri {
    my ($uri, $url) = @_;
    my $base_uri = $uri->clone;

    #print "params: @_\n";
    my $uri_url = URI->new( $url );
    if ($uri_url->scheme) {
        return $uri_url; 
    }
    
    my @base_segments = $base_uri->path_segments;
    #print Dumper( \@url_segments );
    if (@base_segments && $base_segments[-1] eq '') {
        pop @base_segments;
    }
    
    my @path_segments = (@base_segments, $uri_url->path_segments);
    $base_uri->path_segments( @path_segments );
    return $base_uri->canonical;
}

sub parse_base_uri {
    my $data = shift;

    open my $fh, '<', \$data or die "Can't open scalar: $!";
    return parse_base_urls_fh($fh);
}

sub parse_base_urls_fh {
    my $fh = shift;

    my @base_urls;
    while( <$fh>) {
        chomp;
        s/^\s*//g; s/\s*$//g;
        s/#.*//;
        next unless length($_);

        my $url = $_;
        #print "url -> $url\n";
        my $u = URI->new( $url );
        unless ($u->scheme) {
            $u->scheme('http');
            $u->host($url);
            $u->path('');
        }
        if ($u->scheme eq 'file') {
            # correct uri for relative files
            if ($url =~ m{^\w+://(\.\S+)} ) {
                $u = URI::file->new( $1 )->abs( URI::file->cwd );
            }
        }
        push @base_urls, $u;
    }
    return @base_urls;
}

1; # End of MyFavRobot
