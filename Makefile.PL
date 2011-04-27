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
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MyFavRobot-*' },
);
