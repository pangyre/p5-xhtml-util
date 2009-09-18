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

    ok( $xu->strip_tags("blockquote p"), "Strip p beneath blockquote" );

    unlike( $xu->as_string, qr/<blockquote>[^<]*<p>/,
          'No /<blockquote><p>/');

    like( $xu->as_string, qr/<p>/,
          'Still have a <p>');

    ok( $xu->strip_tags("i,b"), "Try to strip i,b at the top of fragment" );
    unlike( $xu->as_string, qr/<i>/, 'No <i>');
    unlike( $xu->as_string, qr/<b>/, 'No <b>');

    like( $xu->as_string, qr/graph two\.\.\./, 'Remaining text looks good');

    ok( $xu->strip_tags("*"), "Try to strip i,b at the top of fragment" );

#<i><b>two</b>...</i>


}
