#!perl 

use Test::More tests => 6;

BEGIN {
    use_ok( 'MyFavRobot::Utils' )   || print "Bail out!\n";
    use_ok( 'MyFavRobot::FindIco' ) || print "Bail out!\n";
    use_ok( 'MyFavRobot::ReadTxt' ) || print "Bail out!\n";
    use_ok( 'MyFavRobot::HTML::ParseHead' ) || print "Bail out!\n";
    use_ok( 'MyFavRobot::Cmd' )     || print "Bail out!\n";
    use_ok( 'MyFavRobot' )          || print "Bail out!\n";
}

diag( "Testing MyFavRobot $MyFavRobot::VERSION, Perl $], $^X" );
