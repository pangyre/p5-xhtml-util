use strict;
use inc::Module::Install;

name "XHTML-Util";
license 'perl';
all_from "lib/XHTML/Util.pm";
repository "git://github.com/pangyre/p5-xhtml-util";

requires "Encode" => 2;
requires "HTML::Tagset" => 3.02;
requires "XML::LibXML" => "1.69"; # Is this where unicode was all normalized?
requires "XML::Normalize::LibXML";

requires "Scalar::Util";
requires "HTML::Tagset" => 3.02;
requires "HTML::DTD" => 0.03;
requires "HTML::Entities";
requires "CSS::Tiny";
requires "HTML::Selector::XPath" => "0.04";
requires "HTML::TokeParser::Simple";
requires "LWP::Simple";

test_requires "Test::More" => 0.5;
test_requires "YAML";
test_requires "Test::Exception" => 0.2;
test_requires "File::Spec" => 3;
test_requires "Algorithm::Diff";
test_requires "autodie";

if ( $Module::Install::AUTHOR )
{
    system("pod2text lib/XHTML/Util.pm > README") == 0
        or die "Couldn't update the README";
}

auto_install;
WriteAll;

__END__

2.6.2?
    XML::LibXML::LIBXML_DOTTED_VERSION
2.7.0 better


