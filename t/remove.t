use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Util;

{
    my $before = <<"BEFORE";
<p><a href="/some/uri">Paragraph one</a>.</p>

<blockquote><p>Paragraph <i><b>two</b>...</i></p></blockquote>
BEFORE

    ok( my $xu = XHTML::Util->new(\$before),
        "XHTML::Util->new(...)" );

    like( $xu->as_string, qr/<a[^.]+Paragraph one<\/a>./,
          '<a/> is in object');

    ok( $xu->remove("p a"), "Remove <a/>s inside <p/>s" );

    unlike( $xu->as_string, qr/<a[^.]+Paragraph one<\/a>/,
          '<a/> and its content are gone');

    like( $xu->as_string, qr/<p>\.<\/p>/,
          '"Empty" <p/> remains');

    ok( $xu->remove("b"), "Remove <b/>s" );
    like( $xu->as_string, qr/<i>\.\.\.<\/i>/,
          '<b/> and its content are gone');

    ok( $xu->remove("i"), "Remove <i/>s" );
    like( $xu->as_string, qr/<p>Paragraph <\/p>/,
          '<i/> and its content are gone');

    ok( $xu->remove("p"), "Remove <p/>s" );

#    diag([ $xu->doc->findnodes("//blockquote") ]->[0]->toStringHTML );
    is( $xu->as_string, '<blockquote/>',
        'Just the empty <blockquote/> left');
}

__END__
