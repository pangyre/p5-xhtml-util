package XHTML::Util;
use strict;
use warnings;
no warnings "uninitialized";
use Carp;
use XML::LibXML;
use HTML::Tagset 3.02 ();
use HTML::Entities qw( encode_entities decode_entities );
use HTML::Selector::XPath ();
use HTML::DTD;
use Path::Class;
use Encode;
use Scalar::Util qw( blessed );
use HTML::TokeParser::Simple;
use XML::Normalize::LibXML qw( xml_normalize );

use overload q{""} => sub { +shift->as_string }, fallback => 1;

our $VERSION = "0.99_04";
our $AUTHORITY = 'cpan:ASHLEY';
our $TITLE_ATTR = join("/", __PACKAGE__, $VERSION);

our $FRAGMENT_SELECTOR = "div[title='$TITLE_ATTR']";
our $FRAGMENT_XPATH = HTML::Selector::XPath::selector_to_xpath($FRAGMENT_SELECTOR);

my $isKnown = { %HTML::Tagset::isKnown }; # We modify this one.
my $emptyElement = \%HTML::Tagset::emptyElement;
my $isBodyElement = \%HTML::Tagset::isBodyElement;
my $isPhraseMarkup = \%HTML::Tagset::isPhraseMarkup;
#my $canTighten = \%HTML::Tagset::canTighten;
#my $isHeadElement = \%HTML::Tagset::isHeadElement;
#my $isHeadOrBodyElement = \%HTML::Tagset::isHeadOrBodyElement;
#my $isList = \%HTML::Tagset::isList;
#my $isTableElement = \%HTML::Tagset::isTableElement;
my $isFormElement = \%HTML::Tagset::isFormElement;
#my $p_closure_barriers = \@HTML::Tagset::p_closure_barriers;

# Accommodate HTML::TokeParser's idea of a "tag."
$isKnown->{"$_/"} = 1 for keys %{$emptyElement};
my $isBlockLevel = { map {; $_ => 1 }
                     grep { ! ( $isPhraseMarkup->{$_} || $isFormElement->{$_} ) }
                     keys %{$isBodyElement}
                 };
# use YAML; die YAML::Dump($isBlockLevel);

sub tags {
    grep { ! /\W/ }
        sort keys %HTML::Tagset::isKnown;
}

sub new {
    my $class = shift;
    my $arg = shift or croak "new requires an argument";
    my $self = bless {}, $class;

    if ( ref($arg) eq "SCALAR" )
    {
        $self->_parse( $$arg );
        # $self->_original_string( $$arg );
    }
    elsif ( blessed($arg) eq "Path::Class::File" )
    {
        $self->_parse( scalar $arg->slurp );
    }
    elsif ( blessed($arg) and $arg->can("getlines") )
    {
        $self->_parse( join("", $arg->getlines) );
    }
    else
    {
        $self->_parse( scalar Path::Class::File->new($arg)->slurp );
    }
    $self;
}

sub debug {
    my $self = shift;
    $self->{_debug} = shift if @_;
    $self->{_debug} || 0;
}

sub as_string {
    my $self = shift;
    my @args = @_ ? @_ : ( 1, "UTF-8" );
    if ( $self->is_document )
    {
        return _trim( Encode::decode_utf8( $self->doc->serialize(@args) ) );
    }
    elsif ( $self->is_fragment )
    {
        croak "No root in document\n", $self->doc->serialize
            unless $self->root;

        my ( $fragment ) = $self->root->findnodes($FRAGMENT_XPATH);

        croak "No fragment...?\n", $self->doc->serialize
            unless $fragment;

        my $out = "";
        $out .= $_->serialize(@args) for $fragment->childNodes;

        return Encode::decode_utf8( _trim($out) );
    }
    else
    {
        die "No type was found, internal issue :(";
    }
}

sub is_document {
    +shift->{_type} eq "document";
}

sub is_fragment {
    +shift->{_type} eq "fragment";
}

sub _parse {
    my $self = shift;
    $self->{_sanitized} =
        $self->_sanitize( $self->{_original_string} = shift );

    if ( $self->{_original_string} =~ /\A(?:<\W[^>]+>|\s+)*<html/i )
    {
        $self->{_type} = "document";
        $self->{_doc} = $self->parser->parse_html_string($self->{_sanitized});
        # Special case, doc contains ONLY 1 p and its first and last
        # child of body then we should replace it with the FRAGMENT
        # holder div.
    }
    else
    {
        # SHOULD we sanitize first?
        $self->{_type} = "fragment";

        $self->{_doc} = $self->parser
            ->parse_html_string(join("\n",
                                     "<html><head><title></title></head><body>",
                                     sprintf('<div title="%s">',
                                             $TITLE_ATTR
                                     ),
                                     $self->{_sanitized},
                                     #Encode::encode_utf8($self->{_sanitized}),
                                     '</div></body></html>')
            );
    }

    $self->root->normalize;
    $self->doc;
}

sub root {
    +shift->doc->getDocumentElement;
}

sub doc {
    +shift->{_doc};
}

sub parser {
    my $self = shift;
    return $self->{_parser} if $self->{_parser};
    $self->{_parser} = XML::LibXML->new;
    $self->{_parser}->recover_silently(1);
    $self->{_parser}->keep_blanks(1);
    $self->{_parser};
}

sub is_valid {
    my $self = shift;
    return 1 if $self->doc->is_valid;
    # 321 debug about which DTD is being used.
    my $dtd_name = shift || "xhtml1-transitional";
    my $dtd_string = HTML::DTD->get_dtd("$dtd_name.dtd");
    $self->{_dtd} = XML::LibXML::Dtd->parse_string($dtd_string);
    return $self->doc->is_valid($self->{_dtd}) ? $self : undef;
}

sub validate {
    my $self = shift;
    return 1 if $self->is_valid;
    return $self->doc->validate($self->{_dtd});
}

sub _original_string {
    my $self = shift;
    $self->{_original_string} ||= shift;
#    $self->{_original_string} ||= Encode::encode_utf8( shift ); #321
    $self->{_original_string};
}

sub _return {
    my $self = shift; # 321 ARGS for serialize.
    xml_normalize( $self->doc );
    my $callers_wantarray = [ caller(1) ]->[5];
    return unless defined $callers_wantarray; # Void context.
    return $self;    # Should always return self?
}

sub fix {
    my $self = shift;
    return $self->_return if $self->is_valid;

    for my $fixable ( qw( img ) )
    {
        my $method = "_fix_$fixable";
        for my $node ( $self->root->findnodes("//$fixable") )
        {
            $self->$method($node);
        }
    }

    $self->is_valid()
        or carp "Could not fix the problems with this document";
    $self->validate();
    $self->_return;
}

sub _sanitize {
    my $self = shift;
    my $fragment = shift or return;
    #$fragment = Encode::decode_utf8($fragment);
    my $p = HTML::TokeParser::Simple->new(\$fragment);
    my $renew = "";
    my $in_body = 0;
  TOKEN:
    while ( my $token = $p->get_token )
    {
        #warn sprintf("%10s %10s %s\n",  $token->[-1], $token->get_tag, blessed($token));
        #no warnings "uninitialized";
        if ( $isKnown->{$token->get_tag} )
        {
            if ( $token->is_start_tag )
            {
                my @pair;
                for my $attr ( @{ $token->get_attrseq } )
                {
                    next if $attr eq "/";
                    my $value = encode_entities(decode_entities($token->get_attr($attr)));
                    push @pair, join("=",
                                     $attr,
                                     qq{"$value"});
                }
                $renew .= "<" . join(" ", $token->get_tag, @pair);
                $renew .= ( $token->get_attr("/") || $emptyElement->{$token->get_tag} ) ? "/>" : ">";
            }
            else
            {
                $renew .= $token->as_is;
            }
        }
        elsif ( $token->is_declaration or $token->is_pi )
        {
            $renew .= $token->as_is;
        }
        else
        {
            $renew .= encode_entities(decode_entities($token->as_is),'<>"&');
        }
    }
    return $renew;
}

sub body {
    [ shift->doc->findnodes("//body") ]->[0];
}

sub head {
    [ shift->doc->findnodes("//head") ]->[0];
}

sub as_fragment {
    my $self = shift;
    my ( $fragment ) = $self->doc->findnodes($FRAGMENT_XPATH);
    $fragment ||= $self->body;
    my $out = "";
    $out .= $_->serialize(1,"UTF-8") for $fragment->childNodes;
    return $out;
}

sub _make_selector {
    my $self = shift;
    my $selector = shift;
    unless ( $selector )
    {
        my $base = $self->is_fragment ? $FRAGMENT_SELECTOR : "body";
        $selector = "$base, $base *";
    }
    warn "Selector: $selector" if $self->debug > 2;
    $selector =~ m,\A/, ?
        $selector :
        HTML::Selector::XPath::selector_to_xpath($selector);
}

sub traverse {
    my $self = shift;
    my $xpath = $self->_make_selector(+shift) if @_ == 2;
    my $code = shift;

    if ( $xpath )
    {
        for my $node ( $self->root->findnodes("$xpath") )
        {
            $code->($node);
        }
    }
    else
    {
        $code->($self->root);
    }
    $self->_return;
}


sub enpara {
    my $self = shift;
    my $xpath = $self->_make_selector(+shift);
    my $root = $self->root;
    my $doc = $self->doc;

  NODE:
    for my $designated_enpara ( $root->findnodes("$xpath") )
    {
        # warn "FOUND ", $designated_enpara->nodeName, $/;
        # warn "*********", $designated_enpara->toString if $self->debug > 2;
        next unless $designated_enpara->nodeType == 1;
        next NODE if $designated_enpara->nodeName eq 'p';
        if ( $designated_enpara->nodeName eq 'pre' )  # I don't think so, honky.
        {
            # Expand or leave it alone? or ->validate it...?
            carp "It makes no sense to enpara within a <pre/>; skipping";
            next NODE;
        }
        next unless $isBlockLevel->{$designated_enpara->nodeName};

        $self->_enpara_this_nodes_content($designated_enpara, $doc);
    }
    $self->_enpara_this_nodes_content($root, $doc);
    $self->_return;
}

sub _enpara_this_nodes_content {
    my ( $self, $parent, $doc ) = @_;
    my $lastChild = $parent->lastChild;
    my @naked_block;
    for my $node ( $parent->childNodes )
    {
        if ( $isBlockLevel->{$node->nodeName}
             or
             $node->nodeName eq "a" # special case block level, so IGNORE
             and
             grep { $_->nodeName eq "img" } $node->childNodes
             )
        {
            next unless @naked_block; # nothing to enblock
            my $p = $doc->createElement("p");
            $p->setAttribute("enpara","enpara");
            $p->setAttribute("line",__LINE__) if $self->debug > 4;
            $p->appendChild($_) for @naked_block;
            $parent->insertBefore( $p, $node )
                if $p->textContent =~ /\S/;
            @naked_block = ();
        }
        elsif ( $node->nodeType == 3
                and
                $node->nodeValue =~ /(?:[^\S\n]*\n){2,}/
                )
        {
            my $text = $node->nodeValue;
            my @text_part = map { $doc->createTextNode($_) }
                split /([^\S\n]*\n){2,}/, $text;

            my @new_node;
            for ( my $x = 0; $x < @text_part; $x++ )
            {
                if ( $text_part[$x]->nodeValue =~ /\S/ )
                {
                    push @naked_block, $text_part[$x];
                }
                else # it's a blank newline node so _STOP_
                {
                    next unless @naked_block;
                    my $p = $doc->createElement("p");
                    $p->setAttribute("enpara","enpara");
                    $p->setAttribute("line",__LINE__) if $self->debug > 4;
                    $p->appendChild($_) for @naked_block;
                    @naked_block = ();
                    push @new_node, $p;
                }
            }
            if ( @new_node )
            {
                $parent->insertAfter($new_node[0], $node);
                for ( my $x = 1; $x < @new_node; $x++ )
                {
                    $parent->insertAfter($new_node[$x], $new_node[$x-1]);
                }
            }
            $node->unbindNode;
        }
        elsif ( $node->nodeName !~ /\Ahead|body\z/ ) # Hack? Fix real reason? 321
        {
            push @naked_block, $node; # if $node->nodeValue =~ /\S/;
        }

        if ( $node->isSameNode( $lastChild )
             and @naked_block )
        {
            my $p = $doc->createElement("p");
            $p->setAttribute("enpara","enpara");
            $p->setAttribute("line",__LINE__) if $self->debug > 4;
            $p->appendChild($_) for ( @naked_block );
            $parent->appendChild($p) if $p->textContent =~ /\S/;
        }
    }

    my $newline = $doc->createTextNode("\n");
    my $br = $doc->createElement("br");

    for my $p ( $parent->findnodes('//p[@enpara="enpara"]') )
    {
        $p->removeAttribute("enpara");
        $parent->insertBefore( $newline->cloneNode, $p );
        $parent->insertAfter( $newline->cloneNode, $p );

        my $frag = $doc->createDocumentFragment();

        my @kids = $p->childNodes();
        for ( my $i = 0; $i < @kids; $i++ )
        {
            my $kid = $kids[$i];
            next unless $kid->nodeName eq "#text";
            my $text = $kid->nodeValue;
            $text =~ s/\A\r?\n// if $i == 0;
            $text =~ s/\r?\n\z// if $i == $#kids;

            my @lines = map { $doc->createTextNode($_) }
                split /(\r?\n)/, $text;

            for ( my $i = 0; $i < @lines; $i++ )
            {
                $frag->appendChild($lines[$i]);
                unless ( $i == $#lines
                         or
                         $lines[$i]->nodeValue =~ /\A\r?\n\z/ )
                {
                    $frag->appendChild($br->cloneNode);
                }
            }
            $kid->replaceNode($frag);
        }
    }
}

sub _trim {
    s/\A\s+|\s+\z//g for @_;
    wantarray ? @_ : $_[0];
}

sub _fix_img {
    my ( $self, $img ) = @_;
    unless ( $img->hasAttribute("src") )
    {
        croak "There is no way to fix an image without a source";
    }
    unless ( $img->hasAttribute("alt") )
    {
        $img->setAttribute("alt", $img->getAttribute("src"));
    }
}

sub _fix_center {
    my ( $self, $center ) = @_;
    # <center> --> <div style="text-align:center">
    die "Unimplemented";
}

sub _make_selector_xpath {
    my $self = shift;
    my $selector = shift;
    my $base = $self->is_fragment ? $FRAGMENT_SELECTOR : "body";
    my $xpath = HTML::Selector::XPath::selector_to_xpath("$base $selector");
    warn "XPATH: $xpath\n" if $self->debug >= 5;
    return $xpath;
}

sub remove {
    my $self = shift;
    my $xpath = $self->_make_selector_xpath(@_);
    for my $node ( $self->root->findnodes($xpath) )
    {
        $node->parentNode->removeChild($node);
    }
    $self->_return;
}

sub strip_tags {
    my $self = shift;
    my $xpath = $self->_make_selector_xpath(@_);

    for my $node ( $self->root->findnodes($xpath) )
    {
        my $fragment = $self->doc->createDocumentFragment;
        for my $n ( $node->childNodes )
        {
            $fragment->appendChild($n);
        }
        $node->replaceNode($fragment);
    }
    $self->_return;
}

sub same_same {
    my $self = shift;
    my $other = shift;
    my $self2 = blessed($other) eq __PACKAGE__ ?
        $other : __PACKAGE__->new($other);

    $self->parser->keep_blanks(0);

    my $one = $self->parser->parse_string($self->root->serialize(0))->serialize(0);
    my $two = $self->parser->parse_string($self2->root->serialize(0))->serialize(0);

    $self->parser->keep_blanks(1);

    $one eq $two or die "$one\n\n$two"
}

1;

__END__

=head1 NAME

XHTML::Util - (alpha software) powerful utilities for common but difficult to nail HTML munging.

=head2 VERSION

0.99_04

=head1 SYNOPSIS

 use strict;
 use warnings;
 use XHTML::Util;
 my $xu = XHTML::Util
    ->new(\"This is naked\n\ntext for making into paragraphs.");
 print $xu->enpara, $/;
 
 # <p>This is naked</p>
 #
 # <p>text for making into paragraphs.</p>

 $xu = XHTML::Util
     ->new(\"<blockquote>Quotes should probably have paras.</blockquote>");
 print $xu->enpara("blockquote");
 
 # <blockquote>
 #   <p>Quotes should probably have paras.</p>
 # </blockquote>

 $xu = XHTML::Util
     ->new(\'<i><a href="#"><b>Something</b></a>.</i>');
 
 print $xu->strip_tags('a');
 # <i><b>Something</b>.</i>

=head1 DESCRIPTION

You can use CSS expressions to most of the methods. E.g., to only enpara the contents of div tags with a class of "enpara" -- C<< E<lt>div class="enpara"/E<gt> >> -- you could do this-

 print $xu->enpara("div.enpara");

To do the contents of all blockquotes and divs-

 print $xu->enpara("div, blockquote");

Alterations to the XHTML in the object are persistent.

 my $xu = XHTML::Util
     ->new(\'<script>alert("OH HAI")</script>');
 $xu->strip_tags('script');

Will remove the script tagsE<mdash>not the script content thoughE<mdash>so the next time you call anything that returns the stringified object the changes will remainE<ndash>

 print $xu->as_string, $/;
 # alert("OH HAI")

Well... really you'll get C<< E<lt>![CDATA[alert(&quot;OH HAI&quot;)]]E<gt> >>.

=head1 METHODS

=head2 new

Creates a new C<XHTML::Util> object.

=head2 strip_tags

Why you might need this-

 my $post_title = "I <3 <a href="http://icanhascheezburger.com/">kittehs</a>";
 my $blog_link = some_link_maker($post_title);
 print $blog_link;

 <a href="/oh-noes">I <3 <a href="http://icanhascheezburger.com/">kittehs</a></a>

That isn't legal so there's no definition for what browsers should do with it. Some sort of tolerate it, some don't. It's never going to be a good user experience.

What you can do is something like thisE<ndash>

 my $post_title = "I <3 <a href="http://icanhascheezburger.com/">kittehs</a>";
 my $safe_title = $xu->strip_tags($post_title, ["a"]);
 # Menu link should only go to the single post page.
 my $menu_view_title = some_link_maker($safe_title);
 # No need to link back to the page you're viewing already.
 my $single_view_title = $post_title;

=head2 remove

Takes a CSS selector string. Completely removes the matched nodes, including their content. This differs from L</strip_tags> which retains the child nodes intact and only removes the tags proper.

 # Remove <center/> tags and external images.
 my $cleaned = $xu->remove("center, img[src^='http']");

=head2 traverse

Walks the given nodes and executes the given callback. Can be called with a selector or without. If called with a selector, the callback sub receives the selected nodes as its arguments.

 $xu->traverse("div.fancy", sub { my $div_node = shift });

Without a selector it receives the document root.

 $xu->traverse(sub { my $root = shift });

=head2 translate_tags

[Not implemented.] Translates one tag to another.

=head2 remove_style

[Not implemented.] Removes styles from matched nodes. To remove all style from a fragment-

 $xu->remove_style("*");

(Should also remove style sheets, yes?)

=head2 inline_stylesheets

[Not implemented.] Moves all linked stylesheet information into inline style attributes. This is useful, for example, when distributing a document fragment like an RSS/Atom feed and having it match its online appearance.

=head2 sanitize

[Not implemented.] Upgrades old or broken HTML to valid XHTML.

=head2 fix

[Partially implemented.] Attempts to make many known problems go away. E.g., entity escaping, missing alt attributes of images, etc.

=head2 validate

Validates a given document or fragment (which is actually contained in a full document) against a DTD provided by name or, if none is provided, it will validate against F<xhtml1-transitional>. Uses L<XML::LibXML>'s validate under the covers.

=head2 is_valid

A non-fatal version of L</validate>. Returns true on success, false on failure.

=head2 enpara

To add paragraph markup to naked text. There are many, many implementations of this basic idea out there as well as many like Markdown which do much more. While some are decent, none is really meant to sling arbitrary HTML and get DWIM behavior from places where it's left out; every implementation I've seen either has rigid syntax or has beaucoup failure prone edge cases. Consider these-

 Is this a paragraph
 or two?

 <p>I can do HTML when I'm paying attention.</p>
 <p style="color:#a00">Or I need to for some reason.</p>
 Oh, I stopped paying attention... What happens here? Or <i>here</i>?

 I'd like to see this in a paragraph so it's legal markup.
 <pre>
 now
 this
 should


 not be touched!
 </pre>I meant to do that.

With C<< XHTML::Util-E<gt>enpara >> you will get-

 <p>Is this a paragraph<br/>
 or two?</p>

 <p>I can do HTML when I'm paying attention.</p>
 <p style="color:#a00">Or I need to for some reason.</p>
 <p>Oh, I stopped paying attention... What happens here? Or <i>here</i>?</p>

 <p>I'd like to see this in a paragraph so it's legal markup.</p>
 <pre>
 now
 this
 should
 
 
 not be touched!
 </pre>
 <p>I meant to do that.</p>

=head2 parser

The L<XML::LibXML> parser object used to parse (X)HTML.

=head2 doc

The L<XML::LibXML::Document> object created from input.

=head2 root

The documentElement of the L<XML::LibXML::Document> object.

=head2 head

The head element.

=head2 body

The body element.

Note there is always an implicit head and body even with fragments because libxml creates them, well, we ask it to do so.

=head2 as_fragment

Returns the original (intent-wise) fragment or the elements within the body if starting with a full document.

=head2 as_string

Stringified version of object. If the object was created from an HTML fragment, a fragment will be returned.

=head2 debug

Yep. 1-5 with higher giving more info to STDERR.

=head2 is_document

Returns true if the originally parsed item was a full HTML document.

=head2 is_fragment

Returns true if the originally parsed item was a fragment.

=head2 same_same

Takes another XHTML::Util object or the valid argument to create one. Attempts to determine if the resulting object is the same as the calling object. E.g.,

 print $xu->same_same(\"<p>OH HAI</p>") ?
     "Yepper!\n" : "Noes...\n";

=head2 tags

Returns a list of all known HTML tags. Please ignore method. I'm not sure it's a good idea, well named, or will remain.

=head2 selector_to_xpath

This wraps L<selector_to_xpath HTML::Selector::Xpath/selector_to_xpath>. Not really meant to be used but exposed in case you want it.

 print $xu->selector_to_xpath("form[name='register'] input[type='password']");
 # //form[@name='register']//input[@type='password']

=head1 TO DO

I think the default doc should be \"". There is no reason to jump through that hoop if wanting to build up something from scratch.

Finish spec and tests. Get it running solid enough to remove alpha label. Generalize the argument handling. Provide optional setting or methods for returning nodes instead of serialized content. Improve document/head related handling/options.

I can see this being easier to use functionally. I haven't decided on the argspec or method--E<gt>sub approach for that yet. I think it's a good idea.

=head1 BUGS AND LIMITATIONS

All input should be UTF-8 or at least safe to run L<decode_utf8|Encode/decode_utf8> on. Regular Latin character sets, I suspect, will be fine but extended sets will probably give garbage or unpredictable results; guessing.

This will wreck XML and probably XHTML with a custom DTD too. It uses L<HTML::Tagset>'s conception of what valid tags are. This is not optimal but it is easier than DTD handling. It might improve to more automatic detection in the future.

I have used many of these methods and snippets in many projects and I'm tired of recycling them. Some are extremely useful and, at least in the case of L</enpara>, better than any other implementation I've been able to find in any language.

That said, a lot of the code herein is not well tested or at least not well tested in this incarnation. Bug reports and good feedback are B<adored>.

=head1 SEE ALSO

L<XML::LibXML>, L<HTML::Tagset>, L<HTML::Entities>, L<HTML::Selector::XPath>, L<HTML::TokeParser::Simple>, L<CSS::Tiny>.

CSS W3Schools, L<http://www.w3schools.com/Css/default.asp>, Learning CSS at W3C, L<http://www.w3.org/Style/CSS/learning>.

=head1 AUTHOR

Ashley Pond V, ashley at cpan.org.

=head1 COPYRIGHT & LICENSE

Copyright (E<copy>) 2006-2009.

This program is free software; you can redistribute it or modify it or both under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty for the software, to the extent permitted by applicable law. Except when otherwise stated in writing the copyright holders or other parties provide the software "as is" without warranty of any kind, either expressed or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose. The entire risk as to the quality and performance of the software is with you. Should the software prove defective, you assume the cost of all necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing will any copyright holder, or any other party who may modify and/or redistribute the software as permitted by the above licence, be liable to you for damages, including any general, special, incidental, or consequential damages arising out of the use or inability to use the software (including but not limited to loss of data or data being rendered inaccurate or losses sustained by you or third parties or a failure of the software to operate with any other software), even if such holder or other party has been advised of the possibility of such damages.

=cut

typedef enum {
    XML_ELEMENT_NODE=           1,
    XML_ATTRIBUTE_NODE=         2,
    XML_TEXT_NODE=              3,
    XML_CDATA_SECTION_NODE=     4,
    XML_ENTITY_REF_NODE=        5,
    XML_ENTITY_NODE=            6,
    XML_PI_NODE=                7,
    XML_COMMENT_NODE=           8,
    XML_DOCUMENT_NODE=          9,
    XML_DOCUMENT_TYPE_NODE=     10,
    XML_DOCUMENT_FRAG_NODE=     11,
    XML_NOTATION_NODE=          12,
    XML_HTML_DOCUMENT_NODE=     13,
    XML_DTD_NODE=               14,
    XML_ELEMENT_DECL=           15,
    XML_ATTRIBUTE_DECL=         16,
    XML_ENTITY_DECL=            17,
    XML_NAMESPACE_DECL=         18,
    XML_XINCLUDE_START=         19,
    XML_XINCLUDE_END=           20
#ifdef LIBXML_DOCB_ENABLED
   ,XML_DOCB_DOCUMENT_NODE=     21
#endif
} xmlElementType;


use HTML::Entities;
our %Charmap = %HTML::Entities::entity2char;
delete @Charmap{qw( amp lt gt quot apos )};



translate_tags

traverse("/*") -> callback

strip_styles(* or [list])
strip_attributes()

inline_stylesheets(names/paths)

fragment_to_xhtml

We WILL NOT be covering other well known and well done implementations like HTML::Entities or URI::Escape

   use Rose::HTML::Util qw(:all);

   $esc = escape_html($str);
   $str = unescape_html($esc);

   $esc = escape_uri($str);
   $str = unescape_uri($esc);

   $comp = escape_uri_component($str);

   $esc = encode_entities($str);

# Two ways to get doc together. Pass through HTML::TokeParser first to
# correct for nothing but HTML and escape the rest.

# Two ways to handle the overview: destructive or exception. Just try
# to do it and ignore errors which might mean erasing content, or
# throw them.
# translate div p
# replace //a@href... || a[href^=...] 'content' || call back

HTML TO XHTML will have to strip deprecated shite like center and font.


12212g

VALID_ONLY FLAG?

DEBUG:

   5 EVERYTHING
   4
   3
   2
   1

SANITIZE IS BREAKING THE XML DTD HEADERS AND CDATA

Mention HTML::Restrict

    Test::Harness

Things like wrap() should be quite easy to add...
