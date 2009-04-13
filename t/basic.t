#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 72;
#use Test::More 'no_plan';

BEGIN { use_ok 'Text::Markover' or die; }

ok my $m = Text::Markover->new, 'Contruct Markover object';

for my $spec (

    # Paragraphs.
    [ "Foo\n\nBar",   "<p>Foo</p>\n\n<p>Bar</p>",   'with paras' ],
    [ "Foo\n\nBar\n", "<p>Foo</p>\n\n<p>Bar</p>\n", 'with trailing newline' ],
    [ "Foo\nBar\n",   "<p>Foo\nBar</p>\n",          'with inline newline' ],

    # Escapes.
    [ "\\*Foo\\* Bar", "<p>*Foo* Bar</p>", ' with escapes' ],

    # Code.
    [ 'This is `code`', '<p>This is <code>code</code></p>', 'with code' ],

    # URLs.
    [
        '<http://foo.com>',
        '<p><a href="http://foo.com/">http://foo.com/</a></p>',
        'with autolink',
    ],
    [
        '<http://foo.com?q=4&a=b>',
        '<p><a href="http://foo.com?q=4&amp;a=b">http://foo.com?q=4&amp;a=b</a></p>',
        'with autolink with entities',
    ],

    # Emphasis.
    [ '*this*', '<p><em>this</em></p>', 'with simple * emphasis' ],
    [ '_this_', '<p><em>this</em></p>', 'with simple _ emphasis' ],
    [
        '*this\*that*',
        '<p><em>this*that</em></p>',
        'with simple * emphasis and escape',
    ],
    [
        '_this\_that_',
        '<p><em>this_that</em></p>',
        'with simple _ emphasis and escape',
    ],
    [ "*this", "<p>*this</p>", 'with lone * and eof' ],
    [
        "*this\n\n",
        "<p>*this</p>\n\n",
        'with lone * and eob',
    ],
    [
        "*this\n\nfoo",
        "<p>*this</p>\n\n<p>foo</p>",
        'with lone * and eob + para',
    ],
    [
        'un*frigging*believable',
        '<p>un<em>frigging</em>believable</p>',
        'with mid-word * emphasis',
    ],
    [
        'un_frigging_believable',
        '<p>un<em>frigging</em>believable</p>',
        'with mid-word _ emphasis',
    ],
    [
        '*this* and *that',
        '<p><em>this</em> and *that</p>',
        'two *, one hanging',
    ],
    [
        '_this_ and _that',
        '<p><em>this</em> and _that</p>',
        'two _, one hanging',
    ],

    # Strong.
    [ '**this**', '<p><strong>this</strong></p>', 'with simple ** strong' ],
    [ '__this__', '<p><strong>this</strong></p>', 'with simple __ strong' ],
    [
        '**this\*\*that**',
        '<p><strong>this**that</strong></p>',
        'with simple ** strong and escape',
    ],
    [
        '__this\_\_that__',
        '<p><strong>this__that</strong></p>',
        'with simple __ strong and escape',
    ],
    [
        "**this",
        "<p>**this</p>",
        'with lone ** and eof',
    ],
    [
        "**this\n\n",
        "<p>**this</p>\n\n",
        'with lone ** and eob',
    ],
    [
        "**this\n\nfoo",
        "<p>**this</p>\n\n<p>foo</p>",
        'with lone ** and eob + para',
    ],
    [
        'un**frigging**believable',
        '<p>un<strong>frigging</strong>believable</p>',
        'with mid-word ** strong',
    ],
    [
        'un__frigging__believable',
        '<p>un<strong>frigging</strong>believable</p>',
        'with mid-word __ strong',
    ],
    [
        '**this** and **that',
        '<p><strong>this</strong> and **that</p>',
        'two **, one hanging',
    ],
    [
        '__this__ and __that',
        '<p><strong>this</strong> and __that</p>',
        'two __, one hanging',
    ],

    # Strong and Emphasis.
    [
        '***this***',
        '<p><strong><em>this</em></strong></p>',
        'with strong ** and em *',
    ],
    [
        '___this___',
        '<p><strong><em>this</em></strong></p>',
        'with strong __ and em _',
    ],
    [
        '**_this_**',
        '<p><strong><em>this</em></strong></p>',
        'with strong ** and em _',
    ],
    [
        '__*this*__',
        '<p><strong><em>this</em></strong></p>',
        'with strong __ and em *',
    ],
    [
        '_**this**_',
        '<p><em><strong>this</strong></em></p>',
        'with em _ and strong **',
    ],
    [
        '*__this__*',
        '<p><em><strong>this</strong></em></p>',
        'with em * and strong __',
    ],
    [
        '**_this**_',
        '<p>**_this**_</p>',
        'with unbalanced  **_ **_',
    ],
    [
        '__*this__*',
        '<p>__*this__*</p>',
        'with unbalanced __* __*',
    ],
    [
        '_**this_**',
        '<p>_**this_**</p>',
        'with unbalanced _** _**',
    ],
    [
        '*__this*__',
        '<p>*__this*__</p>',
        'with unbalanced *__ *__',
    ],

    [
        'un*__frigging__*believable',
        '<p>un<em><strong>frigging</strong></em>believable</p>',
        'with mid-word *__ emphasis',
    ],
    [
        'un__*frigging*__believable',
        '<p>un<strong><em>frigging</em></strong>believable</p>',
        'with mid-word __* emphasis',
    ],
    [
        'un_**frigging**_believable',
        '<p>un<em><strong>frigging</strong></em>believable</p>',
        'with mid-word _** emphasis',
    ],
    [
        'un**_frigging_**believable',
        '<p>un<strong><em>frigging</em></strong>believable</p>',
        'with mid-word **_ emphasis',
    ],
    [
        'un***frigging***believable',
        '<p>un<strong><em>frigging</em></strong>believable</p>',
        'with mid-word *** emphasis',
    ],
    [
        'un___frigging___believable',
        '<p>un<strong><em>frigging</em></strong>believable</p>',
        'with mid-word ___ emphasis',
    ],
    [
        '*this **and** that*',
        '<p><em>this <strong>and</strong> that</em></p>',
        'mixed em * and srong **',
    ],
    [
        '*this __and__ that*',
        '<p><em>this <strong>and</strong> that</em></p>',
        'mixed em * and srong __',
    ],

    # Unbalanced emphasis.
    [ '*this *that!',   '<p>*this *that!</p>', '2 hangling left *s' ],
    [ '_this _that!',   '<p>_this _that!</p>', '2 hangling left _s' ],
    [ '**this **that!', '<p>**this **that!</p>', '2 hangling left **s' ],
    [ '__this __that!', '<p>__this __that!</p>', '2 hangling left __s' ],
    [ '_this*', '<p>_this*</p>', 'mismatched em chars' ],
    [ '__this**', '<p>__this**</p>', 'mismatched strong chars' ],
    [ '*this_', '<p>*this_</p>', 'mismatched em chars reversed' ],
    [ '__this**', '<p>__this**</p>', 'mismatched strong chars' ],
    [ '**this__', '<p>**this__</p>', 'mismatched strong chars reversed' ],
    [ '__*this_**', '<p>__*this_**</p>', 'mismatched both' ],
    [ '_**this__*', '<p>_**this__*</p>', 'mismatched both 2' ],
    [ '**_this*__', '<p>**_this*__</p>', 'mismatched both 3' ],
    [ '*__this**_', '<p>*__this**_</p>', 'mismatched both 4' ],
    [ '___this***', '<p>___this***</p>', 'mismatched both 5' ],
    [ '***this___', '<p>***this___</p>', 'mismatched both 6' ],

    # Hanging emphasis characters.
    [ '* not em *',       '<p>* not em *</p>',       'not em *' ],
    [ '** not strong **', '<p>** not strong **</p>', 'not strong **' ],
    [ '_ not em _',       '<p>_ not em _</p>',       'not em _' ],
    [ '__ not strong __', '<p>__ not strong __</p>', 'not strong __' ],
    [ '*__ not stem __*', '<p>*__ not stem __*</p>', 'not stem *__' ],
    [ '_** not stem **_', '<p>_** not stem **_</p>', 'not stem _**' ],
  )
{
    is $m->markover( $spec->[0] ), $spec->[1],
      "Markdown $spec->[2] should work";
}

# Test email autolinking.
like $m->markover('<mailto:address@example.com>'),
  qr{^<p><a[ ]href="[^:]+:([^"]+)">\1</a></p>$},
  'A mailto autolink link should work';
like $m->markover('<address@example.com>'),
  qr{^<p><a[ ]href="[^:]+:([^"]+)">\1</a></p>$},
  'An automail should work';

sub get_toks {
    my @text = @_;
    my @toks;
    my $lexer = Text::Markover->lexer( sub { shift @text } );
    while ( my $tok = $lexer->() ) {
        push @toks, $tok;
    }
    return \@toks;

}
