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
        _substr($expected)
      );
    # diag( YAML::Dump($xu) );
}

sub _substr {
    my ( $copy ) = @_;
    $copy =~ s/[^\S ]+//g; # Flatten for nicer verbosity display.
    length($copy) > 60 ?
        substr($copy, 0, 57) . "..." : $copy;
}

sub _trim {
    my @copy = @_;
    s/(\A\s+|\s+\z)//g for @copy;
    wantarray ? @copy : $copy[0];
}

=head1 NOTES

Should URI escape fix-up only happen in ->fix?

=cut

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

Naked entities: <Q&A>
::
Naked entities: &lt;Q&amp;A&gt;

::TEST::DATA::

<b>Already encoded: &lt;Q&amp;A&gt;</b>
::
<b>Already encoded: &lt;Q&amp;A&gt;</b>

::TEST::DATA::

<img src=no-quote.gif alt='<p class="asterix">*</p>' width=10%>
::
<img src="no-quote.gif" alt="&lt;p class=&quot;asterix&quot;&gt;*&lt;/p&gt;" width="10%"/>

::TEST::DATA::

<a href="/moo?cow=cow&flag=burned&site=1">åß∂ƒ</a>
::
<a href="/moo?cow=cow&amp;flag=burned&amp;site=1">åß∂ƒ</a>
