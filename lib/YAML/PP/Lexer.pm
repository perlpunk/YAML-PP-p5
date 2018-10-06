use strict;
use warnings;
package YAML::PP::Lexer;

our $VERSION = '0.000'; # VERSION

use constant TRACE => $ENV{YAML_PP_TRACE} ? 1 : 0;
use constant DEBUG => ($ENV{YAML_PP_DEBUG} || $ENV{YAML_PP_TRACE}) ? 1 : 0;

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
    $self->{next_line} = undef;
    $self->{line} = 0;
    $self->{context} = 'normal';
    $self->{flowcontext} = 0;
}

sub next_line { return $_[0]->{next_line} }
sub set_next_line { $_[0]->{next_line} = $_[1] }
sub reader { return $_[0]->{reader} }
sub set_reader { $_[0]->{reader} = $_[1] }
sub next_tokens { return $_[0]->{next_tokens} }
sub line { return $_[0]->{line} }
sub set_line { $_[0]->{line} = $_[1] }
sub offset { return $_[0]->{offset} }
sub set_offset { $_[0]->{offset} = $_[1] }
sub inc_line { return $_[0]->{line}++ }
sub context { return $_[0]->{context} }
sub set_context { $_[0]->{context} = $_[1] }
sub flowcontext { return $_[0]->{flowcontext} }
sub set_flowcontext { $_[0]->{flowcontext} = $_[1] }

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
my $RE_ANCHOR_CAR = '[\x21-\x2B\x2D-\x5A\x5C\x5E-\x7A\x7C\x7E\xA0-\xFF\x{100}-\x{10FFFF}]';

my $RE_PLAIN_START = '[\x21\x22\x24-\x39\x3B-\x7E\xA0-\xFF\x{100}-\x{10FFFF}]';
my $RE_PLAIN_END = '[\x21-\x39\x3B-\x7E\xA0-\xFF\x{100}-\x{10FFFF}]';
my $RE_PLAIN_FIRST = '[\x24\x28-\x29\x2B\x2E-\x39\x3B-\x3D\x41-\x5A\x5C\x5E-\x5F\x61-\x7A\x7E\xA0-\xFF\x{100}-\x{10FFFF}]';

my $RE_PLAIN_START_FLOW = '[\x21\x22\x24-\x2B\x2D-\x39\x3B-\x5A\x5C\x5E-\x7A\x7C\x7E\xA0-\xFF\x{100}-\x{10FFFF}]';
my $RE_PLAIN_END_FLOW = '[\x21-\x2B\x2D-\x39\x3B-\x5A\x5C\x5E-\x7A\x7C\x7E\xA0-\xFF\x{100}-\x{10FFFF}]';
my $RE_PLAIN_FIRST_FLOW = '[\x24\x28-\x29\x2B\x2E-\x39\x3B-\x3D\x41-\x5A\x5C\x5E-\x5F\x61-\x7A\x7C\x7E\xA0-\xFF\x{100}-\x{10FFFF}]';
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

my $RE_PLAIN_WORD_FLOW = "(?::+$RE_PLAIN_END_FLOW|$RE_PLAIN_START_FLOW)(?::+$RE_PLAIN_END_FLOW|$RE_PLAIN_END_FLOW)*";
my $RE_PLAIN_FIRST_WORD_FLOW = "(?:[:?-]+$RE_PLAIN_END_FLOW|$RE_PLAIN_FIRST_FLOW)(?::+$RE_PLAIN_END_FLOW|$RE_PLAIN_END_FLOW)*";
my $RE_PLAIN_WORDS_FLOW = "(?:$RE_PLAIN_FIRST_WORD_FLOW(?:$RE_WS+$RE_PLAIN_WORD_FLOW)*)";
my $RE_PLAIN_WORDS_FLOW2 = "(?:$RE_PLAIN_WORD_FLOW(?:$RE_WS+$RE_PLAIN_WORD_FLOW)*)";


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
    DOUBLEQUOTED => qr{(?:\\(?:[ \\\/_0abefnrtvLNP"]|x[0-9a-fA-F]{2}|[uU][0-9a-fA-F]+|$)|[^"\r\n\\]+)*}m,
    SINGLEQUOTE => qr{(')},
    SINGLEQUOTED => qr{(?:''|[^'\r\n]+)*},
    LITERAL => qr{(\|)},
    FOLDED => qr{(>)},
    FLOW_MAP_START => qr{(\{)},
    FLOW_SEQ_START => qr{(\[)},
);

sub _fetch_next_tokens_plain {
    my ($self, $indent, $next_line) = @_;
    my ($spaces, $content) = @$next_line;
    my $ws = '';
    if ($content =~ s/\A($RE_WS+)//) {
        $ws = $1;
    }
    if ($content =~ s/\A(#.*)\z//) {
        $self->push_tokens( [ COMMENT => $spaces . $ws . $1, EOL => '' ]);
        $self->set_context('normal');
        return;
    }

    if (not length $content) {
        $self->push_tokens( [ EOL => $spaces . $ws ] );
        $self->set_next_line(undef);
        return;
    }
    my @tokens;
    push @tokens, INDENT => $spaces;
    push @tokens, WS => $ws;

    my $RE = $RE_PLAIN_WORDS2;
    if ($self->flowcontext) {
        $RE = $RE_PLAIN_WORDS_FLOW2;
    }

    if ($content =~ s/\A($RE)//) {
        my $string = $1;
        push @tokens, PLAIN => $string;
        my $ws = '';
        if ($content =~ s/\A($RE_WS+)//) {
            $ws = $1;
        }
        if ($content =~ s/\A(#.*)\z//) {
            push @tokens, COMMENT => $ws . $1;
            push @tokens, EOL => '';
            $self->set_context('normal');
            $self->push_tokens( \@tokens );
            $self->set_next_line(undef);
            return;
        }
        if (length $content) {
            push @tokens, WS => $ws if $ws;
            $self->set_context('normal');
            $next_line->[0] = '';
            $next_line->[1] = $content;
            $self->push_tokens( \@tokens );
            my $ret = $self->_fetch_next_tokens($indent, $next_line);
            return $ret;
        }
        $self->set_next_line(undef);
        push @tokens, EOL => $ws;
    }
    else {
        if ($self->flowcontext) {
            $self->set_context('normal');
            $next_line->[0] = '';
            $next_line->[1] = $content;
            $self->push_tokens( \@tokens );
            my $ret = $self->_fetch_next_tokens($indent, $next_line);
            return $ret;
        }
        push @tokens, ERROR => $content;
    }
    $self->push_tokens( \@tokens );
    return;
}

sub fetch_next_line {
    my ($self) = @_;
    my $next_line = $self->next_line;
    if (defined $next_line ) {
        return $next_line;
    }

    my $line = $self->reader->readline;
    unless (defined $line) {
        $self->set_next_line(undef);
        return;
    }
    $self->inc_line;
    $line =~ m/\A( *)([^\r\n]*)([\r\n]|\z)/ or die "Unexpected";
    $next_line = [ $1,  $2, $3 ];
    $self->set_next_line($next_line);

    return $next_line;
}

my %fetch_methods = (
    normal => '_fetch_next_tokens',
    plain => '_fetch_next_tokens_plain',
);

sub fetch_next_tokens {
    my ($self, $indent) = @_;
    my $next = $self->next_tokens;
    return $next if @$next;

    my $next_line = $self->fetch_next_line;
    my $status = '';
    my @tokens;
    if (not $next_line) {
        $status = 'END_STREAM';
    }
    else {
        my ($spaces, $content) = @$next_line;
        if (not $spaces and $content =~ s/\A(---|\.\.\.)(?=$RE_WS|\z)//) {
            my $t = $1;
            my $token_name = { '---' => 'DOC_START', '...' => 'DOC_END' }->{ $t };
            @tokens = [ $token_name => $t ];
            $status = 'END';
            $next_line->[1] = $content;
        }
        elsif ((length $spaces) < $indent) {
            if (not length $content) {
                $status = 'EOL';
                $self->push_tokens( [ EOL => $spaces . $next_line->[2] ] );
                $self->set_next_line(undef);
                return $next;
            }
            else {
                $status = 'LESS';
            }
        }
    }
    if ($self->context eq 'normal') {
        return [] if $status eq 'END_STREAM';
    }
    else {
        if ($status) {
            $self->push_tokens( [ END => '' ] );
            $self->set_context('normal');
            if ($status eq 'END_STREAM') {
                return [];
            }
        }
    }
    $self->push_tokens( @tokens ) if @tokens;
    my $method = $fetch_methods{ $self->context };
    TRACE and warn __PACKAGE__.':'.__LINE__.": fetch next tokens: $method\n";
    my $partial = $self->$method($indent, $next_line);

    if (not $partial) {
        $self->set_next_line(undef);
    }
    if (not $partial and @$next) {
        $next->[-1]->{value} .= $next_line->[2];
        $self->set_next_line(undef);
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
    '[' => 'FLOWSEQ_START',
    ']' => 'FLOWSEQ_END',
    '{' => 'FLOWMAP_START',
    '}' => 'FLOWMAP_END',
    ',' => 'FLOW_COMMA',
);

my %ANCHOR_ALIAS_TAG =    ( '&' => 1, '*' => 1, '!' => 1 );
my %BLOCK_SCALAR =        ( '|' => 1, '>' => 1 );
my %COLON_DASH_QUESTION = ( ':' => 1, '-' => 1, '?' => 1 );
my %QUOTED =              ( '"' => 1, "'" => 1 );
my %FLOW =                ( '{' => 1, '[' => 1, '}' => 1, ']' => 1 );

my $RE_ESCAPES = qr{(?:
    \\([ \\\/_0abefnrtvLNP"]) | \\x([0-9a-fA-F]{2})
    | \\u([A-Fa-f0-9]{4}) | \\U([A-Fa-f0-9]{4,8})
)}x;
my %CONTROL = (
    '\\' => '\\', '/' => '/', n => "\n", t => "\t", r => "\r", b => "\b",
    'a' => "\a", 'b' => "\b", 'e' => "\e", 'f' => "\f", 'v' => "\x0b",
    'P' => "\x{2029}", L => "\x{2028}", 'N' => "\x85",
    '0' => "\0", '_' => "\xa0", ' ' => ' ', q/"/ => q/"/,
);

sub _fetch_next_tokens {
    my ($self, $indent, $next_line) = @_;
    my $offset = $self->offset || 0;
    my $flowcontext = $self->flowcontext;
    my $next = $self->next_tokens;
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$next_line], ['next_line']);

    my $spaces = $next_line->[0];
    my $yaml = \$next_line->[1];
    if (not length $$yaml) {
        $self->push_tokens( [ EOL => $spaces ] );
        return;
    }
    # $ESCAPE_CHAR from YAML.pm
    if ($$yaml =~ tr/\x00-\x08\x0b-\x0c\x0e-\x1f//) {
        $self->exception("Control characters are not allowed");
    }

    my $first = substr($$yaml, 0, 1);

    my @tokens;
    if ($offset == 0) {
        if ($first eq '#') {
            push @tokens, ( EOL => $spaces . $$yaml );
            $$yaml = '';
            $self->push_tokens(\@tokens);
            return;
        }
        if ($spaces ) {
            push @tokens, ( INDENT => $spaces );
        }
        elsif ($first eq "%" and not $self->flowcontext) {
            $self->_fetch_next_tokens_directive($yaml);
            return;
        }
    }

    while (1) {
        unless (length $$yaml) {
            push @tokens, ( EOL => '' );
            $self->push_tokens(\@tokens);
            return;
        }
        $first = substr($$yaml, 0, 1);
        my $plain = 0;

        if ($QUOTED{ $first }) {
            push @tokens, ( CONTEXT => $first );
            $self->push_tokens(\@tokens);
            return 1;
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
                next;
            }
            $plain = 1;
        }
        elsif ($BLOCK_SCALAR{ $first }) {
            push @tokens, ( CONTEXT => $first );
            $self->push_tokens(\@tokens);
            return 1;

        }
        elsif ($ANCHOR_ALIAS_TAG{ $first }) {
            my $token_name = $TOKEN_NAMES{ $first };
            my $REGEX = $REGEXES{ $token_name };
            if ($$yaml =~ s/\A$REGEX//) {
                push @tokens, ( $token_name => $1 );
            }
            else {
                push @tokens, ( "Invalid $token_name" => $$yaml );
                $self->push_tokens(\@tokens);
                return;
            }
        }
        elsif ($first eq ' ' or $first eq "\t") {
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
            if ($first eq '{' or $first eq '[') {
                push @tokens, ( $TOKEN_NAMES{ $first } => $first );
                substr($$yaml, 0, 1, '');
                $self->set_flowcontext(++$flowcontext);
            }
            if ($first eq '}' or $first eq ']') {
                push @tokens, ( $TOKEN_NAMES{ $first } => $first );
                substr($$yaml, 0, 1, '');
                $self->set_flowcontext(--$flowcontext);
            }
        }
        elsif ($first eq ',') {
            push @tokens, ( $TOKEN_NAMES{ $first } => $first );
            substr($$yaml, 0, 1, '');
        }
        else {
            $plain = 1;
        }

        if ($plain) {
            my $RE = $RE_PLAIN_WORDS;
#            warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$flowcontext], ['flowcontext']);
            if ($flowcontext) {
                $RE = $RE_PLAIN_WORDS_FLOW;
            }
            if ($$yaml =~ s/\A($RE)//) {
                push @tokens, ( PLAIN => $1 );
#                warn __PACKAGE__.':'.__LINE__.": PLAIN >>$1<<\n";
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
                push @tokens, ( 'Invalid plain scalar' => $$yaml );
                $self->push_tokens(\@tokens);
                return;
            }
        }

    }

    return;
}

sub fetch_block {
    my ($self, $indent, $context) = @_;
    my $next_line = $self->next_line;
    my $yaml = \$next_line->[1];
    my $eol = $next_line->[2];

    my @tokens;
    my $token_name = $TOKEN_NAMES{ $context };
    $$yaml =~ s/\A\Q$context\E// or die "Unexpected";
    push @tokens, ( $token_name => $context );
    my $current_indent = $indent;
    my $started = 0;
    my $set_indent = 0;
    if ($$yaml =~ s/\A([1-9]\d*)([+-]?)//) {
        push @tokens, ( BLOCK_SCALAR_INDENT => $1 );
        $set_indent = $1;
        push @tokens, ( BLOCK_SCALAR_CHOMP => $2 ) if $2;
    }
    elsif ($$yaml =~ s/\A([+-])([1-9]\d*)?//) {
        push @tokens, ( BLOCK_SCALAR_CHOMP => $1 );
        push @tokens, ( BLOCK_SCALAR_INDENT => $2 ) if $2;
        $set_indent = $2 if $2;
    }
    if ($set_indent) {
        $started = 1;
        $current_indent = $set_indent;
    }
    unless (length $$yaml) {
        push @tokens, ( EOL => $eol );
    }
    if ($$yaml =~ s/\A$RE_WS+(?:#.*)\z//) {
        push @tokens, ( EOL => $eol );
    }

    while (1) {
        $self->set_next_line(undef);
        my $next_line = $self->fetch_next_line;
        if (not $next_line) {
            push @tokens, ( END => '' );
            last;
        }
        my $spaces = $next_line->[0];
        my $content = $next_line->[1];
        my $eol = $next_line->[2];
        if (not $spaces and $content =~ m/\A(---|\.\.\.)(?=$RE_WS|\z)/) {
            push @tokens, ( END => '' );
            last;
        }
        if ((length $spaces) < $current_indent) {
            if (length $content) {
                push @tokens, ( END => '' );
                last;
            }
            else {
                push @tokens, ( EOL => $spaces . $eol );
                next;
            }
        }
        if ((length $spaces) > $current_indent) {
            if ($started) {
                ($spaces, my $more_spaces) = unpack "a${current_indent}a*", $spaces;
                $content = $more_spaces . $content;
            }
        }
        unless (length $content) {
            push @tokens, ( INDENT => $spaces, EOL => $eol );
            unless ($started) {
                $current_indent = length $spaces;
            }
            next;
        }
        unless ($started) {
            $started = 1;
            $current_indent = length $spaces;
        }
        push @tokens, (
            INDENT => $spaces,
            BLOCK_SCALAR_CONTENT => $content,
            EOL => $eol,
        );
    }
    $self->push_tokens(\@tokens);
    return 1;
}

sub fetch_quoted {
    my ($self, $indent, $context) = @_;
    my $next_line = $self->next_line;
    my $yaml = \$next_line->[1];
    $$yaml =~ s/\A$context//;
    my @tokens;

    my ($return, @quoted_tokens) = $self->_read_quoted_tokens(1, $context, $yaml);
    push @tokens, @quoted_tokens;
    $self->push_tokens(\@tokens);
    if ($return) {
        if ($return == 2) {
            return;
        }
    }
    else {
        return $self->_fetch_next_tokens($indent, $next_line);
    }
    $self->set_next_line(undef);
    while (1) {

        my $next_line = $self->fetch_next_line;
        if (not $next_line) {
            last;
        }
        my @tokens;

        my $spaces = $next_line->[0];
        my $yaml = \$next_line->[1];
        if (not $spaces and $$yaml =~ m/\A(---|\.\.\.)(?=$RE_WS|\z)/) {
            push @tokens, ( 'Invalid quoted string' => $$yaml );
            $self->push_tokens(\@tokens);
            $self->set_next_line(undef);
            last;
        }
        elsif (not length $$yaml) {
            $self->push_tokens( [ EOL => $spaces . $next_line->[2] ] );
            $self->set_next_line(undef);
        }
        elsif ((length $spaces) < $indent) {
            push @tokens, ( 'Invalid quoted string' => $$yaml );
            $self->push_tokens(\@tokens);
            $self->set_next_line(undef);
            last;
        }
        else {
            if ($$yaml =~ s/\A($RE_WS+)//) {
                $spaces .= $1;
            }

            push @tokens, ( WS => $spaces );
            my ($return, @quoted_tokens) = $self->_read_quoted_tokens(0, $context, $yaml);
            push @tokens, @quoted_tokens;
            $self->push_tokens(\@tokens);
            if ($return) {
                if ($return == 2) {
                    last;
                }
            }
            else {
                return $self->_fetch_next_tokens($indent, $next_line);
            }
            $self->set_next_line(undef);
        }
    }
}

sub _read_quoted_tokens {
    my ($self, $start, $first, $yaml) = @_;
    my $quoted = '';
    my $decoded = '';
    if ($first eq "'") {
        my $regex = $REGEXES{SINGLEQUOTED};
        if ($$yaml =~ s/\A($regex)//) {
            $quoted .= $1;
            $decoded .= $1;
            $decoded =~ s/''/'/g;
        }
    }
    else {
        ($quoted, $decoded) = $self->_read_doublequoted($yaml);
    }
    my $token_name = $TOKEN_NAMES{ $first };
    my $token_name2 = $token_name . 'D';
    my @tokens;
    my $return = 0;

    if ($$yaml =~ s/\A$first//) {
        if ($start) {
            my @subtokens;
            push @subtokens, ( $token_name => $first );
            push @subtokens, ( $token_name2 => { value => $decoded, orig => $quoted } );
            push @subtokens, ( $token_name => $first );
            push @tokens, ( QUOTED => \@subtokens );
        }
        else {
            $token_name2 = $token_name . 'D_LINE';
            push @tokens, ( $token_name2 => { value => $decoded, orig => $quoted } );
            push @tokens, ( $token_name => $first );
        }
    }
    elsif (not length $$yaml) {
        my $eol = '';
        if ($quoted =~ s/($RE_WS+)\z//) {
            $eol = $1;
            $decoded =~ s/($eol)\z//;
        }
        push @tokens, ( $token_name => $first ) if $start;
        push @tokens, ( $token_name . 'D_LINE' => { value => $decoded, orig => $quoted } );
        push @tokens, ( EOL => $eol );
        $return = 1;
    }
    else {
        push @tokens, ( $token_name => $first ) if $start;
        push @tokens, ( $token_name2 => { value => $decoded, orig => $quoted } );
        push @tokens, ( 'Invalid quoted string' => $$yaml );
        $return = 2;
    }

    return ($return, @tokens);
}

sub _read_doublequoted {
    my ($self, $yaml) = @_;
    my $quoted = '';
    my $decoded = '';
    while (1) {
        my $last = 1;
        if ($$yaml =~ s/\A([^"\\]+)//) {
            $quoted .= $1;
            $decoded .= $1;
            $last = 0;
        }
        if ($$yaml =~ s/\A($RE_ESCAPES)//) {
            $quoted .= $1;
            my $dec = defined $2 ? $CONTROL{ $2 }
                        : defined $3 ? chr hex $3
                        : defined $4 ? chr hex $4
                        : chr hex $5;
            $decoded .= $dec;
            $last = 0;
        }
        if ($$yaml =~ s/\A(\\)\z//) {
            $quoted .= $1;
            $decoded .= $1;
            last;
        }
        last if $last;
    }
    return ($quoted, $decoded);
}

sub _fetch_next_tokens_directive {
    my ($self, $yaml) = @_;
    my @tokens;

    if ($$yaml =~ s/\A(\s*%YAML)//) {
        my $dir = $1;
        if ($$yaml =~ s/\A( )//) {
            $dir .= $1;
            if ($$yaml =~ s/\A(1\.2$RE_WS*)//) {
                $dir .= $1;
                push @tokens, ( YAML_DIRECTIVE => $dir );
            }
            else {
                $$yaml =~ s/\A(.*)//;
                $dir .= $1;
                my $warn = $ENV{YAML_PP_RESERVED_DIRECTIVE} || 'warn';
                if ($warn eq 'warn') {
                    warn "Found reserved directive '$dir'";
                }
                elsif ($warn eq 'fatal') {
                    die "Found reserved directive '$dir'";
                }
                push @tokens, ( RESERVED_DIRECTIVE => "$dir" );
            }
        }
        else {
            $$yaml =~ s/\A(.*)//;
            $dir .= $1;
            push @tokens, ( 'Invalid directive' => $dir );
            $self->push_tokens(\@tokens);
            return;
        }
    }
    elsif ($$yaml =~ s/\A(\s*%TAG +(!$RE_NS_WORD_CHAR*!|!) +(tag:\S+|!$RE_URI_CHAR+)$RE_WS*)//) {
        push @tokens, ( TAG_DIRECTIVE => $1 );
        # TODO
        my $tag_alias = $2;
        my $tag_url = $3;
    }
    elsif ($$yaml =~ s/\A(\s*\A%(?:\w+).*)//) {
        push @tokens, ( RESERVED_DIRECTIVE => $1 );
        my $warn = $ENV{YAML_PP_RESERVED_DIRECTIVE} || 'warn';
        if ($warn eq 'warn') {
            warn "Found reserved directive '$1'";
        }
        elsif ($warn eq 'fatal') {
            die "Found reserved directive '$1'";
        }
    }
    else {
        push @tokens, ( 'Invalid directive' => $$yaml );
        $self->push_tokens(\@tokens);
        return;
    }
    if (not length $$yaml) {
        push @tokens, ( EOL => '' );
    }
    else {
        push @tokens, ( 'Invalid directive' => $$yaml );
    }
    $self->push_tokens(\@tokens);
    return;
}

sub push_tokens {
    my ($self, $new_tokens) = @_;
    my $next = $self->next_tokens;
    my $line = $self->line;

    my $column = $self->offset || 0;

    for (my $i = 0; $i < @$new_tokens; $i += 2) {
        my $value = $new_tokens->[ $i + 1 ];
        my $name = $new_tokens->[ $i ];
        my $push = {
            name => $new_tokens->[ $i ],
            line => $line,
            column => $column,
        };
        if (ref $value eq 'ARRAY') {
            my @subtokens = @$value;
            for (my $i = 0; $i < @subtokens; $i += 2) {
                my $value = $subtokens[ $i + 1 ];
                my $name = $subtokens[ $i ];

                my %sub = (
                    name => $subtokens[ $i ],
                    line => $line,
                    column => $column,
                    value => $value,
                );
                if (ref $value eq 'HASH') {
                    %sub = ( %sub, %$value );
                    $column += length $value->{orig};
                }
                else {
                    $column += length $value unless $name eq 'CONTEXT';
                }
                push @{ $push->{value} }, {
                    %sub
                };
            }
        }
        elsif (ref $value eq 'HASH') {
            %$push = ( %$push, %$value );
            $column += length $value->{orig} unless $name eq 'CONTEXT';
        }
        else {
            $push->{value} = $value;
            $column += length $value unless $name eq 'CONTEXT';
        }
        push @$next, $push;
        if ($push->{name} eq 'EOL') {
            $column = 0;
        }
    }
#    if ($next->[-1]->{name} eq 'EOL') {
#        $column = 0;
#    }
    $self->set_offset($column);
    return $next;
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
