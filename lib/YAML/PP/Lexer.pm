use strict;
use warnings;
package YAML::PP::Lexer;

our $VERSION = '0.000'; # VERSION

use constant TRACE => $ENV{YAML_PP_TRACE};
use constant DEBUG => $ENV{YAML_PP_DEBUG} || $ENV{YAML_PP_TRACE};

use YAML::PP::Grammar qw/ $GRAMMAR /;
use Carp qw/ croak /;

use constant NODE_TYPE => 0;
use constant NODE_OFFSET => 1;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        reader => $args{reader},
    }, $class;
    $self->init;
    return $self;
}

sub init {
    my ($self) = @_;
    $self->{next_tokens} = [];
    $self->{next_line} = undef;
    $self->{line} = 1;
}

sub next_line { return $_[0]->{next_line} }
sub set_next_line { $_[0]->{next_line} = $_[1] }
sub reader { return $_[0]->{reader} }
sub set_reader { $_[0]->{reader} = $_[1] }
sub next_tokens { return $_[0]->{next_tokens} }
sub line { return $_[0]->{line} }
sub set_line { $_[0]->{line} = $_[1] }
sub inc_line { return $_[0]->{line}++ }

my $RE_WS = '[\t ]';
my $RE_LB = '[\r\n]';
my $RE_DOC_END = qr/\A(\.\.\.)(?=$RE_WS|$)/m;
my $RE_DOC_START = qr/\A(---)(?=$RE_WS|$)/m;
my $RE_EOL = qr/\A($RE_WS+#.*|$RE_WS+)?(?:$RE_LB|\z)/;
my $RE_COMMENT_EOL = qr/\A(#.*)?(?:$RE_LB|\z)/;

#ns-word-char    ::= ns-dec-digit | ns-ascii-letter | “-”
my $RE_NS_WORD_CHAR = '[0-9A-Za-z-]';
my $RE_URI_CHAR = '(?:' . '%[0-9a-fA-F]{2}' .'|'.  q{[0-9A-Za-z#;/?:@&=+$,_.!*'\(\)\[\]-]} . ')';
my $RE_NS_TAG_CHAR = '(?:' . '%[0-9a-fA-F]{2}' .'|'.  q{[0-9A-Za-z#;/?:@&=+$_.*'\(\)-]} . ')';

#  [#x21-#x7E]          /* 8 bit */
# | #x85 | [#xA0-#xD7FF] | [#xE000-#xFFFD] /* 16 bit */
# | [#x10000-#x10FFFF]                     /* 32 bit */

#nb-char ::= c-printable - b-char - c-byte-order-mark
#my $RE_NB_CHAR = '[\x21-\x7E]';
my $RE_ANCHOR_CAR = '[\x21-\x2B\x2D-\x5A\x5C\x5E-\x7A\x7C\x7E]';

my $RE_PLAIN_START = '[\x21\x22\x24-\x39\x3B-\x7E\xA0-\xFF\x{100}-\x{10FFFF}]';
my $RE_PLAIN_END = '[\x21-\x39\x3B-\x7E\xA0-\xFF\x{100}-\x{10FFFF}]';
my $RE_PLAIN_FIRST = '[\x24\x28-\x29\x2B\x2E-\x39\x3B-\x3D\x41-\x5A\x5C\x5E-\x5F\x61-\x7A\x7E\x{100}-\x{10FFFF}]';
# c-indicators
#! 21
#" 22
## 23
#% 25
#& 26
#' 27
#* 2A
#, 2C FLOW
#- 2D XX
#: 3A XX
#> 3E
#? 3F XX
#@ 40
#[ 5B FLOW
#] 5D FLOW
#` 60
#{ 7B FLOW
#| 7C
#} 7D FLOW


my $RE_PLAIN_WORD = "(?::+$RE_PLAIN_END|$RE_PLAIN_START)(?::+$RE_PLAIN_END|$RE_PLAIN_END)*";
my $RE_PLAIN_FIRST_WORD = "(?:[:?-]+$RE_PLAIN_END|$RE_PLAIN_FIRST)(?::+$RE_PLAIN_END|$RE_PLAIN_END)*";
my $RE_PLAIN_WORDS = "(?:$RE_PLAIN_FIRST_WORD(?:$RE_WS+$RE_PLAIN_WORD)*)";
my $RE_PLAIN_WORDS2 = "(?:$RE_PLAIN_WORD(?:$RE_WS+$RE_PLAIN_WORD)*)";


#c-secondary-tag-handle  ::= “!” “!”
#c-named-tag-handle  ::= “!” ns-word-char+ “!”
#ns-tag-char ::= ns-uri-char - “!” - c-flow-indicator
#ns-global-tag-prefix    ::= ns-tag-char ns-uri-char*
#c-ns-local-tag-prefix   ::= “!” ns-uri-char*
my $RE_TAG = "!(?:$RE_NS_WORD_CHAR*!$RE_NS_TAG_CHAR+|$RE_NS_TAG_CHAR+|<$RE_URI_CHAR+>|)";

#c-ns-anchor-property    ::= “&” ns-anchor-name
#ns-char ::= nb-char - s-white
#ns-anchor-char  ::= ns-char - c-flow-indicator
#ns-anchor-name  ::= ns-anchor-char+
my $RE_ANCHOR = "$RE_ANCHOR_CAR+";

my $RE_SEQSTART = qr/\A(-)(?=$RE_WS|$)/m;
my $RE_COMPLEX = qr/(\?)(?=$RE_WS|$)/m;
my $RE_COMPLEXCOLON = qr/\A(:)(?=$RE_WS|$)/m;
my $RE_ALIAS = qr/(\*$RE_ANCHOR)/m;


my %REGEXES = (
    ANCHOR => qr{(&$RE_ANCHOR)},
    TAG => qr{($RE_TAG)},
    EOL => qr{($RE_EOL)},
    EMPTY => qr{($RE_COMMENT_EOL)},
    LB => qr{($RE_LB)},
    WS => qr{($RE_WS*)},
    'WS' => qr{($RE_WS+)},
    SCALAR => qr{($RE_PLAIN_WORDS)},
    ALIAS => qr{$RE_ALIAS},
    QUESTION => qr{$RE_COMPLEX},
    COLON => qr{(?m:(:)(?=$RE_WS|$))},
    DASH => qr{(?m:(-)(?=$RE_WS|$))},
    DOUBLEQUOTE => qr{(")},
    DOUBLEQUOTED => qr{((?:\\(?:.|$)|[^"\r\n\\])*)}m,
    SINGLEQUOTE => qr{(')},
    SINGLEQUOTED => qr{((?:''|[^'\r\n])*)},
    LITERAL => qr{(\|)},
    FOLDED => qr{(>)},
    FLOW_MAP_START => qr{(\{)},
    FLOW_SEQ_START => qr{(\[)},
);

sub parse_tokens {
    my ($self, $parser, %args) = @_;
    my $next_rule = $parser->rules;
    my $callback = $args{callback};
    my $tokens = $parser->tokens;
    my $new_type;

    TRACE and $parser->debug_rules($next_rule);
    TRACE and $parser->debug_yaml;
    DEBUG and $parser->debug_next_line;

    my $next_tokens = $self->next_tokens;
    RULE: while (1) {
        last unless $next_rule;

        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$next_tokens->[0]], ['next_token']);
        my $got = $next_tokens->[0]->{name};
        my $def = $next_rule->{ $got };
        if ($def) {
            push @$tokens, shift @$next_tokens;
        }
        elsif ($def = $next_rule->{ 'WS?' }) {
            if ($got eq 'WS') {
                push @$tokens, shift @$next_tokens;
            }
            $got = 'WS?';
        }
        else {
            $def = $next_rule->{DEFAULT};
            $got = 'DEFAULT';
        }

        unless ($def) {
            DEBUG and $parser->not("---not $next_tokens->[0]->{name}");
            $parser->set_rules(undef);
            return;
        }

        DEBUG and $parser->got("---got $got");
        if (my $sub = $def->{match}) {
            $callback->($parser, $sub);
        }
        if (my $new = $def->{new}) {
            $next_rule = $new;
            DEBUG and $parser->got("NEW: $$next_rule");
            if (exists $GRAMMAR->{ $$next_rule }) {
                $next_rule = $GRAMMAR->{ $$next_rule };
                next RULE;
            }
            else {
                $new_type = $$next_rule;
                undef $next_rule;
                last RULE;
            }
        }
        $next_rule = $def;
        next RULE;

    }
    $parser->set_rules($next_rule);
    TRACE and $parser->highlight_yaml;
    TRACE and $parser->debug_tokens;

    return $new_type;
}

sub parse_block_scalar {
    TRACE and warn "=== parse_block_scalar()\n";
    my ($self, $parser, %args) = @_;
    my $tokens = $parser->tokens;
    my $indent = $parser->offset->[-1] + 1;

    my $block_type = $args{type};
    my $exp_indent;
    my $chomp = '';
    my $next_tokens = $self->next_tokens;
    if ($next_tokens->[0]->{name} eq 'BLOCK_SCALAR_INDENT') {
        $exp_indent = $next_tokens->[0]->{value};
        push @$tokens, shift @$next_tokens;
        if ($next_tokens->[0]->{name} eq 'BLOCK_SCALAR_CHOMP') {
            $chomp = $next_tokens->[0]->{value};
            push @$tokens, shift @$next_tokens;
        }
    }
    elsif ($next_tokens->[0]->{name} eq 'BLOCK_SCALAR_CHOMP') {
        $chomp = $next_tokens->[0]->{value};
        push @$tokens, shift @$next_tokens;
        if ($next_tokens->[0]->{name} eq 'BLOCK_SCALAR_INDENT') {
            $exp_indent = $next_tokens->[0]->{value};
            push @$tokens, shift @$next_tokens;
        }
    }
    if ($next_tokens->[0]->{name} eq 'EOL') {
        push @$tokens, shift @$next_tokens;
    }
    else {
        $parser->exception("Invalid block scalar");
    }
    if (defined $exp_indent) {
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$exp_indent], ['exp_indent']);
    }
    my @lines;

    my $got_indent = 0;
    if ($exp_indent) {
        $indent = $exp_indent;
        $got_indent = 1;
    }
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$indent], ['indent']);
    my $indent_re = '[ ]' ."{$indent}";
    TRACE and local $Data::Dumper::Useqq = 1;
    my $type;
    my $yaml = $self->fetch_next_line;
    while (defined $yaml) {
        TRACE and warn __PACKAGE__.':'.__LINE__.": RE: $indent_re\n";
        TRACE and $parser->debug_yaml;
        my $column = 1;
        my $pre;
        my $space;
        my $length;
        last if $$yaml =~ $RE_DOC_START;
        last if $$yaml =~ $RE_DOC_END;
        if ($$yaml =~ s/\A($indent_re)($RE_WS*)//) {
            $pre = $1;
            $space = $2;
            push @$tokens, $self->new_token( INDENT => $pre, column => $column );
            $column += length $pre;
            push @$tokens, $self->new_token( WS => $space, column => $column );
            $length = length $space;
            $column += $length;
        }
        elsif ($$yaml =~ m/\A$RE_WS*#.*$RE_LB/) {
            last;
        }
        elsif ($$yaml =~ s/\A($RE_WS*)($RE_LB)//) {
            $pre = $1;
            push @$tokens, $self->new_token( WS => $pre, column => $column );
            $column += length $pre;
            push @$tokens, $self->new_token( LB => $2, column => $column );
            $column += length $2;
            $self->inc_line;
            $yaml = $self->fetch_next_line;
            $space = '';
            $type = 'EMPTY';
            push @lines, [$type => $pre, $space];
            next;
        }
        else {
            last;
        }
        if ($$yaml =~ s/\A($RE_LB)//) {
            push @$tokens, $self->new_token( LB => $1, column => $column );
            $self->inc_line;
            $yaml = $self->fetch_next_line;
            $type = 'EMPTY';
            if ($got_indent) {
                push @lines, [$type => $pre, $space];
            }
            else {
                push @lines, [$type => $pre . $space, ''];
            }
            next;
        }
        if ($length and not $got_indent) {
            $indent += $length;
            $indent_re = '[ ]' . "{$indent}";
            $pre = $space;
            $space = '';
            $got_indent = 1;
        }
        elsif (not $got_indent) {
            $got_indent = 1;
        }
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);

        if ($$yaml =~ s/\A(.*)($RE_LB|\z)//) {
            my $value = $1;
            push @$tokens, $self->new_token( BLOCK_SCALAR_CONTENT => $value, column => $column );
            $column += length $value;
            push @$tokens, $self->new_token( LB => $2, column => $column );
            $column += length $2;
            $self->inc_line;
            $yaml = $self->fetch_next_line;
            $type = length $space ? 'MORE' : 'CONTENT';
            push @lines, [ $type => $pre, $space . $value ];
        }

    }
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@lines], ['lines']);

    my $string = YAML::PP::Render::render_block_scalar(
        block_type => $block_type,
        chomp => $chomp,
        lines => \@lines,
    );

    return { eol => 1, value => $string, style => $block_type };
}

sub parse_plain_multi {
    TRACE and warn "=== parse_plain_multi()\n";
    my ($self, $parser) = @_;
    my $yaml = $self->fetch_next_line;
    my @multi;
    my $indent = $parser->offset->[ -1 ] + 1;
    my $tokens = $parser->tokens;

    my $indent_re = $RE_WS . '{' . $indent . '}';
    while (1) {
        last if not defined $$yaml;
        my $column = 1;

        unless ($$yaml =~ s/\A($indent_re)//) {
            last;
        }

        if ($indent == 0) {
            last if $$yaml =~ $RE_DOC_END;
            last if $$yaml =~ $RE_DOC_START;
        }
        push @$tokens, $self->new_token( INDENT => $1, column => $column );
        $column += length $1;
        if ($$yaml =~ s/\A($RE_WS+)//) {
            push @$tokens, $self->new_token( WS => $1, column => $column );
            $column += length $1;
        }
        if ($$yaml =~ s/\A(#.*)($RE_LB|\z)//) {
            push @$tokens, $self->new_token( COMMENT => $1, column => $column );
            $column += length $1;
            push @$tokens, $self->new_token( LB => $2, column => $column );
            $self->inc_line;
            last;
        }

        if ($$yaml =~ s/\A($RE_LB|\z)//) {
            push @$tokens, $self->new_token( LB => $1, column => $column );
            $self->inc_line;
            $yaml = $self->fetch_next_line;
            push @multi, '';
        }
        elsif ($$yaml =~ s/\A($RE_PLAIN_WORDS2)//) {
            my $string = $1;
            push @$tokens, $self->new_token( PLAIN => $string, column => $column );
            $column += length $string;
            if ($$yaml =~ s/\A($RE_WS+)//) {
                push @$tokens, $self->new_token( WS => $1, column => $column );
                $column += length $1;
            }
            push @multi, $string;
            if ($$yaml =~ s/\A(#.*)($RE_LB|\z)//) {
                push @$tokens, $self->new_token( COMMENT => $1, column => $column );
                $column += length $1;
                push @$tokens, $self->new_token( LB => $2, column => $column );
                $self->inc_line;
                $yaml = $self->fetch_next_line;
                last;
            }
            unless ($$yaml =~ s/\A($RE_LB|\z)//) {
                $parser->exception("Unexpected content");
            }
            push @$tokens, $self->new_token( LB => $1, column => $column );
            $self->inc_line;
            $yaml = $self->fetch_next_line;
        }
        else {
            TRACE and $parser->debug_yaml;
            $parser->exception("Unexpected content");
        }
    }
    return {
        eol => 1,
        style => ':',
        value => \@multi,
    };
}


sub fetch_next_line {
    my ($self) = @_;
    my $next_line = $self->next_line;
    if (not defined $next_line or (length $$next_line) == 0) {
        my $line = $self->reader->readline;
        unless (defined $line) {
            return;
        }
        $next_line = \$line;
        $self->set_next_line(\$line);
    }
    return $next_line;
}

sub fetch_next_tokens {
    my ($self, $offset) = @_;
    my $next = $self->next_tokens;
    unless (@$next) {
        my $next_line = $self->fetch_next_line;
        unless (defined $next_line) {
            return $next;
        }
        $self->_fetch_next_tokens($offset, $next_line);
    }
    return $next;
}

my %TOKEN_NAMES = (
    '"' => 'DOUBLEQUOTE',
    "'" => 'SINGLEQUOTE',
    '|' => 'LITERAL',
    '>' => 'FOLDED',
    '!' => 'TAG',
    '*' => 'ALIAS',
    '&' => 'ANCHOR',
);
sub _fetch_next_tokens {
    my ($self, $offset, $yaml) = @_;
    my $next = $self->next_tokens;

    if (not length $$yaml) {
        return;
    }
    # $ESCAPE_CHAR from YAML.pm
    if ($$yaml =~ tr/\x00-\x08\x0b-\x0c\x0e-\x1f//) {
        $self->exception("Control characters are not allowed");
    }
    my $first = substr($$yaml, 0, 1);

    if ($offset == 0) {
        if ($first eq "%") {
            if ($$yaml =~ s/\A(\s*%YAML ?1\.2$RE_WS*)//) {
                $self->push_token( YAML_DIRECTIVE => $1 );
            }
            elsif ($$yaml =~ s/\A(\s*%TAG +(!$RE_NS_WORD_CHAR*!|!) +(tag:\S+|!$RE_URI_CHAR+)$RE_WS*)//) {
                $self->push_token( TAG_DIRECTIVE => $1 );
                # TODO
                my $tag_alias = $2;
                my $tag_url = $3;
            }
            elsif ($$yaml =~ s/\A(\s*\A%(?:\w+).*)//) {
                $self->push_token( RESERVED_DIRECTIVE => $1 );
                warn "Found reserved directive '$1'";
            }
            else {
                $self->exception("Invalid directive");
            }
            if ($$yaml =~ s/\A([\r\n]|\z)//) {
                $self->push_token( EMPTY => $1 );
            }
            else {
                $self->exception("Invalid directive");
            }
            return;
        }
        elsif ($first eq "#") {
            if ($$yaml =~ s/\A(#.*(?:[\r\n]|\z))//) {
                $self->push_token( EMPTY => $1 );
                return;
            }
        }
        elsif ($first eq ' ') {
            my $ws = '';
            if ($$yaml =~ s/\A( +)//) {
                $ws = $1;
            }
            if ($$yaml =~ s/\A(#.*(?:[\r\n]|\z))//) {
                $self->push_token( EMPTY => $ws . $1 );
                return;
            }
            if ($$yaml =~ s/\A([\r\n]|\z)//) {
                $self->push_token( EMPTY => $ws . $1 );
                return;
            }
            $self->push_token( INDENT => $ws );
        }
        elsif ($first eq '-') {
            if ($$yaml =~ s/$RE_DOC_START//) {
                $self->push_token( DOC_START => $1 );
                my $eol = $$yaml =~ s/\A($RE_EOL|\z)//;
                if ($eol) {
                    $self->push_token( EOL => $1 );
                    return;
                }
                else {
                    if ($$yaml =~ s/\A($RE_WS+)//) {
                        $self->push_token( WS => $1 );
                    }
                    else {
                        $self->exception("Unexpected content after ---");
                    }
                }
            }
        }
        elsif ($first eq '.') {
            if ($$yaml =~ s/$RE_DOC_END//) {
                $self->push_token( DOC_END => $1 );
                $$yaml =~ s/($RE_EOL|\z)// or croak "Unexpected";
                $self->push_token( EOL => $1 );
                return;
            }
        }
    }

    $first = substr($$yaml, 0, 1);
    while (length $$yaml) {
        my $plain = 0;
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$first], ['first']);

        if ($first eq '"' or $first eq "'") {
            my $token_name = $TOKEN_NAMES{ $first };
            my $token_name2 = $token_name . 'D';
            my $regex = $REGEXES{ $token_name2 };
            if ($$yaml =~ s/\A($first)$regex($first|[\r\n]|\z)//) {
                my $quote = $1;
                $self->push_token( $token_name => $1 );
                if ($3 eq $first) {
                    $self->push_token( $token_name2 . '_SINGLE' => $2 );
                    $self->push_token( $token_name => $3 );
                }
                else {
                    $self->push_token( $token_name2 . '_LINE' => $2 );
                    $self->push_token( LB => $3 );
                    $yaml = $self->fetch_next_line;
                    while (1) {
                        if ($$yaml =~ s/\A$regex($first|[\r\n])//) {
                            if ($2 eq $first) {
                                $self->push_token( $token_name2 . '_END' => $1 );
                                $self->push_token( $token_name => $2 );
                                last;
                            }
                            else {
                                $self->push_token( $token_name2 . '_LINE' => $1 );
                                $self->push_token( LB => $2 );
                                $yaml = $self->fetch_next_line;
                            }
                        }
                        else {
                            $self->exception("Invalid quoted string");
                        }
                    }
                }
            }
            else {
                $self->exception("Invalid quoted string");
            }
        }
        elsif ($first eq '-' or $first eq ':' or $first eq '?') {
            if ($$yaml =~ s/\A(\Q$first\E)(?:($RE_WS+)|([\r\n]|\z))//) {
                my $token_name = { '-' => 'DASH', ':' => 'COLON', '?' => 'QUESTION' }->{ $first };
                $self->push_token( $token_name => $1 );
                if (not defined $2) {
                    $self->push_token( EOL => $3 );
                    return;
                }
                my $ws = $2;
                if ($$yaml =~ s/\A(#.*|)([\r\n]|\z)//) {
                    $self->push_token( EOL => $ws . ($1 // '') . $2 );
                    return;
                }
                $self->push_token( WS => $ws );
            }
            else {
                $plain = 1;
            }
        }
        elsif ($first eq '|' or $first eq '>') {
            my $token_name = $TOKEN_NAMES{ $first };
            if ($$yaml =~ s/\A(\Q$first\E)//) {
                $self->push_token( $token_name => $1 );
                if ($$yaml =~ s/\A([1-9]\d*)([+-]?)//) {
                    $self->push_token( BLOCK_SCALAR_INDENT => $1 );
                    $self->push_token( BLOCK_SCALAR_CHOMP => $2 ) if $2;
                }
                elsif ($$yaml =~ s/\A([+-])([1-9]\d*)?//) {
                    $self->push_token( BLOCK_SCALAR_CHOMP => $1 );
                    $self->push_token( BLOCK_SCALAR_INDENT => $2 ) if $2;
                }
            }
        }
        elsif ($first eq '!') {
            my $token_name = $TOKEN_NAMES{ $first };
            if ($$yaml =~ s/\A($RE_TAG)//) {
                $self->push_token( $token_name => $1 );
            }
            else {
                $self->exception("Invalid tag");
            }
        }
        elsif ($first eq '&') {
            my $token_name = $TOKEN_NAMES{ $first };
            if ($$yaml =~ s/\A(\&$RE_ANCHOR)//) {
                $self->push_token( $token_name => $1 );
            }
            else {
                $self->exception("Invalid anchor");
            }
        }
        elsif ($first eq '*') {
            my $token_name = $TOKEN_NAMES{ $first };
            if ($$yaml =~ s/\A(\*$RE_ANCHOR)//) {
                $self->push_token( $token_name => $1 );
            }
            else {
                $self->exception("Invalid alias");
            }
        }
        elsif ($first eq ' ') {
            if ($$yaml =~ s/\A($RE_WS+)//) {
                my $ws = $1;
                if ($$yaml =~ s/\A((?:#.*)?(?:[\r\n]|\z))//) {
                    $self->push_token( EOL => $ws . $1 );
                    return;
                }
                $self->push_token( WS => $ws );
            }
        }
        elsif ($first eq "\n") {
            if ($$yaml =~ s/\A(\n)//) {
                $self->push_token( EOL => $1 );
                return;
            }
        }
        elsif ($first eq '{' or $first eq '[') {
            $self->exception("Not Implemented: Flow Style");
        }
        else {
            $plain = 1;
        }

        if ($plain) {
            if ($$yaml =~ s/\A($RE_PLAIN_WORDS)//) {
                $self->push_token( SCALAR => $1 );
                if ($$yaml =~ s/\A(?:($RE_WS+#.*)|($RE_WS*))([\r\n]|\z)//) {
                    if (defined $1) {
                        $self->push_token( COMMENT_EOL => $1 . $3 );
                        return;
                    }
                    $self->push_token( EOL => $2 . $3 );
                    return;
                }
            }
            else {
                $self->exception("Invalid plain scalar");
            }
        }

        $first = substr($$yaml, 0, 1);
    }
    push @$next, $self->new_token( EOL => '' );

    return;
}

my %is_new_line = (
    EOL => 1,
    COMMENT_EOL => 1,
    LB => 1,
    EMPTY => 1,
);

sub push_token {
    my ($self, $type, $value) = @_;
    my $next = $self->next_tokens;
    my $column = 1;
    if (@$next) {
        my $previous = $next->[-1];
        if ($is_new_line{ $previous->{name} }) {
            $column = 1;
        }
        else {
            $column = $previous->{column} + length( $previous->{value} );
        }
    }
    push @$next, {
        name => $type,
        value => $value,
        line => $self->line,
        column => $column,
    };
    if ($is_new_line{ $type }) {
        $self->inc_line;
    }
}

sub new_token {
    my ($self, $type, $value, %args) = @_;
    return { name => $type, value => $value, line => $self->line, %args };
}

sub exception {
    my ($self, $msg) = @_;
    my $next = $self->next_tokens;
    my $line = @$next ? $next->[0]->{line} : $self->line;
    my @caller = caller(0);
    my $e = YAML::PP::Exception->new(
        line => $line,
        msg => $msg,
        next => $next,
        where => $caller[1] . ' line ' . $caller[2],
        yaml => \'',
    );
    croak $e;
}

1;
