#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;
use Data::Dumper;
use HOP::Stream;

BEGIN { use_ok 'Text::Markover' or die }

my @markover = split /(\n)/, 'This is a *test*. It is __only__ a `test`.
If this had been an \*actual\* emergency, _well,
you_ would `know` it!';

my $lexer = Text::Markover->lexer( sub { shift @markover } );
my @toks;
while ($lexer) {
    push @toks, HOP::Stream::head($lexer);
    $lexer = HOP::Stream::tail($lexer);
}

is_deeply \@toks, [
    [ STRING  => 'This is a *test*. It is __only__ a `test`.' ],
    [ NEWLINE => "\n" ],
    [ STRING  => 'If this had been an \*actual\* emergency, _well,' ],
    [ NEWLINE => "\n" ],
    [ STRING  => 'you_ would `know` it!' ],
], 'Simple lexer should generate correct tokens';

