use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use FindBin qw( $Bin );
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($Bin, '../lib');
use XHTML::Util;

dies_ok( sub { my $xu = XHTML::Util->new },
         "XHTML::Util->new dies without content" );

{
    my $before = Path::Class::File->new("$FindBin::Bin/files/basics-before.txt");
    my $after = Path::Class::File->new("$FindBin::Bin/files/basics-after.txt");
    cmp_ok( $before->slurp, "ne", $after->slurp,
            "Before and after differ");

    ok( my $xu = XHTML::Util->new($before->stringify),
        "XHTML::Util->new files/basics-before.txt" );

    ok( $xu->is_fragment,
        "Doc is a fragment" );

    $xu->debug(3);

    isa_ok( $xu, "XHTML::Util" );

    is(XHTML::Util::_trim($xu->as_string), XHTML::Util::_trim(scalar $before->slurp),
       "Original content matches stringified object");

    ok( my $enparaed = $xu->enpara(),
        "Enpara'ing the content" );

    is( $enparaed, $after->slurp,
        "Enpara'ed content of 'before' matches 'after'" );
}

{
    ok( my $xu = XHTML::Util->new("$FindBin::Bin/files/basic.html"),
        "XHTML::Util->new(basic.html)" );
    # diag($xu->as_string());
}

{
    my $xu = XHTML::Util->new(\'<script type="text/javascript">alert("OH HAI")</script>');
    ok( $xu->strip_tags('script'),
        "Stripping script tags" );
    is( $xu->as_string, '<![CDATA[alert(&quot;OH HAI&quot;)]]>',
        "Smooth as mother's butter" );
}

__END__
