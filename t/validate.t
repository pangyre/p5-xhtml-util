#!/usr/bin/perl
use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;

my $basic_html = "$FindBin::Bin/files/basic.html";
ok( my $xu = XHTML::Util->new($basic_html),
    "XHTML::Util->new(basic.html)" );

ok( $xu->is_valid(),
    "$basic_html is_valid" );

lives_ok( sub { $xu->validate() },
          "$basic_html validates" );

