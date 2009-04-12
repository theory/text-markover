#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 103;

#use Test::More 'no_plan';
use Data::Dumper;
use HOP::Stream;

BEGIN { use_ok 'Text::Markover' or die }

sub get_toks {
    my @text = @_;
    my @toks;
    my $lexer = Text::Markover->lexer( sub { shift @text } );
    while ( my $tok = $lexer->() ) {
        push @toks, $tok;
    }
    return \@toks;

}

# Basic lexing.
for my $spec (

    # Simple tokens.
    [ 'Foo',  [ [ STRING  => 'Foo' ] ], 'one word' ],
    [ "\n",   [ [ NEWLINE => "\n" ] ],  'a newline' ],
    [ "\r\n", [ [ NEWLINE => "\n" ] ],  'a Windows newline' ],
    [ "\r",   [ [ NEWLINE => "\n" ] ],  'a Mac newline' ],

    # Unix blank lines.
    [ "\n\n",   [ [ BLANK => "\n\n" ] ],   'a blank line' ],
    [ "\n\n\n", [ [ BLANK => "\n\n\n" ] ], 'a double blank line' ],
    [ "\n  \n", [ [ BLANK => "\n  \n" ] ], 'a blank line with spaces' ],
    [
        "\n  \n  \n",
        [ [ BLANK => "\n  \n  \n" ] ],
        'a double blank line with spaces'
    ],
    [ "\n \t \n", [ [ BLANK => "\n \t \n" ] ], 'a blank line with tab' ],
    [
        "\n \t \n \t \n",
        [ [ BLANK => "\n \t \n \t \n" ] ],
        'a double blank line with tabs'
    ],
    [ "  \n\n", [ [ BLANK => "  \n\n" ] ], 'a blank line leading spaces' ],
    [
        "  \n\n  \n",
        [ [ BLANK => "  \n\n  \n" ] ],
        'a double blank line leading spaces'
    ],

    # Windows blank lines.
    [ "\r\n\r\n",   [ [ BLANK => "\n\n" ] ],   'a Windows blank line' ],
    [ "\r\n\r\n\r", [ [ BLANK => "\n\n\n" ] ], 'a double Windows blank line' ],
    [
        "\r\n  \r\n",
        [ [ BLANK => "\n  \n" ] ],
        'a Windows blank line with spaces'
    ],
    [
        "\r\n  \r\n  \r\n",
        [ [ BLANK => "\n  \n  \n" ] ],
        'a double Windows blank line with spaces'
    ],
    [
        "\r\n  \t\t \r\n",
        [ [ BLANK => "\n  \t\t \n" ] ],
        'a Windows blank line with tabs'
    ],
    [
        "\r\n  \t\t \r\n\r\n",
        [ [ BLANK => "\n  \t\t \n\n" ] ],
        'a double Windows blank line with tabs'
    ],

    # Mac blank lines.
    [ "\r\r",   [ [ BLANK => "\n\n" ] ],   'a Mac blank line' ],
    [ "\r\r\r", [ [ BLANK => "\n\n\n" ] ], 'a double Mac blank line' ],
    [ "\r  \r", [ [ BLANK => "\n  \n" ] ], 'a Mac blank line with spaces' ],
    [
        "\r  \r  \r",
        [ [ BLANK => "\n  \n  \n" ] ],
        'a double Mac blank line with spaces'
    ],
    [
        "\r  \t\t \r",
        [ [ BLANK => "\n  \t\t \n" ] ],
        'a Mac blank line with tabs'
    ],
    [
        "\r  \t\t \r\r",
        [ [ BLANK => "\n  \t\t \n\n" ] ],
        'a double Mac blank line with tabs'
    ],

    # Code spans.
    [ '`code`',      [ [ CODE => 'code' ] ],      'a simple code span' ],
    [ '`this that`', [ [ CODE => 'this that' ] ], 'a code span with space' ],
    [
        "`this\nthat`",
        [ [ CODE => "this\nthat" ] ],
        'a code span with a newline'
    ],
    [ '``code``', [ [ CODE => 'code' ] ], 'a double backtick code span' ],
    [
        '`` `code` ``',
        [ [ CODE => '`code`' ] ],
        'a double backtick code span with backticks'
    ],
    [
        '`` ` ``',
        [ [ CODE => '`' ] ],
        'a double backtick code span with just an embedded backtick'
    ],
    [
        '``(`)``',
        [ [ CODE => '(`)' ] ],
        'a double backtick code span with embedded backtick'
    ],

    # Autolinks.
    [
        '<http://example.com>',
        [ [ AUTOLINK => URI::URL->new('http://example.com') ] ],
        'an http URL'
    ],
    [
        '<http://example.com/>',
        [ [ AUTOLINK => URI::URL->new('http://example.com/') ] ],
        'an http URL with slash'
    ],
    [
        '<http://example.com/foo/bar>',
        [ [ AUTOLINK => URI::URL->new('http://example.com/foo/bar') ] ],
        'an http URL with path'
    ],
    [
        '<http://example.com/?>',
        [ [ AUTOLINK => URI::URL->new('http://example.com/?') ] ],
        'an http URL with slash and ?'
    ],
    [
        '<http://example.com?foo>',
        [ [ AUTOLINK => URI::URL->new('http://example.com?foo') ] ],
        'an http URL with query'
    ],
    [
        '<mailto:foo@bar.com>',
        [ [ AUTOLINK => URI::URL->new('mailto:foo@bar.com') ] ],
        'a mailto URL'
    ],
    [
        '<ftp://ftp.site.org>',
        [ [ AUTOLINK => URI::URL->new('ftp://ftp.site.org') ] ],
        'an FTP URL'
    ],
    [
        '<gopher://moo.foo.com>',
        [ [ AUTOLINK => URI::URL->new('gopher://moo.foo.com') ] ],
        'a gopher URL'
    ],
    [
        '<http://foo.com/?<this>&that>',
        [ [ STRING => '<http://foo.com/?<this>&that>' ] ],
        'A URL with brackets should be a string'
    ],
    [
'<http://www.deja.com/%5BST_rn=ps%5D/qs.xp?ST=PS&svcclass=dnyr&QRY=lwall>',
        [
            [
                AUTOLINK => URI::URL->new(
'http://www.deja.com/%5BST_rn=ps%5D/qs.xp?ST=PS&svcclass=dnyr&QRY=lwall'
                )
            ]
        ],
        'a long URL with path and query'
    ],

    # Automail.
    [ '<foo@bar.com>', [ [ AUTOMAIL => 'foo@bar.com' ] ], 'an email autolink' ],

    # Emphasis characters.
    [ '*', [ [ STRING => '*' ] ], 'a single *' ],
    [
        '*this*', [ [ EMLOP => '*' ], [ STRING => 'this' ], [ EMROP => '*' ] ],
        'a *word*'
    ],
    [ '**', [ [ STRING => '**' ] ], 'a double *' ],
    [
        '**this**',
        [ [ EMLOP => '**' ], [ STRING => 'this' ], [ EMROP => '**' ] ],
        'a **word**'
    ],
    [
        'un*frigging*believable' => [
            [ STRING => 'un' ],
            [ EMMOP  => '*' ],
            [ STRING => 'frigging' ],
            [ EMMOP  => '*' ],
            [ STRING => 'believable' ]
        ],
        'a mid*word*string'
    ],
    [
        'un**frigging**believable' => [
            [ STRING => 'un' ],
            [ EMMOP  => '**' ],
            [ STRING => 'frigging' ],
            [ EMMOP  => '**' ],
            [ STRING => 'believable' ]
        ],
        'a mid**word**string'
    ],

    [ '_', [ [ STRING => '_' ] ], 'a single _' ],
    [
        '_this_', [ [ EMLOP => '_' ], [ STRING => 'this' ], [ EMROP => '_' ] ],
        'a _word_'
    ],
    [ '__', [ [ STRING => '__' ] ], 'a double _' ],
    [
        '__this__',
        [ [ EMLOP => '__' ], [ STRING => 'this' ], [ EMROP => '__' ] ],
        'a __word__'
    ],
    [
        'un_frigging_believable' => [
            [ STRING => 'un' ],
            [ EMMOP  => '_' ],
            [ STRING => 'frigging' ],
            [ EMMOP  => '_' ],
            [ STRING => 'believable' ]
        ],
        'a mid_word_string'
    ],
    [
        'un__frigging__believable' => [
            [ STRING => 'un' ],
            [ EMMOP  => '__' ],
            [ STRING => 'frigging' ],
            [ EMMOP  => '__' ],
            [ STRING => 'believable' ]
        ],
        'a mid__word__string'
    ],

    [
        '*un*believable' => [
            [ EMLOP  => '*' ],
            [ STRING => 'un' ],
            [ EMMOP  => '*' ],
            [ STRING => 'believable' ]
        ],
        'a left and mid *'
    ],
    [
        'un*believable*' => [
            [ STRING => 'un' ],
            [ EMMOP  => '*' ],
            [ STRING => 'believable' ],
            [ EMROP  => '*' ]
        ],
        'a mid and right *'
    ],
    [
        '**un**believable' => [
            [ EMLOP  => '**' ],
            [ STRING => 'un' ],
            [ EMMOP  => '**' ],
            [ STRING => 'believable' ]
        ],
        'a left and mid **'
    ],
    [
        'un**believable**' => [
            [ STRING => 'un' ],
            [ EMMOP  => '**' ],
            [ STRING => 'believable' ],
            [ EMROP  => '**' ]
        ],
        'a mid and right **'
    ],
    [
        '_un_believable' => [
            [ EMLOP  => '_' ],
            [ STRING => 'un' ],
            [ EMMOP  => '_' ],
            [ STRING => 'believable' ]
        ],
        'a left and mid _'
    ],
    [
        'un_believable_' => [
            [ STRING => 'un' ],
            [ EMMOP  => '_' ],
            [ STRING => 'believable' ],
            [ EMROP  => '_' ]
        ],
        'a mid and right _'
    ],
    [
        '__un__believable' => [
            [ EMLOP  => '__' ],
            [ STRING => 'un' ],
            [ EMMOP  => '__' ],
            [ STRING => 'believable' ]
        ],
        'a left and mid __'
    ],
    [
        'un__believable__' => [
            [ STRING => 'un' ],
            [ EMMOP  => '__' ],
            [ STRING => 'believable' ],
            [ EMROP  => '__' ]
        ],
        'a mid and right __'
    ],

    # Combining emphasis characters.
    [ '*__',    [ [ STRING => '*__' ] ],    '*__' ],
    [ '__*',    [ [ STRING => '__*' ] ],    '__*' ],
    [ '*____*', [ [ STRING => '*____*' ] ], '*____*' ],
    [ '_**',    [ [ STRING => '_**' ] ],    '_**' ],
    [ '**_',    [ [ STRING => '**_' ] ],    '**_' ],
    [ '_****_', [ [ STRING => '_****_' ] ], '_****_' ],
    [
        '__*this*__',
        [
            [ EMLOP  => '__' ],
            [ EMLOP  => '*' ],
            [ STRING => 'this' ],
            [ EMROP  => '*' ],
            [ EMROP  => '__' ]
        ],
        'a __*word*__'
    ],
    [
        '*__this__*',
        [
            [ EMLOP  => '*' ],
            [ EMLOP  => '__' ],
            [ STRING => 'this' ],
            [ EMROP  => '__' ],
            [ EMROP  => '*' ]
        ],
        'a *__word__*'
    ],
    [
        '**_this_**',
        [
            [ EMLOP  => '**' ],
            [ EMLOP  => '_' ],
            [ STRING => 'this' ],
            [ EMROP  => '_' ],
            [ EMROP  => '**' ]
        ],
        'a **_word_**'
    ],
    [
        '_**this**_',
        [
            [ EMLOP  => '_' ],
            [ EMLOP  => '**' ],
            [ STRING => 'this' ],
            [ EMROP  => '**' ],
            [ EMROP  => '_' ]
        ],
        'a _**word**_'
    ],
    [
        '___this___',
        [
            [ EMLOP  => '__' ],
            [ EMLOP  => '_' ],
            [ STRING => 'this' ],
            [ EMROP  => '__' ],
            [ EMROP  => '_' ]
        ],
        'a ___word___'
    ],
    [
        '***this***',
        [
            [ EMLOP  => '**' ],
            [ EMLOP  => '*' ],
            [ STRING => 'this' ],
            [ EMROP  => '**' ],
            [ EMROP  => '*' ]
        ],
        'a ***word***'
    ],

    [
        'un*__frigging__*believable' => [
            [ STRING => 'un' ],
            [ EMMOP  => '*' ],
            [ EMMOP  => '__' ],
            [ STRING => 'frigging' ],
            [ EMMOP  => '__' ],
            [ EMMOP  => '*' ],
            [ STRING => 'believable' ]
        ],
        'a mid*__word__*string'
    ],
    [
        'un_**frigging**_believable' => [
            [ STRING => 'un' ],
            [ EMMOP  => '_' ],
            [ EMMOP  => '**' ],
            [ STRING => 'frigging' ],
            [ EMMOP  => '**' ],
            [ EMMOP  => '_' ],
            [ STRING => 'believable' ]
        ],
        'a mid_**word**_string'
    ],
    [
        '*__un__*believable' => [
            [ EMLOP  => '*' ],
            [ EMLOP  => '__' ],
            [ STRING => 'un' ],

            [ EMMOP  => '__' ],
            [ EMMOP  => '*' ],
            [ STRING => 'believable' ]
        ],
        'a mid_**word**_string'
    ],
    [
        '_**un**_believable' => [
            [ EMLOP  => '_' ],
            [ EMLOP  => '**' ],
            [ STRING => 'un' ],
            [ EMMOP  => '**' ],
            [ EMMOP  => '_' ],
            [ STRING => 'believable' ]
        ],
        'a mid*__word__*string'
    ],

    # Unbalanced combined emphasis operators.
    [
        '__*this__*',
        [
            [ EMLOP  => '__' ],
            [ EMLOP  => '*' ],
            [ STRING => 'this' ],
            [ EMROP  => '__' ],
            [ EMROP  => '*' ]
        ],
        'a __*word__*'
    ],
    [
        '**_this**_',
        [
            [ EMLOP  => '**' ],
            [ EMLOP  => '_' ],
            [ STRING => 'this' ],
            [ EMROP  => '**' ],
            [ EMROP  => '_' ]
        ],
        'a **_word**_'
    ],
  )
{
    my $toks = get_toks $spec->[0];
    is_deeply $toks, $spec->[1], "Lexing $spec->[2] should work"
      or diag Dumper $toks;
}

# Test all escape characters.
for my $char ( '-', '+', '.', '!', '#', '(', ')', '[', ']', '{', '}', '_', '*',
    '`', '\\' )
{
    my $toks = get_toks "\\$char";
    is_deeply $toks, [ [ ESCAPE => $char ] ], "\\$char should lex as an escape"
      or diag Dumper $toks;
}

# Combine some things.
for my $spec (
    [
        "Foo\n\nBar" =>
          [ [ STRING => 'Foo' ], [ BLANK => "\n\n" ], [ STRING => 'Bar' ] ],
        'two paras'
    ],
    [
        "Foo\n \t \nBar" =>
          [ [ STRING => 'Foo' ], [ BLANK => "\n \t \n" ], [ STRING => 'Bar' ] ],
        'two paras with tab in the blank'
    ],
    [
        'This is a `test`.' => [
            [ STRING => 'This is a ' ], [ CODE => 'test' ], [ STRING => '.' ],
        ],
        'a string and code'
    ],
    [
        "This is a `test`.\n" => [
            [ STRING  => 'This is a ' ],
            [ CODE    => 'test' ],
            [ STRING  => '.' ],
            [ NEWLINE => "\n" ],
        ],
        'a string and code and newline'
    ],
    [
        "This is a `test\n`." => [
            [ STRING => 'This is a ' ],
            [ CODE   => "test\n" ],
            [ STRING => '.' ],
        ],
        'a string and code with newline'
    ],
    [
        '`two bits` of `code`' =>
          [ [ CODE => 'two bits' ], [ STRING => ' of ' ], [ CODE => 'code' ], ],
        'two bits of code'
    ]
  )
{
    my $toks = get_toks $spec->[0];
    is_deeply $toks, $spec->[1], "Lexing $spec->[2] should work"
      or diag Dumper $toks;
}

# A more complicated lex.
my @markover = split /(\n)/, 'This is a *test*. It is __only__ a `test`.
If this had been an \\*actual\\* emergency, _well,
you_ would `know` it!';

is_deeply get_toks(@markover),
  [
    [ STRING  => 'This is a ' ],
    [ EMLOP   => '*' ],
    [ STRING  => 'test' ],
    [ EMMOP   => '*' ],
    [ STRING  => '. It is ' ],
    [ EMLOP   => '__' ],
    [ STRING  => 'only' ],
    [ EMROP   => '__' ],
    [ STRING  => ' a ' ],
    [ CODE    => 'test' ],
    [ STRING  => '.' ],
    [ NEWLINE => "\n" ],
    [ STRING  => 'If this had been an ' ],
    [ ESCAPE  => '*' ],
    [ STRING  => 'actual' ],
    [ ESCAPE  => '*' ],
    [ STRING  => ' emergency, ' ],
    [ EMLOP   => '_' ],
    [ STRING  => 'well,' ],
    [ NEWLINE => "\n" ],
    [ STRING  => 'you' ],
    [ EMROP   => '_' ],
    [ STRING  => ' would ' ],
    [ CODE    => 'know' ],
    [ STRING  => ' it!' ],
  ],
  'Simple lexer should generate correct tokens';

