use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Util;
use utf8;

# What happens with an empty string document?

{
    my $before = <<"BEFORE";
<p><a href="/some/uri">¶aragraph øne¡</a></p>

<blockquote><p>¶aragraph <i><b>two</b>...</i></p></blockquote>
BEFORE

    ok( my $xu = XHTML::Util->new(\$before),
        "XHTML::Util->new(...)" );

#    diag( $xu->as_string );

    ok( $xu->strip_tags("a"), "Strip <a/>" );

    unlike( $xu->as_string, qr/<a\s/,
          'No /<a\s/');

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

{
    my $script = <<'_script_';
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.js"
  type="text/javascript"></script>
<script type="text/javascript">//<![CDATA[
jQuery(function($) {
  $("body").html("<h1>OH HAI</h1>");
});
//]]> </script>
_script_

    my $xu = XHTML::Util->new(\$script);
    my $xu2 = XHTML::Util->new(\$script); # Breaks with clone, so clone is wonky.
    $xu->strip_tags("script");
    like( $xu, qr/jQuery/,
          "Script text remains after strip_tags(script)" );
    $xu2->remove("script");
    is( $xu2, "",
        "Nothing remains after remove(script)" );

}
