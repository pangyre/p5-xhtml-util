use strict;
use warnings;
use Test::More "no_plan";
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Util;

{
    ok( my $xu = XHTML::Util->new(\"."),
        "Empty object" );

    diag( join(" ", $xu->tags )) if $ENV{TEST_VERBOSE};

    ok( my @tags = $xu->tags,
        "List of tags" );

    is( @tags, 108,
        "108 tags" );
}

__END__
