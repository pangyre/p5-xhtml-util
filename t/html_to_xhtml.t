#!/usr/bin/perl
use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;

my $html4 = File::Spec->catfile($FindBin::Bin,"files","html4.html");
ok( my $xu = XHTML::Util->new($html4),
    "XHTML::Util->new with HTML 4" );

dies_ok( sub { $xu->html_to_xhtml('whatever') },
         "Not implemented" );
