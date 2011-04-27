package MyFavRobot::HTML::ParseHead;
use strict;
use warnings;
use HTML::Parser;
use base qw(HTML::Parser);

use vars qw($VERSION $DEBUG);
#$DEBUG = 1;
$VERSION = "0.1";
use MIME::Types;
use List::MoreUtils qw(any all none notall);

my $mimetypes = MIME::Types->new;
sub new
{
    my $class = shift;
    my %opts  = @_;
    # $opts{ robot_meta_names => ['yandex', 'robots']

    my $self = $class->SUPER::new(api_version => 3,
        start_h => ["start", "self,tagname,attr"],
        end_h   => ["end",   "self,tagname"],
        #text_h  => ["text",  "self,text"],
        ignore_elements => [qw(script style)],
    );
    $self->{favicon} = {};
    $self;
}


sub start {
    my($self, $tag, $attr) = @_;  # $attr is reference to a HASH
    my $favicon = $self->{favicon};
    print "START[$tag]\n" if $DEBUG;
    if ($tag eq 'meta') {
        # TODO: may be process noindex tags? like this:
        #   <meta name="robots" content="noindex" />
        return;
    } 
    elsif ($tag eq 'link') {
        return if notall { exists $attr->{$_} } qw(rel href type);

        my $rel_name = lc $attr->{rel};
        return if none { $rel_name eq $_ } ('icon', 'shortcut icon');

        my $type = $attr->{type} ? $attr->{type} : '';
        my $mime_type = $mimetypes->type($type);
        my $media     = $mime_type->mediaType;
        #warn "found mtype: $media";
        return if (!$media or ($media ne 'image'));

        # image/x-icon
        my $sub_type = $mime_type->subType;
        # for image/vnd.microsoft.icon no subtype, force to set it
        unless ($sub_type) {
            if (any {'ico' eq $_} ($mime_type->extensions) ) {
                $sub_type = 'icon'
            }
        }
        return unless $sub_type;
        #warn "found sub_type: $sub_type";
        
        my $href = $attr->{href};
        # check domain if full url

        $favicon->{$sub_type} = [] unless $favicon->{$sub_type};
        push @{ $favicon->{$sub_type} }, $href;
    } 
}

sub get_favicons {
    return $_[0]->{favicon};
}

sub end {
    my($self, $tag) = @_;
    print "END[$tag]\n" if $DEBUG;
    $self->eof if $tag eq 'head'; # stop parsing
}

1;
