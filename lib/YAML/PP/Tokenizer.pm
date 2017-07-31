use strict;
use warnings;
package YAML::PP::Tokenizer;

our $VERSION = '0.000'; # VERSION

use constant TRACE => $ENV{YAML_PP_TRACE};
use constant DEBUG => $ENV{YAML_PP_DEBUG} || $ENV{YAML_PP_TRACE};

use constant NODE_TYPE => 0;
use constant NODE_OFFSET => 1;


my $RE_WS = '[\t ]';
my $RE_LB = '[\r\n]';
my $RE_DOC_END = qr/\A\.\.\.(?=$RE_WS|$)/m;
my $RE_DOC_START = qr/\A---(?=$RE_WS|$)/m;
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

#my $RE_PLAIN_START = '[\x21\x22\x24-\x7E]';
my $RE_PLAIN_START = '[\x21\x22\x24-\x39\x3B-\x7E]';
my $RE_PLAIN = '[\x21-\x7E]';
my $RE_PLAIN_END = '[\x21-\x39\x3B-\x7E]';
#my $RE_PLAIN_FIRST = '[\x24\x28-\x29\x2B\x2E-\x3D\x41-\x5A\x5C\x5E-\x5F\x61-\x7A\x7E]';
my $RE_PLAIN_FIRST = '[\x24\x28-\x29\x2B\x2E-\x39\x3B-\x3D\x41-\x5A\x5C\x5E-\x5F\x61-\x7A\x7E]';
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


our $RE_INT = '[+-]?[1-9]\d*';
our $RE_OCT = '0o[1-7][0-7]*';
our $RE_HEX = '0x[1-9a-fA-F][0-9a-fA-F]*';
our $RE_FLOAT = '[+-]?(?:\.\d+|\d+\.\d*)(?:[eE][+-]?\d+)?';
our $RE_NUMBER ="'(?:$RE_INT|$RE_OCT|$RE_HEX|$RE_FLOAT)";

#my $RE_PLAIN_WORD = "$RE_PLAIN_START(?:$RE_PLAIN_END|$RE_PLAIN*$RE_PLAIN_END)?";
my $RE_PLAIN_WORD = "(?::$RE_PLAIN_START|$RE_PLAIN_START)(?::$RE_PLAIN_END|$RE_PLAIN_END)*";
my $RE_PLAIN_FIRST_WORD1 = "(?:[:]$RE_PLAIN_END|$RE_PLAIN_FIRST)(?::$RE_PLAIN_END|$RE_PLAIN_END)*";
my $RE_PLAIN_FIRST_WORD2 = "(?:[?-]$RE_PLAIN_END|$RE_PLAIN_FIRST)(?::$RE_PLAIN_END|$RE_PLAIN_END)*";
#my $RE_PLAIN_FIRST_WORD2 = "(?:$RE_PLAIN_FIRST$RE_PLAIN*$RE_PLAIN_END)";
#my $RE_PLAIN_FIRST_WORD3 = "(?:$RE_PLAIN_FIRST$RE_PLAIN_END?)";
#my $RE_PLAIN_FIRST_WORD = "(?:$RE_PLAIN_FIRST_WORD1|$RE_PLAIN_FIRST_WORD2|$RE_PLAIN_FIRST_WORD3)";
my $RE_PLAIN_FIRST_WORD = "(?:$RE_PLAIN_FIRST_WORD1|$RE_PLAIN_FIRST_WORD2)";
my $RE_PLAIN_KEY = "(?:$RE_PLAIN_FIRST_WORD(?:$RE_WS+$RE_PLAIN_WORD)*|)";
#my $key_content_re_dq = '[^"\r\n\\\\]';
#my $key_content_re_sq = q{[^'\r\n]};
#my $key_re_double_quotes = qr{"(?:\\\\|\\[^\r\n]|$key_content_re_dq)*"};
#my $key_re_single_quotes = qr{'(?:\\\\|''|$key_content_re_sq)*'};
#my $key_full_re = qr{(?:$key_re_double_quotes|$key_re_single_quotes|$RE_PLAIN_KEY)};
my $key_full_re = qr{$RE_PLAIN_KEY};

my $plain_start_word_re = '[^*!&\s#][^\r\n\s]*';
my $plain_word_re = '[^#\r\n\s][^\r\n\s]*';


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


my $rule_anchor = ['ANCHOR', \&cb_anchor];
my $rule_tag = ['TAG', \&cb_tag];
my $rule_property_eol = ['EOL', \&cb_property_eol];
my $rule_eol = ['EOL', \&cb_eol];
my $rule_ws = ['WS+', \&cb_ws];
our %GRAMMAR = (
    RULE_ALIAS_KEY_OR_NODE => [
        [['MAPKEY_ALIAS', \&cb_alias],
            ['WS+',
                ['COLON',
                    [$rule_eol, [\'TYPE_FULLNODE'] ],
                    [$rule_ws, [\'MAPVALUE'] ],
                ],
            ],
        ],
        [['ALIAS', \&cb_node_alias],
            [$rule_eol,
            # TODO
                [\'NODE'],
            ],
        ],
    ],
    RULE_COMPLEX => [
        [['QUESTION', \&cb_questionstart],
            [$rule_eol, [\'TYPE_FULLNODE'] ],
            [$rule_ws, [\'TYPE_FULLNODE'] ],
        ],
    ],
    RULE_COMPLEXVALUE => [
        [['COLON', \&cb_complexcolon, \&cb_empty_complexvalue],
            [$rule_eol, [\'TYPE_FULLNODE'] ],
            [$rule_ws, [\'TYPE_FULLNODE'] ],
        ],
        [['QUESTION', \&cb_question],
            [$rule_eol, [\'TYPE_FULLNODE'] ],
            [$rule_ws, [\'TYPE_FULLNODE'] ],
        ],
    ],
    RULE_SINGLEQUOTED_KEY_OR_NODE => [
        ['SINGLEQUOTE',
            [['SINGLEQUOTED', \&cb_stack_singlequoted],
                ['SINGLEQUOTE',
                    [['EOL', \&cb_scalar_from_stack],
                        [\'NODE'],
                    ],
                    ['WS',
                        [['COLON', \&cb_mapkey_from_stack],
                            [$rule_eol, [\'TYPE_FULLNODE'] ],
                            [$rule_ws, [\'MAPVALUE'] ],
                        ],
                        [['EOL', \&cb_scalar_from_stack],
                            [\'TYPE_FULLNODE'],
                        ],
                    ],
                ],
                ['LB',
                    [\'MULTILINE_SINGLEQUOTED'],
                ],
            ],
        ],
    ],
    MULTILINE_SINGLEQUOTED => [
        [['SINGLEQUOTED', \&cb_stack_singlequoted],
            ['SINGLEQUOTE',
                [['EOL', \&cb_scalar_from_stack],
                    [\'NODE'],
                ],
                ['WS',
                    [['EOL', \&cb_scalar_from_stack],
                        [\'NODE'],
                    ],
                ],
            ],
            ['LB',
                [\'MULTILINE_SINGLEQUOTED'],
            ],
        ],
    ],
    RULE_DOUBLEQUOTED_KEY_OR_NODE => [
        ['DOUBLEQUOTE',
            [['DOUBLEQUOTED', \&cb_stack_doublequoted],
                ['DOUBLEQUOTE',
                    [['EOL', \&cb_scalar_from_stack],
                        [\'NODE'],
                    ],
                    ['WS',
                        [['COLON', \&cb_mapkey_from_stack],
                            [$rule_eol, [\'TYPE_FULLNODE'] ],
                            [$rule_ws, [\'MAPVALUE'] ],
                        ],
                        [['NOOP', \&cb_scalar_from_stack],
                            [\'ERROR'],
                        ],
                    ],
                ],
                ['LB',
                    [\'MULTILINE_DOUBLEQUOTED'],
                ],
            ],
        ],
    ],
    MULTILINE_DOUBLEQUOTED => [
        [['DOUBLEQUOTED', \&cb_stack_doublequoted],
            ['DOUBLEQUOTE',
                [['EOL', \&cb_scalar_from_stack],
                    [\'NODE'],
                ],
                ['WS',
                    [['EOL', \&cb_scalar_from_stack],
                        [\'NODE'],
                    ],
                ],
            ],
            ['LB',
                [\'MULTILINE_DOUBLEQUOTED'],
            ],
        ],
    ],
    RULE_PLAIN_KEY_OR_NODE => [
        [['SCALAR', \&cb_stack_plain],
            ['WS+',
                [['EMPTY', \&cb_plain_single],
                    [\'NODE'],
                ],
                [['COLON', \&cb_mapkey_from_stack],
                    [['EOL', \&cb_eol],
                        [\'TYPE_FULLNODE'],
                    ],
                    [['WS', \&cb_ws],
                        [\'MAPVALUE'],
                    ],
                ],
            ],
            [['LB', \&cb_multiscalar_from_stack],
                [\'NODE'],
            ],
            [['EOS', \&cb_multiscalar_from_stack],
                [\'END'],
            ],
            [['COLON', \&cb_mapkey_from_stack],
                [['EOL', \&cb_eol],
                    [\'TYPE_FULLNODE'],
                ],
                [['WS', \&cb_ws],
                    [\'MAPVALUE'],
                ],
            ],
        ],
    ],
    RULE_PLAIN => [
        [['SCALAR', \&cb_stack_plain],
            [['EOL', \&cb_multiscalar_from_stack],
                [\'NODE'],
            ],
            [['EOS', \&cb_multiscalar_from_stack],
                [\'END'],
            ],
        ],
    ],
    RULE_MAPKEY_ALIAS => [
        [['MAPKEY_ALIAS', \&cb_mapkey_alias],
            ['WS+',
                ['COLON',
                    [$rule_eol, [\'TYPE_FULLNODE'], ],
                    [$rule_ws, [\'MAPVALUE'], ],
                ],
            ],
        ],
    ],
    RULE_MAPKEY => [
        [['QUESTION', \&cb_question],
            [$rule_eol, [\'TYPE_FULLNODE'], ],
            [$rule_ws, [\'TYPE_FULLNODE'], ],
        ],
        ['DOUBLEQUOTE',
            [['DOUBLEQUOTED', \&cb_doublequoted],
                ['DOUBLEQUOTE',
                    ['WS',
                        ['COLON',
                            [$rule_eol, [\'TYPE_FULLNODE'], ],
                            [$rule_ws, [\'MAPVALUE'], ],
                        ],
                    ],
                ],
            ],
        ],
        ['SINGLEQUOTE',
            [['SINGLEQUOTED', \&cb_singleequoted],
                ['SINGLEQUOTE',
                    ['WS',
                        ['COLON',
                            [$rule_eol, [\'TYPE_FULLNODE'], ],
                            [$rule_ws, [\'MAPVALUE'], ],
                        ],
                    ],
                ],
            ],
        ],
        [['SCALAR', \&cb_mapkey],
            ['WS',
                ['COLON',
                    [$rule_eol, [\'TYPE_FULLNODE'], ],
                    [$rule_ws, [\'MAPVALUE'], ],
                ],
            ],
        ],
    ],
    RULE_MAPSTART => [
        [['QUESTION', \&cb_questionstart],
            [$rule_eol, [\'TYPE_FULLNODE'], ],
            [$rule_ws, [\'TYPE_FULLNODE'], ],
        ],
        ['DOUBLEQUOTE',
            [['DOUBLEQUOTED', \&cb_doublequotedstart],
                ['DOUBLEQUOTE',
                    ['WS',
                        ['COLON',
                            [$rule_eol, [\'TYPE_FULLNODE'], ],
                            [$rule_ws, [\'MAPVALUE'], ],
                        ],
                    ],
                ],
            ],
        ],
        ['SINGLEQUOTE',
            [['SINGLEQUOTED', \&cb_singleequotedstart],
                ['SINGLEQUOTE',
                    ['WS',
                        ['COLON',
                            [$rule_eol, [\'TYPE_FULLNODE'], ],
                            [$rule_ws, [\'MAPVALUE'], ],
                        ],
                    ],
                ],
            ],
        ],
        [['SCALAR', \&cb_mapkeystart],
            ['WS',
                ['COLON',
                    [$rule_eol, [\'TYPE_FULLNODE'], ],
                    [$rule_ws, [\'MAPVALUE'], ],
                ],
            ],
        ],
    ],
    RULE_SEQSTART => [
        [['DASH', \&cb_seqstart],
            [$rule_eol, [\'TYPE_FULLNODE'], ],
            [$rule_ws, [\'TYPE_FULLNODE'], ],
        ],
    ],
    RULE_SEQITEM => [
        [['DASH', \&cb_seqitem],
            [$rule_eol, [\'TYPE_FULLNODE'], ],
            [$rule_ws, [\'TYPE_FULLNODE'], ],
        ],
    ],
    RULE_BLOCK_SCALAR => [
        [['LITERAL', \&cb_block_scalar],
            [\'NODE'],
        ],
        [['FOLDED', \&cb_block_scalar],
            [\'NODE'],
        ],
    ],
    RULE_FLOW_MAP => [
        [['FLOW_MAP_START', \&cb_flow_map],
            [\'ERROR'],
        ],
    ],
    RULE_FLOW_SEQ => [
        [['FLOW_SEQ_START', \&cb_flow_seq],
            [\'ERROR'],
        ],
    ],


    ANCHOR_MAPKEY => [
        [$rule_anchor,
            ['WS+', [\'MAPSTART'], ],
        ],
    ],
    TAG_MAPKEY => [
        [$rule_tag,
            ['WS+', [\'MAPSTART'], ],
        ],
    ],
    FULL_MAPKEY => [
        [$rule_anchor,
            ['WS+',
                [$rule_tag,
                    ['WS+', [\'MAPKEY'], ],
                ],
                [\'MAPKEY'],
            ],
        ],
        [$rule_tag,
            ['WS+',
                [$rule_anchor,
                    ['WS+', [\'MAPKEY'], ],
                ],
                [\'MAPKEY'],
            ],
        ],
        [\'MAPKEY'],
    ],
    PROP_MAPKEY => [
        [$rule_anchor,
            ['WS+',
                [$rule_tag,
                    ['WS+', [\'MAPSTART'], ],
                ],
                [\'MAPSTART'],
            ],
        ],
        [$rule_tag,
            ['WS+',
                [$rule_anchor,
                    ['WS+', [\'MAPSTART'], ],
                ],
                [\'MAPSTART'],
            ],
        ],
    ],

    FULLNODE_ANCHOR => [
        [$rule_tag,
            [$rule_property_eol,
                [\'TYPE_FULLNODE_TAG_ANCHOR'],
            ],
            ['WS+',
                [\'ANCHOR_MAPKEY'],
                # SCALAR
                [\'NODE'],
            ],
        ],
        [$rule_anchor,
            ['WS+',
                [\'TAG_MAPKEY'],
                [\'MAPSTART'],
            ],
        ],
        [\'NODE'],
    ],
    FULLNODE_TAG => [
        [$rule_anchor,
            [$rule_property_eol,
                [\'TYPE_FULLNODE_TAG_ANCHOR'],
            ],
            ['WS+',
                [\'TAG_MAPKEY'],
                # SCALAR
                [\'NODE'],
            ],
        ],
        [$rule_tag,
            ['WS+',
                [\'ANCHOR_MAPKEY'],
                [\'MAPSTART'],
            ],
        ],
        [\'NODE'],
    ],
    FULLNODE_TAG_ANCHOR => [
        [\'PROP_MAPKEY'],
        [\'NODE'],
    ],
    RULE_ANCHOR => [
        [$rule_anchor,
            [$rule_property_eol,
                [\'TYPE_FULLNODE_ANCHOR'],
            ],
            ['WS+',
                [$rule_tag,
                    [$rule_property_eol,
                        [\'TYPE_FULLNODE_TAG_ANCHOR'],
                    ],
                    # SCALAR
                    ['WS+', [\'NODE'] ],
                ],
                # SCALAR
                [\'NODE'],
            ],
        ],
    ],
    RULE_TAG => [
        [$rule_tag,
            [$rule_property_eol,
                [\'TYPE_FULLNODE_TAG'],
            ],
            ['WS+',
                [$rule_anchor,
                    [$rule_property_eol,
                        [\'TYPE_FULLNODE_TAG_ANCHOR'],
                    ],
                    # SCALAR
                    ['WS+', [\'NODE'] ],
                ],
                # SCALAR
                [\'NODE'],
            ],
        ],
    ],
    FULLNODE => [
        [\'RULE_ANCHOR'],
        [\'RULE_TAG'],
        [\'PREVIOUS'],
    ],
#    FULLMAPVALUE => [
#        [\'RULE_ANCHOR'],
#        [\'RULE_TAG'],
#        [\'MAPVALUE'],
#    ],
#    FULLSTARTNODE => [
#        [\'RULE_ANCHOR'],
#        [\'RULE_TAG'],
#        [\'STARTNODE'],
#    ],
);

sub cb_ws {
    my ($self, $res, $props) = @_;
    if ($res) {
        $res->{ws} = length $self->tokens->[-1]->[1];
        $res->{eol} = 0;
    }
}

sub cb_property_eol {
    my ($self, $res) = @_;
    my $node_props = $self->stack->{node_properties} ||= {};
    my $props = $self->stack->{properties} ||= {};
    if (defined $props->{anchor}) {
        $node_props->{anchor} = delete $props->{anchor};
    }
    if (defined $props->{tag}) {
        $node_props->{tag} = delete $props->{tag};
    }
}

sub cb_eol {
    my ($self, $res) = @_;
    $res->{eol} = 1;
    return;
}

sub cb_tag {
    my ($self, $res) = @_;
    my $props = $self->stack->{properties} ||= {};
    $props->{tag} = $self->tokens->[-1]->[1];
}

sub cb_anchor {
    my ($self, $res) = @_;
    my $props = $self->stack->{properties} ||= {};
    my $anchor = $self->tokens->[-1]->[1];
    $anchor = substr($anchor, 1);
    $props->{anchor} = $anchor;
}

sub cb_mapkey {
    my ($self, $res) = @_;
    my $value = $self->tokens->[-1]->[1];
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ value => undef, {
        style => ':',
        value => $self->tokens->[-1]->[1],
    }];
}

sub cb_mapkeystart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ begin => 'MAP', { }];
    push @{ $self->stack->{events} }, [ value => undef, {
        style => ':',
        value => $self->tokens->[-1]->[1],
    }];
    $res->{name} = 'MAPSTART';
}

sub cb_doublequoted {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ value => undef, {
        style => '"',
        value => [ $self->tokens->[-1]->[1] ],
    }];
}

sub cb_doublequotedstart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ begin => 'MAP', { }];
    push @{ $self->stack->{events} }, [ value => undef, {
        style => '"',
        value => [ $self->tokens->[-1]->[1] ],
    }];
    $res->{name} = 'MAPSTART';
}

sub cb_singleequoted {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ value => undef, {
        style => "'",
        value => [ $self->tokens->[-1]->[1] ],
    }];
}

sub cb_singleequotedstart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ begin => 'MAP', { }];
    push @{ $self->stack->{events} }, [ value => undef, {
        style => "'",
        value => [ $self->tokens->[-1]->[1] ],
    }];
    $res->{name} = 'MAPSTART';
}

sub cb_mapkey_alias {
    my ($self, $res) = @_;
    my $alias = $self->tokens->[-1]->[1];
    $alias = substr($alias, 1);
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ alias => undef, {
        alias => $alias,
    }];
}

sub cb_question {
    my ($self, $res) = @_;
    $res->{name} = 'COMPLEX';
}

sub cb_empty_complexvalue {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ value => undef, { style => ':' }];
}

sub cb_questionstart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ begin => 'COMPLEX', { }];
    $res->{name} = 'NOOP';
}

sub cb_complexcolon {
    my ($self, $res) = @_;
    $res->{name} = 'COMPLEXCOLON';
}

sub cb_seqstart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ begin => 'SEQ', { }];
    $res->{name} = 'NOOP';
}

sub cb_seqitem {
    my ($self, $res) = @_;
    $res->{name} = 'SEQITEM';
}

sub cb_alias {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ begin => 'MAP', { }];
    my $alias = $self->tokens->[-1]->[1];
    $alias = substr($alias, 1);
    push @{ $self->stack->{events} }, [ alias => undef, {
        alias => $alias,
    }];
    $res->{name} = 'MAPSTART';
}

sub cb_node_alias {
    my ($self, $res) = @_;
    my $alias = $self->tokens->[-1]->[1];
    $alias = substr($alias, 1);
    $res->{name} = 'SCALAR';
    push @{ $self->stack->{events} }, [ alias => undef, {
        alias => $alias,
    }];
}

sub cb_stack_singlequoted {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => "'",
        value => [],
    };
    push @{ $self->stack->{res}->{value} }, $self->tokens->[-1]->[1];
}

sub cb_stack_doublequoted {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => '"',
        value => [],
    };
    push @{ $self->stack->{res}->{value} }, $self->tokens->[-1]->[1];
}

sub cb_stack_plain {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => ':',
        value => [],
    };
    push @{ $self->stack->{res}->{value} }, $self->tokens->[-1]->[1];
}

sub cb_plain_single {
    my ($self, $res) = @_;
    $res->{name} = 'SCALAR';
    $res->{eol} = 1;
    push @{ $self->stack->{events} }, [ value => undef, {
        style => ':',
        value => $self->stack->{res}->{value},
    }];
    undef $self->stack->{res};
}

sub cb_mapkey_from_stack {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ begin => 'MAP', { }];
    %$res = %{ $self->stack->{res} };
    undef $self->stack->{res};
    push @{ $self->stack->{events} }, [ value => undef, {
        %$res,
    }];
    $res->{name} = 'MAPSTART';

}

sub cb_scalar_from_stack {
    my ($self, $res) = @_;
    my $stack = $self->stack;
    push @{ $self->stack->{events} }, [ value => undef, {
        %{ $self->stack->{res} },
    }];
    undef $self->stack->{res};
    $res->{name} = 'SCALAR';
    $res->{eol} = 1;
}

sub cb_multiscalar_from_stack {
    my ($self, $res) = @_;
    my $stack = $self->stack;
    my $multi = $self->parse_plain_multi;
    my $first = $self->stack->{res}->{value}->[0];
    $res->{eol} = delete $multi->{eol};
    unshift @{ $multi->{value} }, $first;
    push @{ $self->stack->{events} }, [ value => undef, {
        %$multi,
    }];
    undef $self->stack->{res};
    $res->{name} = 'SCALAR';
}

sub cb_block_scalar {
    my ($self, $res) = @_;
    my $type = $self->tokens->[-1]->[1];
    my $block = $self->parse_block_scalar(
        type => $type,
    );
    $res->{eol} = delete $block->{eol};
    push @{ $self->stack->{events} }, [ value => undef, {
        %$block,
    }];
    $res->{name} = 'SCALAR';
}

sub cb_flow_map {
    die "Not Implemented: Flow Style";
}

sub cb_flow_seq {
    die "Not Implemented: Flow Style";
}

my %REGEXES = (
    ANCHOR => qr{(&$RE_ANCHOR)},
    TAG => qr{($RE_TAG)},
    EOL => qr{($RE_EOL)},
    EMPTY => qr{($RE_COMMENT_EOL)},
    LB => qr{($RE_LB)},
    WS => qr{($RE_WS*)},
    'WS+' => qr{($RE_WS+)},
    SCALAR => qr{($RE_PLAIN_KEY)},
    MAPKEY_ALIAS => qr{$RE_ALIAS(?=$RE_WS+:(?m:$RE_WS|$))},
#    MAPKEY_ALIAS => qr{$RE_ALIAS)},
    ALIAS => qr{$RE_ALIAS},
    QUESTION => qr{$RE_COMPLEX},
    COLON => qr{(?m:(:)(?=$RE_WS|$))},
    DASH => qr{(?m:(-)(?=$RE_WS|$))},
    DOUBLEQUOTE => qr{(")},
    DOUBLEQUOTED => qr{((?:\\"|[^"\r\n])*)},
    SINGLEQUOTE => qr{(')},
    SINGLEQUOTED => qr{((?:''|[^'\r\n])*)},
    LITERAL => qr{(\|)},
    FOLDED => qr{(>)},
    FLOW_MAP_START => qr{(\{)},
    FLOW_SEQ_START => qr{(\[)},
);
my %RULES_BY_FIRST = (
    ANY => {
        SCALAR => 0,
        DOUBLEQUOTED => 0,
        SINGLEQUOTED => 0,
        WS => 0,
    },
    '&' => {
        ANCHOR => 0,
        SINGLEQUOTED => 0,
        DOUBLEQUOTED => 0,
        WS => 0,
    },
    '!' => {
        TAG => 0,
        SINGLEQUOTED => 0,
        DOUBLEQUOTED => 0,
        WS => 0,
    },
    '*' => {
        ALIAS => 0,
        MAPKEY_ALIAS => 0,
        SINGLEQUOTED => 0,
        DOUBLEQUOTED => 0,
        WS => 0,
    },
    "\t" => {
        WS => 0,
        'WS+' => 0,
        EOL => 0,
        SINGLEQUOTED => 0,
        DOUBLEQUOTED => 0,
        WS => 0,
    },
    "\n" => {
        EOL => 0,
        LB => 0,
        EMPTY => 0,
        SINGLEQUOTED => 0,
        DOUBLEQUOTED => 0,
        WS => 0,
    },
    "\r" => {
        EOL => 0,
        LB => 0,
        EMPTY => 0,
        SINGLEQUOTED => 0,
        DOUBLEQUOTED => 0,
        WS => 0,
    },
    '' => {
        EOL => 1,
    },
    "'" => {
        SINGLEQUOTE => 1,
        SINGLEQUOTED => 0,
        DOUBLEQUOTED => 0,
        WS => 0,
    },
    '"' => {
        DOUBLEQUOTE => 1,
        SINGLEQUOTED => 0,
        DOUBLEQUOTED => 0,
        WS => 0,
    },
    ' ' => {
        EOL => 0,
        WS => 0,
        'WS+' => 0,
        DOUBLEQUOTED => 0,
        SINGLEQUOTED => 0,
        WS => 0,
    },
    ':' => {
        SCALAR => 0,
        COLON => 0,
        DOUBLEQUOTED => 0,
        SINGLEQUOTED => 0,
        WS => 0,
    },
    '-' => {
        DASH => 0,
        SCALAR => 0,
        DOUBLEQUOTED => 0,
        SINGLEQUOTED => 0,
        WS => 0,
    },
    '?' => {
        QUESTION => 0,
        SCALAR => 0,
        DOUBLEQUOTED => 0,
        SINGLEQUOTED => 0,
        WS => 0,
    },
    '|' => {
        LITERAL => 0,
        DOUBLEQUOTED => 0,
        SINGLEQUOTED => 0,
        WS => 0,
    },
    '>' => {
        FOLDED => 0,
        DOUBLEQUOTED => 0,
        SINGLEQUOTED => 0,
        WS => 0,
    },
    '#' => {
        EOL => 0,
        EMPTY => 0,
        DOUBLEQUOTED => 0,
        SINGLEQUOTED => 0,
        WS => 0,
    },
);

sub parse_tokens {
    my ($self, %args) = @_;
    my $rules = $self->rules;
    my $callback = $args{callback};
    my $tokens = $self->tokens;
    my $new_type;
    my $ok = 0;

    TRACE and $self->debug_rules($rules);
    TRACE and $self->debug_yaml;
    DEBUG and $self->debug_next_line;

    my @next_tokens;
    my $yaml = $self->yaml;
    my $first = substr($$yaml, 0, 1);
    RULE: while (my $next_rule = shift @$rules) {
        my ($rule, @next_rule) = @$next_rule;

        if (ref $rule eq 'SCALAR') {
            DEBUG and $self->got("NEW: $$rule");
            TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$rule], ['rule']);
            if (exists $GRAMMAR{ $$rule }) {
                unshift @$rules, @{ $GRAMMAR{ $$rule } };
                next RULE;
            }
            else {
                $new_type = $$rule;
                last RULE;
            }
        }

        my $sub;
        my $subfalse;
        if (ref $rule eq 'ARRAY') {
            ($rule, $sub, $subfalse) = @$rule;
        }

        my $success;
        DEBUG and $YAML::PP::Tokenizer::CHECK_RULE{ $rule }++;
        if ($rule eq 'EOS') {
            $success = not length $$yaml;
        }
        elsif ($rule eq 'NOOP') {
            $success = 1;
        }
        else {
            my $possible_rules = $RULES_BY_FIRST{ $first } || $RULES_BY_FIRST{ANY};

            TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$first], ['first']);
            TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$rule], ['rule']);
            TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$possible_rules], ['possible_rules']);
            if (not exists $possible_rules->{ $rule }) {
                $success = 0;
            }
            if ($possible_rules->{ $rule }) {
                substr($$yaml, 0, 1, '');
                $first = substr($$yaml, 0, 1);
                push @$tokens, [ $rule, $first ];
                $success = 1;
            }

            unless (defined $success) {
                DEBUG and $YAML::PP::Tokenizer::MATCH_RULE{ $rule }++;
                my $regex = $REGEXES{ $rule } or die "No regex found for '$rule'";
                $success = $$yaml =~ s/\A$regex//;
                if ($success) {
                    push @$tokens, [$rule, $1];
                    $first = substr($$yaml, 0, 1);
                }
            }

        }

        if ($success) {
            DEBUG and $self->got("got $rule");
            $ok = 1;

            @$rules = @next_rule;
            if ($sub) {
                $callback->($self, $sub);
            }
        }
        else {
            DEBUG and $self->not("not $rule");

            if ($subfalse) {
                $subfalse->($self, $sub);
            }
            unless (@$rules) {
                return (0);
            }
        }
    }
    TRACE and $self->highlight_yaml;
    TRACE and $self->debug_tokens;

    return ($ok, $new_type);
}

1;
