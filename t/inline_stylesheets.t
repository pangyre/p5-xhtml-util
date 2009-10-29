#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;

SKIP: {
    skip "Just not done yet", 2;

    ok( my $xu = XHTML::Util->new,
        "XHTML::Util->new " );

    dies_ok( sub { $xu->inline_stylesheets('whatever') },
             "Not implemented" );
}
