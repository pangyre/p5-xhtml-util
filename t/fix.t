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
    chomp;
    my ( $input, $expected ) = _trim(split /::/)
        or next;

    my $xu = XHTML::Util->new(\$input);
    $xu->fix;
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

=head1 DUMMY STUFF

<p>OH HAI!
::
<p>OH HAI!
</p>

::TEST::DATA::

<br height=10>
::
<br/>

::TEST::DATA::

<abbr>SS</abbr>
::
<abbr title="[SS]">SS</abbr>

=cut

__DATA__
<p>OH HAI!
::
<p>OH HAI!
</p>

::TEST::DATA::

<img src='/moo.cow'>
::
<img src="/moo.cow" alt="/moo.cow"/>

::TEST::DATA::
