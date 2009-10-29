use strict;
use warnings;
use Test::More "no_plan";
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Util;

{
    ok( my $xu = XHTML::Util->new(\""),
        "Empty object" );

    diag( join(" ", $xu->tags ));
die scalar($xu->tags);
    ok( scalar(1,$xu->tags),
        "List of tags" );
}

__END__
