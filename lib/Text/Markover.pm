package Text::Markover;

use strict;
use warnings;
use HOP::Lexer ();
use lib '/Users/david/Downloads/HOP-Parser-0.01/lib';
use HOP::Parser ':all';
use HOP::Stream ();
use URI::URL ();
use Email::Valid;
#use Data::Dumper;

sub new {
    my $class = shift;
    bless {} => $class;
}

sub lexer {
    my ($self, $iter) = @_;
    HOP::Lexer::make_lexer(
        $iter,
        [ BLANK   => qr/(?:[ \t]*(?:\n|\r\n?+)){2,}/ms, sub {
              # Change all line endings to "\n";
              my ($l, $b) = @_;
              $b =~ s/\r\n?/\n/g;
              [ $l => $b ];
        } ],
        [ CODE    => qr/``.*?``|`[^`]*`/ms, sub {
              # Strip out the code characters.
              my ($l, $c) = @_;
              $c =~ s/^`(?:`[ ]?)?//;
              $c =~ s/(?:[ ]?`)?`?$//;
              [ $l => $c ];
        } ],
        [ NEWLINE  => qr/\n|\r\n?/ms, sub { [ shift, "\n" ] } ],
        [ ESCAPE   => qr/\\[-+.!#()\[\]{}_*`\\]/, sub { [ shift, substr shift, 1 ] } ],
        [ AUTOMAIL => qr/<$Email::Valid::RFC822PAT>/, sub {
              my $l = shift;
              my $email = substr shift, 1, -1;
              return Email::Valid->address( -address => $email)
                  ? [ $l => $email ]
                  : "<$email>";
          } ],
        [ AUTOLINK => qr/<$URI::scheme_re:[$URI::uric][$URI::uric#]*>/, sub {
              my ($l, $url) = @_;
              my $u = eval { URI::URL->new($url) };
              return $@ && !defined $u ? $url : [ $l => $u ];
        } ],
        [ EMOP => qr/[_]{1,2}|[*]{1,2}/ ],
        [ STRING  => qr/.+/ms ], # anything else.
    );
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

sub lookahead {
    my $p = ref $_[0] eq 'CODE' ? shift : lookfor @_;
    parser {
        my $input = shift or return;
        my @ret = eval { $p->($input) };
        return @ret ? (undef, $input) : ();
    },
}

# sub neg_lookahead {
#     my $p = ref $_[0] eq 'CODE' ? shift : lookfor @_;
#     parser {
#         my $input = shift or return;
#         my @ret = eval { $p->($input) };
#         return @ret ? () : (undef, $input);
#     },
# }

my $newline = match 'NEWLINE';
my $blank   = match 'BLANK';
my $joiner  = sub { join '', @_ };

# string ::= ( STRING | ESCAPE )+
my $string  = T(
    plus(
        alternate(
            match('STRING'),
            match('ESCAPE'),
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
my $eob_ahead = error(lookahead($eob));

sub entitize($) {
    local $_ = shift;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    $_;
}

my @encode = (
    sub { '&#' .                 ord(shift)   . ';' },
    sub { '&#x' . sprintf( '%X', ord(shift) ) . ';' },
    sub {                            shift          },
);

sub obscure($) {
    my $addr = shift;
    srand;

    $addr =~ s{(.)}{
        my $char = $1;
        if ( $char eq '@' ) {
            # this *must* be encoded. I insist.
            $encode[int rand 1]->($char);
        } else {
            my $r = rand;
            # roughly 10% raw, 45% hex, 45% dec
              $r > .9   ?  $encode[2]->($char)
            : $r < .45  ?  $encode[1]->($char)
            :              $encode[0]->($char);
        }
    }gex;

    return $addr;
}

my $spans;
my $Spans = parser { $spans->(@_) };

# code ::= CODE
my $code = lookfor( CODE => sub { '<code>' . entitize(shift->[1]) . '</code>' } );

# autolink ::= AUTOLINK
my $autolink = lookfor( AUTOLINK => sub {
    my $uri = shift->[1];
    my ($scheme, $url) = $uri->scheme eq 'mailto'
        ? ( obscure('mailto') . ':', obscure $uri  )
        : ( '',                      entitize $uri );
    return qq{<a href="$scheme$url">$url</a>}
} );

# automail ::= AUTOMAIL
my $automail = lookfor( AUTOMAIL => sub {
    my $scheme = obscure 'mailto';
    my $email  = obscure shift->[1];
    return qq{<a href="$scheme:$email">$email</a>}
} );

my $sstar   = absorb match EMOP => '*';
my $suscore = absorb match EMOP => '_';
my $not_em;
my $Not_em = parser { $not_em->(@_) };

# emphasis ::= sstar not_em (sstar | lookahead(eob))
#            | suscore not_em (suscore | lookahead(eob))
my $emphasis = T(
    alternate(
        concatenate( $sstar,   $Not_em, alternate($sstar,   $eob_ahead) ),
        concatenate( $suscore, $Not_em, alternate($suscore, $eob_ahead) ),
    ),
    sub { "<em>$_[0]</em>" }
);

my $dstar   = absorb match EMOP => '**';
my $duscore = absorb match EMOP => '__';
my $not_strong;
my $Not_strong = parser { $not_strong->(@_) };

# strong ::= dstar not_strong (dstar | lookahead(eob))
#          | duscore not_strong (duscore | lookahead(eob))
my $strong = T(
    alternate(
        concatenate( $dstar,   $Not_strong, alternate($dstar,   $eob_ahead) ),
        concatenate( $duscore, $Not_strong, alternate($duscore, $eob_ahead) ),
    ),
    sub { "<strong>$_[0]</strong>" }
);

# spans ::= (text | code | autolink | automail | emphasis | strong)+
my @spans   = ($text, $code, $autolink, $automail, $strong, $emphasis);
$spans      = T(plus( T( alternate( @spans ), $joiner, ) ), $joiner);

# not_em ::= (text | code | autolink | automail | strong)+
$not_em     = T(plus( T( alternate( grep { $_ ne $emphasis } @spans ), $joiner, ) ), $joiner);

# not_strong ::= (text | code | autolink | automail | strong)+
$not_strong = T(plus( T( alternate( grep { $_ ne $strong } @spans ), $joiner, ) ), $joiner);

# para ::= spans eob
my $para = T(
    concatenate(
        $Spans,
        $eob,
    ),
    sub { '<p>' . $_[0] . '</p>' . $_[1] }
);

# doc ::= para*
my $doc = T(
    star($para),
    $joiner,
);

sub parse {
    my ($self, $lexer) = @_;
    my ( $output, $remainder ) = $doc->(HOP::Stream::iterator_to_stream( $lexer ));
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
