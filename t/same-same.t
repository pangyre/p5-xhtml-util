use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Util;
use Encode;
use utf8;

# What happens with an empty string document?

{
    my $before = <<"BEFORE";
<p>¶aragraph øne¡</p>

<p>¶aragraph †wo…</p>
BEFORE

    my $after = <<"AFTER";
<p>¶aragraph øne¡</p>
             <p>¶aragraph †wo…

</p>
AFTER

    ok( my $xu = XHTML::Util->new(\$before),
        "XHTML::Util->new(...)" );

    ok( my $xu2 = XHTML::Util->new(\$after),
        "XHTML::Util->new(...)" );

    ok( $xu->same_same($xu),
        "Same same" );

    isnt( $xu->doc->serialize(0), $xu2->doc->serialize(0),
        "And as XML::LibXML fails with keep_blanks" );

    $xu->parser->keep_blanks(0);
    $xu2->parser->keep_blanks(0);

    isnt( $xu->doc->serialize(0), $xu2->doc->serialize(0),
        "And as XML::LibXML works without keep_blanks" );

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

    my $diff = Algorithm::Diff->new( [ split /\n/, $enparaed ],
                                     [ $after->slurp ] );

    while ( $diff->Next() )
    {
        next   if  $diff->Same();
        my $sep = '';
        if(  ! $diff->Items(2)  ) {
            diag(sprintf "%d,%dd%d\n",
                $diff->Get(qw( Min1 Max1 Max2 )));
        } elsif(  ! $diff->Items(1)  ) {
            diag(sprintf "%da%d,%d\n",
                $diff->Get(qw( Max1 Min2 Max2 )));
        } else {
            $sep = "---\n";
            diag(sprintf "%d,%dc%d,%d\n",
                $diff->Get(qw( Min1 Max1 Min2 Max2 )));
        }
        diag( "< $_" )  for  $diff->Items(1);
        diag( $sep );
        diag( "> $_" )  for  $diff->Items(2);
    }
