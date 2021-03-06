#!/usr/bin/perl
use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;

ok( my $xu = XHTML::Util->new(\"something"),
    "XHTML::Util->new " );

dies_ok( sub { $xu->translate_tags('whatever') },
         "Not implemented" );
