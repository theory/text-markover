#!/usr/bin/perl -w

use strict;
use warnings;
#use Test::More tests => 11;
use Test::More 'no_plan';

BEGIN { use_ok 'Text::Markover' or die; }

ok my $m = Text::Markover->new, 'Contruct Markover object';

for my $spec (
    # Paragraphs.
    [ "Foo\n\nBar"    => "<p>Foo</p>\n\n<p>Bar</p>", ' with paras' ],
    [ "Foo\n\nBar\n"  => "<p>Foo</p>\n\n<p>Bar</p>\n", 'with trailing newline' ],
    [ "Foo\nBar\n"    => "<p>Foo\nBar</p>\n", 'with inline newline' ],

    # Escapes.
    [ "\\*Foo\\* Bar" => "<p>*Foo* Bar</p>", ' with escapes' ],

    # Code.
    [ 'This is `code`' => '<p>This is <code>code</code></p>', 'with code' ],

    # URLs.
    [ '<http://foo.com>' => '<p><a href="http://foo.com/">http://foo.com/</a></p>', 'with autolink' ],
    [ '<http://foo.com?q=4&a=b>' => '<p><a href="http://foo.com?q=4&amp;a=b">http://foo.com?q=4&amp;a=b</a></p>', 'with autolink with entities' ],

    # Emphasis.
    [ '*this*' => '<p><em>this</em></p>', 'with simple * emphasis' ],
    [ '_this_' => '<p><em>this</em></p>', 'with simple _ emphasis' ],
    [ '*this\*that*' => '<p><em>this*that</em></p>', 'with simple * emphasis and escape' ],
    [ '_this\_that_' => '<p><em>this_that</em></p>', 'with simple _ emphasis and escape' ],
    [ "*this"        => "<p><em>this</em></p>", 'with simple * emphasis and eof' ],
    [ "*this\n\n"    => "<p><em>this</em></p>\n\n", 'with simple * emphasis and eob' ],
    [ "*this\n\nfoo" => "<p><em>this</em></p>\n\n<p>foo</p>", 'with simple * emphasis and eob + para' ],
    [ 'un*frigging*believable' => '<p>un<em>frigging</em>believable</p>', 'with mid-word emphasis' ],

    # Strong.
    [ '**this**' => '<p><strong>this</strong></p>', 'with simple ** strong' ],
    [ '__this__' => '<p><strong>this</strong></p>', 'with simple __ strong' ],
    [ '**this\*\*that**' => '<p><strong>this**that</strong></p>', 'with simple ** strong and escape' ],
    [ '__this\_\_that__' => '<p><strong>this__that</strong></p>', 'with simple __ strong and escape' ],
    [ "**this"        => "<p><strong>this</strong></p>", 'with simple ** strong and eof' ],
    [ "**this\n\n"    => "<p><strong>this</strong></p>\n\n", 'with simple ** strong and eob' ],
    [ "**this\n\nfoo" => "<p><strong>this</strong></p>\n\n<p>foo</p>", 'with simple ** strong and eob + para' ],
) {
    local $ENV{FOO} = 1 if $spec->[0] eq 'un*frigging*believable';
    is $m->markover( $spec->[0] ), $spec->[1], "Markdown $spec->[2] should work";
}

# Test email autolinking.
like $m->markover( '<mailto:address@example.com>'),
    qr{^<p><a[ ]href="[^:]+:([^"]+)">\1</a></p>$},
    'A mailto autolink link should work';
like $m->markover( '<address@example.com>'),
    qr{^<p><a[ ]href="[^:]+:([^"]+)">\1</a></p>$},
    'An automail should work';

sub get_toks {
    my @text = @_;
    my @toks;
    my $lexer = Text::Markover->lexer( sub { shift @text } );
    while (my $tok = $lexer->()) {
        push @toks, $tok;
    }
    return \@toks;

}
