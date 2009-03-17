#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 39;
#use Test::More 'no_plan';
use Data::Dumper;
use HOP::Stream;

BEGIN { use_ok 'Text::Markover' or die }

sub get_toks {
    my @text = @_;
    my @toks;
    my $lexer = Text::Markover->lexer( sub { shift @text } );
    while ($lexer) {
        push @toks, HOP::Stream::head($lexer);
        $lexer = HOP::Stream::tail($lexer);
    }
    return \@toks;

}

# Basic lexing.
for my $spec (
    [ 'Foo', [[ STRING => 'Foo' ]], 'one word' ],
    [ "\n",  [[ NEWLINE => "\n" ]], 'a newline' ],
    [ "\n\n", [[ BLANK => "\n\n" ]], 'a blank line' ],
    [ "\n  \n", [[ BLANK => "\n  \n" ]], 'a blank line with spaces' ],
    [ "\n \t \n", [[ BLANK => "\n \t \n" ]], 'a blank line with tab' ],
    [ "  \n\n", [[ BLANK => "  \n\n" ]], 'a blank line leading spaces' ],
    [ "\n\n  ", [[ BLANK => "\n\n  " ]], 'a blank line trailing spaces' ],
    [ "  \n\n  ", [[ BLANK => "  \n\n  " ]], 'a blank line leading and trailing spaces' ],
    [ "\t  \n\n  \t", [[ BLANK => "\t  \n\n  \t" ]], 'a blank line leading and trailing tabs' ],
    [ '`code`', [[ CODE => 'code' ]], 'a simple code span' ],
    [ '`this that`', [[ CODE => 'this that' ]], 'a code span with space' ],
    [ "`this\nthat`", [[ CODE => "this\nthat" ]], 'a code span with a newline' ],
    [ '``code``', [[ CODE => 'code' ]], 'a double backtick code span' ],
    [ '`` `code` ``', [[ CODE => '`code`' ]], 'a double backtick code span with backticks' ],
    [ '`` ` ``', [[ CODE => '`' ]], 'a double backtick code span with just an embedded backtick' ],
    [ '``(`)``', [[ CODE => '(`)' ]], 'a double backtick code span with embedded backtick' ],
) {
    my $toks = get_toks $spec->[0];
    is_deeply $toks, $spec->[1], "Lexing $spec->[2] should work"
        or diag Dumper $toks;
}

# Test all escape characters.
for my $char ('-', '+', '.', '!', '#', '(', ')', '[', ']', '{', '}', '_', '*', '`', '\\') {
    my $toks = get_toks "\\$char";
    is_deeply $toks, [[ ESCAPE => $char ]], "\\$char should lex as an escape"
        or diag Dumper $toks;
}

# Combine some things.
for my $spec (
    [ "Foo\n\nBar" => [
        [ STRING => 'Foo' ],
        [ BLANK  => "\n\n" ],
        [ STRING => 'Bar']
    ], 'two paras' ],
    [ "Foo\n \t \nBar" => [
        [ STRING => 'Foo' ],
        [ BLANK  => "\n \t \n" ],
        [ STRING => 'Bar']
    ], 'two paras with tab in the blank' ],
    [ 'This is a `test`.' => [
        [ STRING => 'This is a ' ],
        [ CODE   => 'test' ],
        [ STRING => '.' ],
    ], 'a string and code' ],
    [ "This is a `test`.\n" => [
        [ STRING => 'This is a ' ],
        [ CODE   => 'test' ],
        [ STRING => '.' ],
        [ NEWLINE => "\n" ],
    ], 'a string and code and newline' ],
    [ "This is a `test\n`." => [
        [ STRING => 'This is a ' ],
        [ CODE   => "test\n" ],
        [ STRING => '.' ],
    ], 'a string and code with newline' ],
    [ '`two bits` of `code`' => [
        [ CODE   => 'two bits' ],
        [ STRING => ' of ' ],
        [ CODE   => 'code' ],
    ], 'two bits of code']
) {
    my $toks = get_toks $spec->[0];
    is_deeply $toks, $spec->[1], "Lexing $spec->[2] should work"
        or diag Dumper $toks;
}

# A more complicated lex.
my @markover = split /(\n)/, 'This is a *test*. It is __only__ a `test`.
If this had been an \\*actual\\* emergency, _well,
you_ would `know` it!';

is_deeply get_toks(@markover), [
    [ STRING  => 'This is a *test*. It is __only__ a ' ],
    [ CODE    => 'test' ],
    [ STRING  => '.' ],
    [ NEWLINE => "\n" ],
    [ STRING  => 'If this had been an ' ],
    [ ESCAPE  => '*' ],
    [ STRING  => 'actual' ],
    [ ESCAPE  => '*' ],
    [ STRING  => ' emergency, _well,' ],
    [ NEWLINE => "\n" ],
    [ STRING  => 'you_ would '],
    [ CODE    => 'know' ],
    [ STRING  => ' it!' ],
], 'Simple lexer should generate correct tokens';

