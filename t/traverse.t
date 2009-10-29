#!/usr/bin/perl
use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;

TODO: {
    local $TODO = "Unimplemented";

    ok( my $xu = XHTML::Util->new,
        "XHTML::Util->new " );

    ok( sub { $xu->traverse('whatever') },
        "Not implemented" );

}
