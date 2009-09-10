use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Util;
use YAML;

local $/ = "\n::TEST::DATA::\n";

while ( <DATA> )
{
    my ( $input, $expected ) = _trim(split /::/);

    my $xu = XHTML::Util->new(\$input);

    is( _trim($xu->as_string), _trim($expected),
        length($expected) > 30 ?
        substr($expected, 0, 27) . "..." : $expected
      );
    #diag(YAML::Dump($xu));
}

sub _trim {
    my @copy = @_;
    s/(\A\s+|\s+\z)//g for @copy;
    wantarray ? @copy : $copy[0];
}

__DATA__

OH HAI!
::
OH HAI!

::TEST::DATA::

OH<br>HAI!
::
OH<br/>HAI!

::TEST::DATA::

<p>OH HAI!
::
<p>OH HAI!
</p>

::TEST::DATA::

<Q&A>
::
&lt;Q&amp;A&gt;

::TEST::DATA::

<img src=no-quote.gif alt=* width=10%>
::
<img src="no-quote.gif" alt="*" width="10%"/>

::TEST::DATA::

OH HAI!
::
OH HAI!
