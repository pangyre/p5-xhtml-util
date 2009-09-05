use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
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

    $xu->debug(3);

    isa_ok( $xu, "XHTML::Util" );

    is($xu->as_string, $before->slurp,
       "Original content matches stringified object");

    ok( my $enparaed = $xu->enpara(),
        "Enpara'ing the content" );

    is( $enparaed, $after->slurp,
        "Enpara'ed content of 'before' matches 'after'" );
}

__END__

my $src = _baseline();

ok( my $paras = $xu->enpara($src),
    "Enpara the test text"
    );

# diag("PARAS: " . $paras) if $ENV{TEST_VERBOSE};

is($paras, Encode::decode_utf8(_fixed()),
   "enpara doing swimmingly");

sub _fixed {
    q{<p>Not in<br/>
the first abutting.</p>
<p>Did it manually here.</p>
<p><b>Didn't</b> <i>do it.</i></p>
<p>Did it manually again in the third.</p><pre>
This is the fourth block and has


“triple spacing in it and an &amp;”
</pre>
<p>Didn't do it here<br/>
in<br/>
the fifth.</p>
<p>Did it here in
the sixth mashed up against the fifth so we
could not possibly split on whitespace.</p><hr/>
<p>Have a <b>bold</b> here that needs a paragraph.</p>

<p>also need</p>

<p>three in a row</p>

<p>and four for that matter</p>
<p>real para back into the mix</p>
<p>And two in a row <a href="http://localhost/a/12" title="Read&#10;more of " so="So" i="I" kinda="kinda" have="have" a="a" crush="">[read more]</a></p>

<p>
  <b>asdf</b>
</p>

<p>!</p>

<p>?</p>};
}

sub _baseline {
    q{Not in
the first abutting.<p>Did it manually here.</p>

<b>Didn't</b> <i>do it.</i>

<p>Did it manually again in the third.</p>

<pre>
This is the fourth block and has


“triple spacing in it and an &amp;”
</pre>
Didn't do it here
in
the fifth.<p>Did it here in
the sixth mashed up against the fifth so we
could not possibly split on whitespace.</p>

<hr/>

Have a <b>bold</b> here that needs a paragraph.

also need

three in a row

and four for that matter

<p>real para back into the mix</p>

And two in a row <a href="http://localhost/a/12" title="Read
more of "So I kinda have a crush">[read more]</a>

<b>asdf</b>

!

?

};
}

__END__
