use strict;
use warnings;
package YAML::PP::Lexer;

our $VERSION = '0.000'; # VERSION

use constant TRACE => $ENV{YAML_PP_TRACE};
use constant DEBUG => $ENV{YAML_PP_DEBUG} || $ENV{YAML_PP_TRACE};

use YAML::PP::Grammar qw/ $GRAMMAR /;
use Carp qw/ croak /;

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
    $self->{next_line} = [];
    $self->{line} = 0;
    $self->{context} = 'normal';
}

sub next_line { return $_[0]->{next_line} }
sub set_next_line { $_[0]->{next_line} = $_[1] }
sub reader { return $_[0]->{reader} }
sub set_reader { $_[0]->{reader} = $_[1] }
sub next_tokens { return $_[0]->{next_tokens} }
sub line { return $_[0]->{line} }
sub set_line { $_[0]->{line} = $_[1] }
sub inc_line { return $_[0]->{line}++ }
sub context { return $_[0]->{context} }
sub set_context { $_[0]->{context} = $_[1] }

my $RE_WS = '[\t ]';
my $RE_LB = '[\r\n]';
my $RE_DOC_END = qr/\A(\.\.\.)(?=$RE_WS|$)/m;
my $RE_DOC_START = qr/\A(---)(?=$RE_WS|$)/m;
my $RE_EOL = qr/\A($RE_WS+#.*|$RE_WS+)\z/;
#my $RE_COMMENT_EOL = qr/\A(#.*)?(?:$RE_LB|\z)/;

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

my $RE_SEQSTART = qr/\A(-)(?=$RE_WS|$)/m;
my $RE_COMPLEX = qr/(\?)(?=$RE_WS|$)/m;
my $RE_COMPLEXCOLON = qr/\A(:)(?=$RE_WS|$)/m;
my $RE_ANCHOR = "&$RE_ANCHOR_CAR+";
my $RE_ALIAS = "\\*$RE_ANCHOR_CAR+";


my %REGEXES = (
    ANCHOR => qr{($RE_ANCHOR)},
    TAG => qr{($RE_TAG)},
    EOL => qr{($RE_EOL)},
#    EMPTY => qr{($RE_COMMENT_EOL)},
    LB => qr{($RE_LB)},
    WS => qr{($RE_WS*)},
    'WS' => qr{($RE_WS+)},
    SCALAR => qr{($RE_PLAIN_WORDS)},
    ALIAS => qr{($RE_ALIAS)},
    QUESTION => qr{$RE_COMPLEX},
    COLON => qr{(?m:(:)(?=$RE_WS|$))},
    DASH => qr{(?m:(-)(?=$RE_WS|$))},
    DOUBLEQUOTE => qr{(")},
    DOUBLEQUOTED => qr{(?:\\(?:.|$)|[^"\r\n\\]+)*}m,
    SINGLEQUOTE => qr{(')},
    SINGLEQUOTED => qr{(?:''|[^'\r\n]+)*},
    LITERAL => qr{(\|)},
    FOLDED => qr{(>)},
    FLOW_MAP_START => qr{(\{)},
    FLOW_SEQ_START => qr{(\[)},
);

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
    my $next_line = $self->fetch_next_line;
    while (defined $next_line) {
        my $yaml = \$next_line->[0];
        my $lb = $next_line->[1];
        TRACE and warn __PACKAGE__.':'.__LINE__.": RE: $indent_re\n";
        TRACE and $parser->debug_yaml;
        my $column = 0;
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
        elsif ($$yaml =~ m/\A$RE_WS*#.*\z/) {
            last;
        }
        elsif ($$yaml =~ s/\A($RE_WS*)\z//) {
            $pre = $1;
            push @$tokens, $self->new_token( WS => $pre, column => $column );
            $column += length $pre;
            push @$tokens, $self->new_token( EOL => $lb, column => $column );
            $space = '';
            $type = 'EMPTY';
            push @lines, [$type => $pre, $space];

            $next_line = $self->fetch_next_line(1) or last;
            next;
        }
        else {
            last;
        }
        if (not length $$yaml) {
            push @$tokens, $self->new_token( EOL => $lb, column => $column );
            $type = 'EMPTY';
            if ($got_indent) {
                push @lines, [$type => $pre, $space];
            }
            else {
                push @lines, [$type => $pre . $space, ''];
            }

            $next_line = $self->fetch_next_line(1) or last;
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

        if ($$yaml =~ s/\A(.*)\z//) {
            my $value = $1;
            push @$tokens, $self->new_token( BLOCK_SCALAR_CONTENT => $value, column => $column );
            $column += length $value;
            push @$tokens, $self->new_token( EOL => $lb, column => $column );
            $type = length $space ? 'MORE' : 'CONTENT';
            push @lines, [ $type => $pre, $space . $value ];

            $next_line = $self->fetch_next_line(1) or last;
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
    my $next_line = $self->fetch_next_line or return [];
    my @multi;
    my $indent = $parser->offset->[ -1 ] + 1;
    my $tokens = $parser->tokens;

    my $indent_re = '[ ]' . '{' . $indent . '}';
    while (defined $next_line) {
        my $yaml = \$next_line->[0];
        my $lb = $next_line->[1];
        my $column = 0;

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
        if ($$yaml =~ s/\A(#.*)\z//) {
            push @$tokens, $self->new_token( COMMENT => $1, column => $column );
            $column += length $1;
            push @$tokens, $self->new_token( EOL => $lb, column => $column );
            last;
        }

        if (not length $$yaml) {
            push @$tokens, $self->new_token( EOL => $lb, column => $column );
            push @multi, '';

            $next_line = $self->fetch_next_line(1) or last;
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
            if ($$yaml =~ s/\A(#.*)\z//) {
                push @$tokens, $self->new_token( COMMENT => $1, column => $column );
                $column += length $1;
                push @$tokens, $self->new_token( EOL => $lb, column => $column );
                $next_line = $self->fetch_next_line(1);
                last;
            }
            if (length $$yaml) {
                $self->exception("Unexpected content");
            }
            push @$tokens, $self->new_token( EOL => $lb, column => $column );
            $next_line = $self->fetch_next_line(1) or last;
        }
        else {
            $self->exception("Unexpected content");
        }
    }
    return \@multi;
}


sub fetch_next_line {
    my ($self, $force) = @_;
    my $next_line = $self->next_line;
    if ($force or not defined $next_line->[0] ) {
        my $line = $self->reader->readline;
        unless (defined $line) {
            $self->set_next_line([]);
            return;
        }
        $self->inc_line;
        $line =~ m/\A( *[^\r\n]*)([\r\n]|\z)/ or die "Unexpected";
        @$next_line = ( $1,  $2 );
        $self->set_next_line($next_line);
    }
    return $next_line;
}

sub fetch_next_tokens {
    my ($self, $offset) = @_;
    my $next = $self->next_tokens;
    unless (@$next) {
        my $next_line = $self->fetch_next_line
            or return $next;

        while (1) {
            # Continue reading for multiline quoted
            my $continue = $self->_fetch_next_tokens($offset, $next_line);
            my $lb = $next_line->[1];
            if (@$next) {
                $next->[-1]->{value} .= $lb;
            }
            last unless $continue;
            $next_line = $self->fetch_next_line(1)
                or last;
        }
        @$next_line = ();
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
    ':' => 'COLON',
    '-' => 'DASH',
    '?' => 'QUESTION',
);

my %ANCHOR_ALIAS_TAG =    ( '&' => 1, '*' => 1, '!' => 1 );
my %BLOCK_SCALAR =        ( '|' => 1, '>' => 1 );
my %COLON_DASH_QUESTION = ( ':' => 1, '-' => 1, '?' => 1 );
my %QUOTED =              ( '"' => 1, "'" => 1 );
my %FLOW =                ( '{' => 1, '[' => 1, '}' => 1, ']' => 1 );

sub _fetch_next_tokens {
    my ($self, $offset, $next_line) = @_;
    my $context = $self->context;
    my $next = $self->next_tokens;

    my $yaml = \$next_line->[0];
    if (not length $$yaml) {
        if ($context eq "'" or $context eq '"') {
            my $token_name = $TOKEN_NAMES{ $context } . 'D_LINE';
            $self->push_token( $token_name => '' );
            $self->push_token( EOL => '' );
            return 1;
        }
        else {
            $self->push_token( EOL => '' );
            return;
        }
    }
    # $ESCAPE_CHAR from YAML.pm
    if ($$yaml =~ tr/\x00-\x08\x0b-\x0c\x0e-\x1f//) {
        $self->exception("Control characters are not allowed");
    }

    my $first = substr($$yaml, 0, 1);

    my @tokens;
    if ($offset == 0) {
        if (substr($$yaml, 0, 3) eq '---') {
            if ($$yaml =~ s/$RE_DOC_START//) {
                push @tokens, ( DOC_START => $1 );
                if ($$yaml =~ s/\A($RE_EOL|\z)//) {
                    push @tokens, ( EOL => $1 );
                    $self->push_tokens(\@tokens);
                    return;
                }
                if ($$yaml =~ s/\A($RE_WS+)//) {
                    push @tokens, ( WS => $1 );
                }
            }
        }
        elsif (substr($$yaml, 0, 3) eq '...') {
            if ($$yaml =~ s/$RE_DOC_END//) {
                push @tokens, ( DOC_END => $1 );
                unless ($$yaml =~ s/\A($RE_EOL|\z)//) {
                    $self->push_tokens(\@tokens);
                    $self->exception("Expected EOL");
                }
                push @tokens, ( EOL => $1 );
                $self->push_tokens(\@tokens);
                return;
            }
        }
        elsif ($context eq 'normal') {
            if ($first eq ' ') {
                my $ws = '';
                if ($$yaml =~ s/\A( +)//) {
                    $ws = $1;
                }
                if ($$yaml =~ s/\A(#.*\z)//) {
                    push @tokens, ( EOL => $ws . $1 );
                    $self->push_tokens(\@tokens);
                    return;
                }
                if (not length $$yaml) {
                    push @tokens, ( EOL => $ws );
                    $self->push_tokens(\@tokens);
                    return;
                }
                push @tokens, ( INDENT => $ws );
            }
            elsif ($first eq "#") {
                if ($$yaml =~ s/\A(#.*\z)//) {
                    push @tokens, ( EOL => $1 );
                    $self->push_tokens(\@tokens);
                    return;
                }
            }
            elsif ($first eq "%") {
                if ($$yaml =~ s/\A(\s*%YAML ?1\.2$RE_WS*)//) {
                    push @tokens, ( YAML_DIRECTIVE => $1 );
                }
                elsif ($$yaml =~ s/\A(\s*%TAG +(!$RE_NS_WORD_CHAR*!|!) +(tag:\S+|!$RE_URI_CHAR+)$RE_WS*)//) {
                    push @tokens, ( TAG_DIRECTIVE => $1 );
                    # TODO
                    my $tag_alias = $2;
                    my $tag_url = $3;
                }
                elsif ($$yaml =~ s/\A(\s*\A%(?:\w+).*)//) {
                    push @tokens, ( RESERVED_DIRECTIVE => $1 );
                    warn "Found reserved directive '$1'";
                }
                else {
                    $self->push_tokens(\@tokens);
                    $self->exception("Invalid directive");
                }
                if (not length $$yaml) {
                    push @tokens, ( EOL => '' );
                }
                else {
                    $self->push_tokens(\@tokens);
                    $self->exception("Invalid directive");
                }
                $self->push_tokens(\@tokens);
                return;
            }
        }
        elsif ($QUOTED{ $context }) {
            my $token_name = $TOKEN_NAMES{ $context };
            my $token_name2 = $token_name . 'D';
            my $regex = $REGEXES{ $token_name2 };
            $token_name2 = $token_name . 'D_LINE';

            my $quoted = '';
            if ($$yaml =~ s/\A($regex)//) {
                $quoted .= $1;
            }

            if ($$yaml =~ s/\A$context//) {
                push @tokens, ( $token_name2 => $quoted );
                push @tokens, ( $token_name => $context );
                $context = 'normal';
                $self->set_context('normal');
            }
            elsif ($$yaml eq '') {
                $token_name2 = $token_name . 'D_LINE';
                push @tokens, ( $token_name2 => $quoted );
                push @tokens, ( EOL => '' );
                $self->push_tokens(\@tokens);
                return 1;
            }
            else {
                $self->push_tokens(\@tokens);
                $self->exception("Invalid quoted string");
            }
        }
    }

    $first = substr($$yaml, 0, 1);
    while (1) {
        unless (length $$yaml) {
            push @tokens, ( EOL => '' );
            $self->push_tokens(\@tokens);
            return;
        }
        my $plain = 0;

        if ($QUOTED{ $first }) {
            my $token_name = $TOKEN_NAMES{ $first };
            my $token_name2 = $token_name . 'D';
            $$yaml =~ s/\A$first//;
            push @tokens, ( $token_name => $first );
            my $regex = $REGEXES{ $token_name2 };

            my $quoted = '';
            if ($$yaml =~ s/\A($regex)//) {
                $quoted .= $1;
            }

            if ($$yaml =~ s/\A$first//) {
                push @tokens, ( $token_name2 => $quoted );
                push @tokens, ( $token_name => $first );
            }
            elsif ($$yaml eq '') {
                push @tokens, ( $token_name . 'D_LINE' => $quoted );
                push @tokens, ( EOL => '' );
                $self->push_tokens(\@tokens);
                $self->set_context($first);
                return 1;
            }
            else {
                $self->push_tokens(\@tokens);
                $self->exception("Invalid quoted string");
            }


        }
        elsif ($COLON_DASH_QUESTION{ $first }) {
            if ($$yaml =~ s/\A\Q$first\E(?:($RE_WS+)|\z)//) {
                my $token_name = $TOKEN_NAMES{ $first };
                push @tokens, ( $token_name => $first );
                if (not defined $1) {
                    push @tokens, ( EOL => '' );
                    $self->push_tokens(\@tokens);
                    return;
                }
                my $ws = $1;
                if ($$yaml =~ s/\A(#.*|)\z//) {
                    push @tokens, ( EOL => $ws . $1 );
                    $self->push_tokens(\@tokens);
                    return;
                }
                push @tokens, ( WS => $ws );
            }
            else {
                $plain = 1;
            }
        }
        elsif ($BLOCK_SCALAR{ $first }) {
            my $token_name = $TOKEN_NAMES{ $first };
            if ($$yaml =~ s/\A\Q$first\E//) {
                push @tokens, ( $token_name => $first );
                if ($$yaml =~ s/\A([1-9]\d*)([+-]?)//) {
                    push @tokens, ( BLOCK_SCALAR_INDENT => $1 );
                    push @tokens, ( BLOCK_SCALAR_CHOMP => $2 ) if $2;
                }
                elsif ($$yaml =~ s/\A([+-])([1-9]\d*)?//) {
                    push @tokens, ( BLOCK_SCALAR_CHOMP => $1 );
                    push @tokens, ( BLOCK_SCALAR_INDENT => $2 ) if $2;
                }
            }
        }
        elsif ($ANCHOR_ALIAS_TAG{ $first }) {
            my $token_name = $TOKEN_NAMES{ $first };
            my $REGEX = $REGEXES{ $token_name };
            if ($$yaml =~ s/\A$REGEX//) {
                push @tokens, ( $token_name => $1 );
            }
            else {
                $self->push_tokens(\@tokens);
                $self->exception("Invalid $token_name");
            }
        }
        elsif ($first eq ' ') {
            if ($$yaml =~ s/\A($RE_WS+)//) {
                my $ws = $1;
                if ($$yaml =~ s/\A((?:#.*)?\z)//) {
                    push @tokens, ( EOL => $ws . $1 );
                    $self->push_tokens(\@tokens);
                    return;
                }
                push @tokens, ( WS => $ws );
            }
        }
        elsif ($FLOW{ $first }) {
            $self->push_tokens(\@tokens);
            $self->exception("Not Implemented: Flow Style");
        }
        else {
            $plain = 1;
        }

        if ($plain) {
            if ($$yaml =~ s/\A($RE_PLAIN_WORDS)//) {
                push @tokens, ( SCALAR => $1 );
                if ($$yaml =~ s/\A(?:($RE_WS+#.*)|($RE_WS*))\z//) {
                    if (defined $1) {
                        push @tokens, ( COMMENT => $1 );
                        push @tokens, ( EOL => '' );
                        $self->push_tokens(\@tokens);
                        return;
                    }
                    push @tokens, ( EOL => $2 );
                    $self->push_tokens(\@tokens);
                    return;
                }
            }
            else {
                $self->push_tokens(\@tokens);
                $self->exception("Invalid plain scalar");
            }
        }

        $first = substr($$yaml, 0, 1);
    }

    return;
}

sub push_token {
    my ($self, $type, $value) = @_;
    my $next = $self->next_tokens;
    my $column = 0;
    if (@$next) {
        my $previous = $next->[-1];
        if ($previous->{name} eq 'EOL') {
            $column = 0;
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
}

sub push_tokens {
    my ($self, $new_tokens) = @_;
    my $next = $self->next_tokens;
    my $line = $self->line;

    my $column = 0;
    for (my $i = 0; $i < @$new_tokens; $i += 2) {
        my $name = $new_tokens->[ $i ];
        my $value = $new_tokens->[ $i + 1 ];
        push @$next, {
            name => $name,
            value => $value,
            line => $line,
            column => $column,
        };
        $column += length $value;
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
        yaml => [''],
    );
    croak $e;
}

1;
