#!/usr/bin/perl -w

use strict;
use warnings;
#use Test::More tests => 64;
use Test::More 'no_plan';
use Data::Dumper;
use HOP::Stream;

BEGIN { use_ok 'Text::Markover' or die }

sub get_toks {
    my @text = @_;
    my @toks;
    my $lexer = Text::Markover->lexer( sub { shift @text } );
    while (my $tok = $lexer->()) {
        push @toks, $tok;
    }
    return \@toks;

}

# Basic lexing.
for my $spec (
    # Simple tokens.
    [ 'Foo', [[ STRING => 'Foo' ]], 'one word' ],
    [ "\n",  [[ NEWLINE => "\n" ]], 'a newline' ],
    [ "\r\n",  [[ NEWLINE => "\n" ]], 'a Windows newline' ],
    [ "\r",  [[ NEWLINE => "\n" ]], 'a Mac newline' ],

    # Unix blank lines.
    [ "\n\n", [[ BLANK => "\n\n" ]], 'a blank line' ],
    [ "\n\n\n", [[ BLANK => "\n\n\n" ]], 'a double blank line' ],
    [ "\n  \n", [[ BLANK => "\n  \n" ]], 'a blank line with spaces' ],
    [ "\n  \n  \n", [[ BLANK => "\n  \n  \n" ]], 'a double blank line with spaces' ],
    [ "\n \t \n", [[ BLANK => "\n \t \n" ]], 'a blank line with tab' ],
    [ "\n \t \n \t \n", [[ BLANK => "\n \t \n \t \n" ]], 'a double blank line with tabs' ],
    [ "  \n\n", [[ BLANK => "  \n\n" ]], 'a blank line leading spaces' ],
    [ "  \n\n  \n", [[ BLANK => "  \n\n  \n" ]], 'a double blank line leading spaces' ],

    # Windows blank lines.
    [ "\r\n\r\n", [[ BLANK => "\n\n" ]], 'a Windows blank line' ],
    [ "\r\n\r\n\r", [[ BLANK => "\n\n\n" ]], 'a double Windows blank line' ],
    [ "\r\n  \r\n", [[ BLANK => "\n  \n" ]], 'a Windows blank line with spaces' ],
    [ "\r\n  \r\n  \r\n", [[ BLANK => "\n  \n  \n" ]], 'a double Windows blank line with spaces' ],
    [ "\r\n  \t\t \r\n", [[ BLANK => "\n  \t\t \n" ]], 'a Windows blank line with tabs' ],
    [ "\r\n  \t\t \r\n\r\n", [[ BLANK => "\n  \t\t \n\n" ]], 'a double Windows blank line with tabs' ],

    # Mac blank lines.
    [ "\r\r", [[ BLANK => "\n\n" ]], 'a Mac blank line' ],
    [ "\r\r\r", [[ BLANK => "\n\n\n" ]], 'a double Mac blank line' ],
    [ "\r  \r", [[ BLANK => "\n  \n" ]], 'a Mac blank line with spaces' ],
    [ "\r  \r  \r", [[ BLANK => "\n  \n  \n" ]], 'a double Mac blank line with spaces' ],
    [ "\r  \t\t \r", [[ BLANK => "\n  \t\t \n" ]], 'a Mac blank line with tabs' ],
    [ "\r  \t\t \r\r", [[ BLANK => "\n  \t\t \n\n" ]], 'a double Mac blank line with tabs' ],

    # Code spans.
    [ '`code`', [[ CODE => 'code' ]], 'a simple code span' ],
    [ '`this that`', [[ CODE => 'this that' ]], 'a code span with space' ],
    [ "`this\nthat`", [[ CODE => "this\nthat" ]], 'a code span with a newline' ],
    [ '``code``', [[ CODE => 'code' ]], 'a double backtick code span' ],
    [ '`` `code` ``', [[ CODE => '`code`' ]], 'a double backtick code span with backticks' ],
    [ '`` ` ``', [[ CODE => '`' ]], 'a double backtick code span with just an embedded backtick' ],
    [ '``(`)``', [[ CODE => '(`)' ]], 'a double backtick code span with embedded backtick' ],

    # Autolinks.
    [ '<http://example.com>', [[ AUTOLINK => URI::URL->new('http://example.com')]], 'an http URL' ],
    [ '<http://example.com/>', [[ AUTOLINK => URI::URL->new('http://example.com/')]], 'an http URL with slash' ],
    [ '<http://example.com/foo/bar>', [[ AUTOLINK => URI::URL->new('http://example.com/foo/bar')]], 'an http URL with path' ],
    [ '<http://example.com/?>', [[ AUTOLINK => URI::URL->new('http://example.com/?')]], 'an http URL with slash and ?' ],
    [ '<http://example.com?foo>', [[ AUTOLINK => URI::URL->new('http://example.com?foo')]], 'an http URL with query' ],
    [ '<mailto:foo@bar.com>', [[ AUTOLINK => URI::URL->new('mailto:foo@bar.com')]], 'a mailto URL' ],
    [ '<ftp://ftp.site.org>', [[ AUTOLINK => URI::URL->new('ftp://ftp.site.org')]], 'an FTP URL' ],
    [ '<gopher://moo.foo.com>', [[ AUTOLINK => URI::URL->new('gopher://moo.foo.com')]], 'a gopher URL' ],
    [ '<http://foo.com/?<this>&that>', [[ STRING => '<http://foo.com/?<this>&that>']], 'A URL with brackets should be a string' ],
    [
        '<http://www.deja.com/%5BST_rn=ps%5D/qs.xp?ST=PS&svcclass=dnyr&QRY=lwall>',
        [[ AUTOLINK => URI::URL->new('http://www.deja.com/%5BST_rn=ps%5D/qs.xp?ST=PS&svcclass=dnyr&QRY=lwall')]],
        'a long URL with path and query'
    ],

    # Automail.
    [ '<foo@bar.com>', [[ AUTOMAIL => 'foo@bar.com']], 'an email autolink' ],
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

