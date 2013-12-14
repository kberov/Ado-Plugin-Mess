#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ado::Plugin::Mess' ) || print "Bail out!\n";
}

diag( "Testing Ado::Plugin::Mess $Ado::Plugin::Mess::VERSION, Perl $], $^X" );
