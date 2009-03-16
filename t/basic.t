#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok 'Text::Markover' or die; }

ok my $m = Text::Markover->new, 'Contruct Markover object';

for my $spec (
    [ "Foo\n\nBar" => "<p>Foo</p>\n\n<p>Bar</p>", ' with paras' ],
    [ "Foo\n\nBar\n" => "<p>Foo</p>\n\n<p>Bar</p>\n", 'with trailing newline' ],
    [ "Foo\nBar\n" => "<p>Foo\nBar</p>\n", 'with inline newline' ],
) {
    is $m->markover( $spec->[0] ), $spec->[1], "Markdown $spec->[2] should work";
}
