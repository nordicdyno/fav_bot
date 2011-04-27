package MyFavRobot;

use strict;
use warnings;
use LWP::UserAgent;
use File::Copy; # core
use File::Spec;
use File::Path qw(make_path remove_tree);;
use URI;
use URI::file;
use List::MoreUtils qw(any all none notall);

use MyFavRobot::Utils;
use MyFavRobot::ReadTxt;
use MyFavRobot::FindIco; # provide process function
use MyFavRobot::HTML::ParseHead;

=head1 NAME

MyFavRobot - The great new MyFavRobot!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use MyFavRobot;

    my $foo = MyFavRobot->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

=head2 new

=cut

sub new {
    my ($class) = shift;
    my %opt     = @_; # TODO:
    my $bot_name = exists $opt{bot_name} ? $opt{bot_name} : 'MyFavBot';
    my $base_uri = exists $opt{base_uri} ? $opt{base_uri} : 'http://localhost';

    #my $robo_txt_class    = 'MyFavRobot::ReadTxt';
    my $self = bless { }, $class;
    $self->{bot_name} = $bot_name;
    $self->{base_uri} = $base_uri;
    $self->{img_origin_store_dir} = $opt{img_origin_store_dir};
    $self->{img_result_store_dir} = $opt{img_result_store_dir};
    
    $self;
}

=head2 function1

=cut


=head2 function2

=cut

# bot undersand unly http, file (TODO: https)
sub check_base_uri_schema {
    my $self = shift;
    my $uri  = shift;
    return 1;
}

# Return only one favicon url
# 1-st is png, next: ico, gif, jpeg
sub found_favicon_uri {
    my $self = shift;
    my $fav_icons_hashref  = $self->get_favicons_from_index();
    my $img_uri;

    print Dumper( $fav_icons_hashref );
  IMG_TYPES_LOOP:
    for my $type ( grep { exists $fav_icons_hashref->{$_} } qw (png icon gif jpeg) )
    {
        for my $url ( @{ $fav_icons_hashref->{$type} } ) {
            $img_uri = URI->new( $url );
            #print "found: ", $ico_url, "\n";
            last IMG_TYPES_LOOP;
            #if ($robots.txt->)
        }
    }

    return $img_uri;
}

sub compute_rel_path {
    my $self = shift;
    my $uri = shift;
    my $base_uri  = $self->{base_uri};

    my $path;
    my $rel_uri;
    if ($uri->scheme eq 'file') {
        $path = $uri->rel( $base_uri );
    }
    else {
        $path = $uri->path;
    }

    return $path;
}

sub process_uri {
    my $self = shift;
    my $base_uri  = $self->{base_uri};
    # move to new ?

    # TODO : move to init
    unless ( $self->check_base_uri_schema ) {
        warn "unsupportes schema for URI: $base_uri";
        return;
    }
    #print '-' x 55, "\n";

    #print "base_uri -=> $base_uri\n";
    my $ico_url = $self->found_favicon_uri;
    print "found ico: $ico_url\n" if $ico_url;
    #return;
    if (not defined $ico_url) {
        $ico_url = '/favicon.ico';
    }

    my $ico_uri = MyFavRobot::Utils::found_base_uri($base_uri, $ico_url);

    my $robo_txt_obj = $self->get_robots_txt_obj( $ico_uri );
    if ($robo_txt_obj) {
        my $check_rel = $self->compute_rel_path( $ico_uri );
        print "check $ico_url\n";
        if ( not $robo_txt_obj->is_allow_url( $check_rel ) ) {
            warn "'$check_rel' is disabled by robots.txt. Skip.";
            return;
        }
    }

    my $orig_copy_fname = $self->store_file( $ico_uri );
    #exit;
    my $result_fname    = $self->gen_out_img_fname(); #$ico_uri );
    print "result fname: $result_fname\n";
    print qq{\$img_obj->process( $orig_copy_fname => $result_fname)}, "\n";
    #my $img_obj  = 
    MyFavRobot::FindIco::process( $orig_copy_fname => $result_fname);

}

# TODO : move to init() ?
sub _get_sub_dir_for_base_uri {
    my $self = shift;
    my $base_uri  = $self->{base_uri};
    my $sub_dir;
    if ($base_uri->scheme eq 'file') {
        #$sub_dir = join("-", ($base_uri->path_segments )); #[-1];
        $sub_dir = ($base_uri->path_segments)[-2];
    }
    else {
        $sub_dir = $base_uri->authority();
    }
    $sub_dir =~ s{/}{}g; 
    return $sub_dir;
}

sub store_file {
    my $self = shift;
    my $uri  = shift;
    my $out_path  = $self->{img_origin_store_dir};

    die "not found dir $out_path" unless -d $out_path;

    my $sub_dir = $self->_get_sub_dir_for_base_uri;
    
    my $file_name = ($uri->path_segments)[-1];
    use Data::Dumper;
    print Dumper( [$uri->path_segments] );
    die "not found file name in uri: $uri" unless $file_name;
    print "file_name => $file_name\n";
    
    my $out_path_dir = File::Spec->catfile( $out_path, $sub_dir); 
    $out_path        = File::Spec->catfile( $out_path_dir, $file_name );
    make_path( $out_path_dir );

    if ($uri->scheme eq 'file') {
        copy($uri->path, $out_path) or die "Copy failed: $!";
    }
    else {
        my $raw_src;
        # TODO: UA->mirror( $uri, $out_path)
        $self->_get_file( $uri, \$raw_src);
        
        if (defined $raw_src) {
            open( my $fh, '>', $out_path ) or die "Can't open file: $out_path. '$!'";
            binmode $fh; # на всякий случай
            print ${fh} $raw_src    
                or die "can't write to file $out_path. '$!'";
        }
    }
    return $out_path;
}

sub gen_out_img_fname {
    my $self = shift;
    my $out_path  = $self->{img_result_store_dir};
    die "not found dir $out_path" unless -d $out_path;

    my $sub_dir = $self->_get_sub_dir_for_base_uri;
    # TODO : move hardcoded name and extension to object attrs
    my $file_name = 'favicon.png';

    my $out_path_dir = File::Spec->catfile( $out_path, $sub_dir); 
    my $result_path        = File::Spec->catfile( $out_path_dir, $file_name );
    make_path( $out_path_dir );
    return $result_path;
}

# uri, body_ref
sub _get_file {
    my $self = shift;

    my $uri = shift; # base uri
    my $body_ref = shift;

    if ($uri->scheme eq 'file') {
        my $file = $uri->path;
        #print "get $index_path\n";
        eval {
            local $/ = undef;
            open (my $fh, '<', $file)
                    or die "can't open file $file: $!";
            $$body_ref = <$fh>;
        };
        if ($@) { warn $@; }
    }
    else { 
        my $ua = LWP::UserAgent->new(
            agent => $self->{bot_name} );
        $ua->timeout(3);
        my $res = $ua->get( $uri->as_string );
        if ($res->is_success) {
            $$body_ref = $res->content; 
        }
        # TODO : process wrong result (die?)
    }
}

sub get_favicons_from_index {
    my $self = shift;
    my $uri  = $self->{base_uri};

    my $index_uri = $uri->clone;
    my $index_body;
    if ($uri->scheme eq 'file') {
        $index_uri = MyFavRobot::Utils::found_base_uri($uri, 'index.html');
    }
    $self->_get_file( $index_uri, \$index_body);

    return if not defined $index_body;

    my $head_parser = MyFavRobot::HTML::ParseHead->new();
    $head_parser->parse( $index_body );

    return $head_parser->get_favicons;
}

sub get_robots_txt_obj {
    my $self      = shift;
    my $target_uri  = shift;
    my $base_uri    = $self->{base_uri};

    my $robots_uri;
    if ($target_uri->scheme eq 'file') {
        $robots_uri = MyFavRobot::Utils::found_base_uri($base_uri, 'robots.txt');
    }
    else {
        # if base domain and fetched url domain is different
        my $root_uri = $target_uri->clone;
        $root_uri->path('/');
        $robots_uri = MyFavRobot::Utils::found_base_uri($root_uri, '/robots.txt');
    }
    print "ROBOTS URI: $robots_uri\n";

    my $robots_body;
    $self->_get_file( $robots_uri, \$robots_body);
    
    return unless $robots_body;

    my $robots_txt = MyFavRobot::ReadTxt->new( bot_name => $self->{bot_name} );
    eval {
        $robots_txt->parse( $robots_body);
    };
    if ($@) {
        warn "problem with parsing robots.txt: $@";
        $robots_txt = undef;
    }
    return $robots_txt;
}


1; # End of MyFavRobot
