use strict;
use inc::Module::Install;

name "XHTML-Util";
license 'perl';
all_from "lib/XHTML/Util.pm";
repository "git://github.com/pangyre/p5-xhtml-util";

requires "Encode" => 2;
requires "HTML::Tagset" => 3.02;
requires "XML::LibXML" => 1.6;
requires "XML::Normalize::LibXML" => undef;
requires "Scalar::Util" => undef;
requires "HTML::Tagset" => 3.02;
requires "HTML::DTD" => 0.03;
requires "HTML::Entities" => undef;
requires "CSS::Tiny" => undef;
requires "HTML::Selector::XPath" => undef;
requires "HTML::TokeParser::Simple" => undef;
requires "XHTML::Util" => undef;

build_requires "Test::More" => 0.5;
build_requires "File::Spec" => 3;

system( 'pod2text lib/XHTML/Util.pm > README' );

auto_install;
WriteAll;

__END__

2.6.2?
    XML::LibXML::LIBXML_DOTTED_VERSION
2.7.0 better


