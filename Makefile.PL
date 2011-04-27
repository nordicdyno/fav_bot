use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MyFavRobot',
    AUTHOR              => q{Orlovsky Alexander <nordicdyno@gmail.com>},
    VERSION_FROM        => 'lib/MyFavRobot.pm',
    ABSTRACT_FROM       => 'lib/MyFavRobot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES => ['bin/fetch_favicons.pl'],
    PREREQ_PM => {
        'Test::More'            => 0,
        'URI'                   => 0,
        'LWP::UserAgent'        => 0,
        'List::MoreUtils'       => 0, 
        'Parallel::ForkManager' => 0,
        'Class::Accessor'       => 0,
        'HTML::Parser'          => 0,
        'MIME::Types'           => 0,
        'File::Copy'            => 0, 
        'File::Spec'            => 0,
        'File::Path'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MyFavRobot-*' },
);
