package Text::Markover;

use strict;
use warnings;
use HOP::Lexer ();
use HOP::Parser ':all';
use HOP::Stream ();
use Data::Dumper;

sub new {
    my $class = shift;
    bless {} => $class;
}

sub lexer {
    my ($self, $iter) = @_;
    HOP::Stream::iterator_to_stream( HOP::Lexer::make_lexer(
        $iter,
        [ BLANK   => qr/\s*\n\s*?\n\s*/ms, ],
        [ NEWLINE => qr/\n/ms ],
        [ ESCAPE  => qr/\\[-+.!#()\[\]{}_*`\\]/ ],
        [ STRING  => qr/.+/ms ], # anything else.
    ))
}

# Matches one or more times.
sub plus {
    my $p = shift;
    T(
        concatenate( $p, star($p) ),
        sub {
            my ( $first, $rest ) = @_;
            [ $first, @$rest ];
        }
    );
}

# Matches zero or one time.
sub qmark {
    my $p = shift;
    T(
        alternate($p, \&nothing),
        sub {
            my ( $first, $rest ) = @_;
            [ $first, @$rest ];
        }
    );
}

my $newline = lookfor('NEWLINE');
my $blank   = lookfor('BLANK');
my $joiner  = sub { join '', @_ };

# string ::= ( STRING | ESCAPE)+
my $string  = T(
    plus(
        alternate(
            lookfor('STRING'),
            lookfor(ESCAPE => sub {  substr shift->[1], 1; })
        ),
    ),
    $joiner,
);

# text ::= string (NEWLINE text)*
my $text;
my $Text = parser { $text->(@_) };
$text = T(
    concatenate(
        $string,
        T(
            star(
                T(
                    concatenate($newline, $string),
                    $joiner
                )
            ),
            $joiner
        )
    ),
    $joiner
);

# eof  ::= NEWLINE* 'End_of_Input'
my $eof = T(
    concatenate(
        star($newline),
        \&End_of_Input,
    ),
    sub { shift->[0] || '' }
);

# eob  ::= BLANK | eof
my $eob = alternate( $blank, $eof );

# para ::= text eob
my $para = T(
    concatenate(
        $text,
        $eob,
    ),
    sub { '<p>' . $_[0] . '</p>' . $_[1] }
);

# doc ::= para*
my $doc = T(
    star($para),
    sub { join '', @_ },
);

sub parse {
    my ($self, $stream) = @_;
    my ( $output, $remainder ) = $doc->($stream);
    return $output;
}

sub markover {
    my $self = shift;
    my $text = \@_;
    my $lexer = $self->lexer( sub { shift @{ $text } });
    $self->parse($lexer);
}

1;

=pod

document   ::= blocks 'End_Of_Input'
blocks     ::= block | block blank blocks
block      ::= para | codeblock | header | blockquote | list | horizrule
             | reference | html

para       ::= span | span spans
span       ::= strong | em | code | link | image | autolink | html | text

strongop   ::= '**' | '__'
strong     ::= /strongop(?!\s|$) spans (?!\s|^)strongop

=cut
