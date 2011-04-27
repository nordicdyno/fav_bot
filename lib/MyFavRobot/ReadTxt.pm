package MyFavRobot::ReadTxt;

use 5.006;
use strict;
use warnings;
use List::MoreUtils qw(any all none notall);

=head1 NAME

MyFavRobot::ReadTxt - bot for checking robots.txt file

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use MyFavRobot::ReadTxt;

    my $foo = MyFavRobot::ReadTxt->new();
    ...

=head1 METHODS

=head2 

=cut

=head2 new

=cut
sub new {
    my ($class) = shift;
    my %opt     = @_;
    my $name    = exists $opt{bot_name} ? $opt{bot_name} : '';
    my $self = bless { }, $class;
    $self->{bot_name} = $name;
    
    $self;
}

=head2 

=cut

sub parse_file {
    my $self = shift;
    my $file = shift;

    my $raw; # standart idome for small file slurping
    {   local $/ = undef;
        open(my $fh, '<', $file) or die "Can't open file: $file. $!";
        $raw = <$fh>;
    }
    $self->parse( $raw );
}

sub parse {
    my $self = shift;
    $self->{robots_cfg} = {};
    my $data = shift;
    if (ref $data) {
        die "data must be scalar";
        # TODO: add support ref to scalar
    }
    unless (length $data) {
        #$self->{allow_all} = 1;
        return;
    }
    #print "parse:\n", $data, "\n";
    #return;
    my ($agent_name, %robots_cfg);
    open(my $fh, '<', \$data) or die "can't open robots data: $!";
    my $n = 0;
    while (my $line = <$fh>) {
        $n++;
        #print "PARSE $line";
        #chomp $line; 
        $line =~ s/^\s+//g; $line =~ s/s+$//g;
        next unless length $line;
        next if $line =~ /^#/; # support comments
        
        unless ( $line =~ /^([a-zA-Z-]+)\s*:\s*(\S*)/ ) {
            warn "[line: $n] Wrong string format for robots.txt: '$line'. Skip.";
            next;
        }

        my ($cmd, $value) = ($1, $2);
        $cmd = lc $cmd;

        if ( $cmd eq 'host' ) {
            next; # silently skip 'Host' instruction (not support yet)
        }
        elsif ( all {$cmd ne $_} qw (user-agent disallow allow) ) {
            warn "[line: $n] Wrong string format for robots.txt: '$line'. Skip.";
            next;
        }
        #print "$line\n";
        if ($cmd eq 'user-agent') {
            if (not length $value) {
                warn "[line: $n] User-Agent can't be empty, ignore & skip";
                next;
            }
            elsif ($value eq '*') {
                $agent_name = 'ALL';
            }
            else {
                $agent_name = lc $value;
            }
            next;
        }
       
        # ignore string w/o predeclared User-Agent 
        next if not defined $agent_name;

        if (not length $value) {
            if ($cmd ne 'disallow') {
                warn "[line: $n] empty field for '$cmd', ignore";
                next;
            }

            # empty disallow is allow for all
            # (http://www.robotstxt.org/robotstxt.html)
            $cmd = 'allow';
            $value = '/';
        }
        
        # TODO : move to function ( robostr_to_regex )
        # convert strings like /abc/*/cdb/* to regex strings like
        # \Q/abc/\E [^/]+ \Q/cdb/\E [^/]+
        my $check_re = _robomatch_to_regex($value);
        
        # push regex to disallow and allow subkeys for current User-Agent
        $robots_cfg{ $agent_name }{$cmd} = [] 
            unless $robots_cfg{ $agent_name }{$cmd};
        push @{ $robots_cfg{ $agent_name }{$cmd} }, $check_re;
    }

    #use Data::Dumper; print Dumper(\%robots_cfg),"\n";
    $self->{robots_cfg} = \%robots_cfg;
}

sub _robomatch_to_regex {
    my $value = shift;

    my $check_re = qr//;
    my $re_str = '';
    my $val_len = length($value); 
    my $pos = 0;
    do {
        my $pos_asterix = index( $value, '*', $pos);
        my ($escaped_str, $asterix_str);
        if ($pos_asterix == -1) {
            #$re_str .= '\\\\Q' . substr($value, $pos, $val_len - $pos) . '\\\\E';
            $escaped_str =  substr($value, $pos, $val_len - $pos);
            #$re_str .= '\\' . 'Q' . substr($value, $pos, $val_len - $pos) . '\\E';
            #$re_str = 
            $pos = $val_len;
        }
        else {
            my $offset = $pos_asterix - $pos;
            if ($offset) {
                $escaped_str =  substr($value, $pos, $offset);
            }
            $asterix_str .= '[^/]+';
            $pos = $pos_asterix + 1;
        }
        # \Q - disable meta chars in string, \E - end
        if ($escaped_str) {
            $re_str .= quotemeta( $escaped_str );
        }
        if ($asterix_str) {
            $re_str .= $asterix_str;
        }

    } while ( $pos < $val_len);
    
    #print $value, " -> ", $re_str, "\n";
    $check_re = qr/$re_str/;

    return $check_re;
}

sub is_allow_url {
    my $self = shift;
    my $url  = shift;

    unless ($self->{robots_cfg}) {
        warn "robots seems wasn't parsed";
        return 1;
    }

    my $cfg = $self->{robots_cfg};
    my $ua  = $self->{bot_name};
    $ua = lc $ua;
    my $check_ref;


    my $debug = 0;
# TODO: may be change logic ?
    if (exists $cfg->{$ua}) {
        $check_ref = $cfg->{$ua};
    }
    elsif (exists $cfg->{ALL}) {
        $debug = 1;
        $check_ref = $cfg->{ALL};
    }
    else {
        return 1;
    }

    my $ret = 0;
    for my $check_re ( @{ $check_ref->{allow} }) {
        if ($url =~ /$check_re/) {
            $ret = 1; last;
        }
    }
    return $ret if $ret;

    $ret = 1;
    for my $check_re ( @{ $check_ref->{disallow} }) {
        #print $check_re, "\n" if $debug;
        if ($url =~ /$check_re/) {
            $ret = 0; last;
        }
    }
    return $ret;
}

#sub disallow {
#    my $self = shift;
#}


=head1 AUTHOR

Orlovsky Alexander, C<< <nordicdyno at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-myfavrobot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MyFavRobot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MyFavRobot::ReadTxt


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MyFavRobot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MyFavRobot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MyFavRobot>

=item * Search CPAN

L<http://search.cpan.org/dist/MyFavRobot/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Orlovsky Alexander.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of MyFavRobot::ReadTxt
