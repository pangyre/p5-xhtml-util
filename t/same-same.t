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
             <p>¶aragraph †wo…</p> 
   
AFTER

    ok( my $xu = XHTML::Util->new(\$before),
        "XHTML::Util->new(...)" );

    ok( my $xu2 = XHTML::Util->new(\$after),
        "XHTML::Util->new(...)" );

    ok( $xu->same_same($xu2),
        "Same same" );

    isnt( $xu->doc->serialize(0), $xu2->doc->serialize(0),
        "And as XML::LibXML fails" );
}

__END__
