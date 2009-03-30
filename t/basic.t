#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 11;

BEGIN { use_ok 'Text::Markover' or die; }

ok my $m = Text::Markover->new, 'Contruct Markover object';

for my $spec (
    [ "Foo\n\nBar"    => "<p>Foo</p>\n\n<p>Bar</p>", ' with paras' ],
    [ "Foo\n\nBar\n"  => "<p>Foo</p>\n\n<p>Bar</p>\n", 'with trailing newline' ],
    [ "Foo\nBar\n"    => "<p>Foo\nBar</p>\n", 'with inline newline' ],
    [ "\\*Foo\\* Bar" => "<p>*Foo* Bar</p>", ' with escapes' ],
    [ 'This is `code`' => '<p>This is <code>code</code></p>', 'with code' ],
    [ '<http://foo.com>' => '<p><a href="http://foo.com/">http://foo.com/</a></p>', 'with autolink' ],
    [ '<http://foo.com?q=4&a=b>' => '<p><a href="http://foo.com?q=4&amp;a=b">http://foo.com?q=4&amp;a=b</a></p>', 'with autolink with entities' ],
) {
    is $m->markover( $spec->[0] ), $spec->[1], "Markdown $spec->[2] should work";
}

# Test email autolinking.
like $m->markover( '<mailto:address@example.com>'),
    qr{^<p><a[ ]href="[^:]+:([^"]+)">\1</a></p>$},
    'A mailto autolink link should work';
like $m->markover( '<address@example.com>'),
    qr{^<p><a[ ]href="[^:]+:([^"]+)">\1</a></p>$},
    'An automail should work';
