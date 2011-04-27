package MyFavRobot::FindIco;

use 5.006;
use strict;
use warnings;
use Imager;

=head1 NAME

MyFavRobot::FindIco - found & extract 16x16 ico from gif, png,
                      resize it if need

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use MyFavRobot::FindImg;

    my $foo = MyFavRobot::FindImg->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut


# if in_file  undef, only store empty png
sub process {
    my ($in_file, $out_file) = @_;
    my ($out_w, $out_h) = (16,16);

    my $img_out = Imager->new(xsize => $out_w, ysize => $out_h, channels => 4);

CONTROL_LOOP:
    for ('CONTROL') {
        last if not defined $in_file;
        print "process file $in_file\n";
# TODO: use more portable extension and name check
        unless ($in_file =~ m{([^/]+)\.([^.]+)$}) {
            warn "not matched $in_file (required name.extension format)\n";
            last CONTROL_LOOP;
        }

        my ($f_name, $ext) = map { lc $_ } ($1, $2);;

        my $img_type = imager_detect_type( file => $in_file );
        if (not is_supported_format($img_type) ) {
            warn "unsupported format: $img_type.\n";
            last CONTROL_LOOP;
        }

        my $source_img = find_best_image( $in_file, 
                            {width => $out_w, height => $out_h} );
        if ($source_img) {
            $img_out->rubthrough( src => $source_img );
        }
    }

    $img_out->write( file => $out_file ) or die $img_out->errstr;
}

sub find_best_image {
    my $file = shift;
    my $opt  = shift;
    my ($prefer_w, $prefer_h) = (16,16);
    if (ref $opt){
        ($prefer_w, $prefer_h) = ($opt->{width}, $opt->{height});
    }

    my $img_found;
    my $prefer_ratio = $prefer_w / $prefer_h;
    print "process image: $file\n";
    my @imgs = Imager->read_multi( file => $file )
            or die "Cannot read: ", Imager->errstr;
    return unless @imgs;
    
    my $img_type = imager_detect_type( file => $file );
    #print "check imgs ....\n";
    if ($img_type eq 'gif') { # first image if animated gif
        $img_found = $imgs[0];
    }
    else {
        # if other formats found better size
        #my $ i = 0;
        my @check_imgs;
       IMGS_LOOP:
        for (my $i =0; $i < @imgs; $i++) {
            my $img = $imgs[ $i ];
            #$i++;
            my ($w, $h) = ($img->getwidth(), $img->getheight() );
            if ($w == $prefer_w && $h == $prefer_h) {
                $img_found = $img;
                last IMGS_LOOP;
            }

            print "width => $w, height => $h\n";
            next IMGS_LOOP if ($w == 0 or $h == 0);
            my $ratio = $w / $h;
            # пропускаем все неквадартные картинки (для упрощения логики)
            next IMGS_LOOP if $ratio != $prefer_ratio;
            # TODO: проверять сколько пикселей по минимальной стороне
            #next if
            push @check_imgs, { idx => $i, w => $w, h => $h };
            # TODO: проверять соотношение сторон картинки
            # различие с искомым соотношением и кратные размеры для лучшего
            # масштабирования
        }

        return $img_found if $img_found;
    
        # found better image
            #print "check if not found prefered size:\n";
        for my $struc ( @check_imgs ) {
            # слишком маленькая картинка
            next if $struc->{w} < $prefer_w / 4;
            next if $struc->{w} > $prefer_w * 4;
            # берем первую попавшиюся, не очень большую и не очень
            # маленькую картинку (TODO: лучше выбирать кратную по размерам,
            # для меньшего кол-ва артефактов при масштабировании)
            #print "found img, scale it...\n";
            #print Dumper( $struc );
            $img_found = $imgs[ $struc->{idx} ]
                            ->scale(xpixels => $prefer_w, ypixels => $prefer_h);
        }
    }

    return $img_found;
}

=head2 is_supported_format

=cut

sub is_supported_format {
    my $type_check = shift;
    use Data::Dumper;
    return 1 if $type_check eq 'ico';
    #print Dumper( $Imager::formats );
    return $Imager::formats{ $type_check };
}

# TODO: use Image::ExifTool ?
sub imager_detect_type {
    my %opts = @_;

    #my $class = 'Imager';
    my ($IO, $file) = Imager->_get_reader_io(\%opts, $opts{'type'});
    my $type = Imager::i_test_format_probe( $IO, -1);
    return $type;
}

=head1 AUTHOR

Orlovsky Alexander, C<< <nordicdyno at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-myfavrobot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MyFavRobot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MyFavRobot::FindImg


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

1; # End of MyFavRobot::FindImg
