#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'MyFavRobot' ) || print "Bail out!\n";
    use_ok( 'MyFavRobot::ReadTxt' ) || print "Bail out!\n";
    use_ok( 'MyFavRobot::FindImg' ) || print "Bail out!\n";
}

diag( "Testing MyFavRobot $MyFavRobot::VERSION, Perl $], $^X" );
