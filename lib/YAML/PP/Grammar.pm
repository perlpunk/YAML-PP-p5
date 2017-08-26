use strict;
use warnings;
package YAML::PP::Grammar;

our $VERSION = '0.000'; # VERSION

use base 'Exporter';

our @EXPORT_OK = qw/ $GRAMMAR /;

our $GRAMMAR = {
    RULE_ALIAS_KEY_OR_NODE => {
        ALIAS => ['cb_stack_alias', {
            EOL => [ 'cb_alias_from_stack', [ \'NODE' ]],
            WS => [0, {
                COLON => [ 'cb_alias_key_from_stack', {
                    EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                    WS => ['cb_ws', [ \'MAPVALUE' ]],
                }],
            }],
        }],
    },
    RULE_COMPLEX => {
        QUESTION => [ 'cb_questionstart', {
            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
            WS => ['cb_ws', [\'TYPE_FULLNODE']],
        }],
    },
    RULE_COMPLEXVALUE => {
        COLON => [ 'cb_complexcolon', {
            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
            WS => ['cb_ws', [ \'TYPE_FULLNODE' ]],
        }],
        DEFAULT => ['cb_empty_complexvalue', {
            QUESTION => ['cb_question', {
                EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                WS => ['cb_ws', [ \'TYPE_FULLNODE' ]],
            }],
            DEFAULT => [0, [
                \'RULE_MAPKEY',
            ]],
        }],
    },
    RULE_SINGLEQUOTED_KEY_OR_NODE => {
        SINGLEQUOTE => [0, {
            SINGLEQUOTED_SINGLE => [ 'cb_stack_singlequoted_single', {
                SINGLEQUOTE => [0, {
                    EOL => [ 'cb_scalar_from_stack', [ \'NODE' ]],
                    'WS?' => [0, {
                        COLON => [ 'cb_mapkey_from_stack', {
                            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                            WS => ['cb_ws', [ \'MAPVALUE' ]],
                        }],
                        EOL => [ 'cb_scalar_from_stack', [
                            \'TYPE_FULLNODE',
                        ]],
                    }],
                }],
            }],
            SINGLEQUOTED_LINE => [ 'cb_stack_singlequoted', {
                LB => [0, [ \'MULTILINE_SINGLEQUOTED' ] ],
            }],
        }],
    },
    MULTILINE_SINGLEQUOTED => {
        SINGLEQUOTED_END => [ 'cb_stack_singlequoted', {
            SINGLEQUOTE => [0, {
                EOL => [ 'cb_scalar_from_stack', [ \'NODE' ]],
            }],
        }],
        SINGLEQUOTED_LINE => [ 'cb_stack_singlequoted', {
            LB => [0, [ \'MULTILINE_SINGLEQUOTED' ]],
        }],
    },
    RULE_DOUBLEQUOTED_KEY_OR_NODE => {
        DOUBLEQUOTE => [0, {
            DOUBLEQUOTED_SINGLE => [ 'cb_stack_doublequoted_single', {
                DOUBLEQUOTE => [ 0, {
                    EOL => [ 'cb_scalar_from_stack', [ \'NODE' ]],
                    'WS?' => [0, {
                        COLON => [ 'cb_mapkey_from_stack', {
                            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                            WS => ['cb_ws', [ \'MAPVALUE' ]],
                        }],
                        DEFAULT => [ 'cb_scalar_from_stack', [
                            \'ERROR',
                        ]],
                    }],
                }],
            }],
            DOUBLEQUOTED_LINE => [ 'cb_stack_doublequoted', {
                LB => [0, [ \'MULTILINE_DOUBLEQUOTED' ] ],
            }],
        }],
    },
    MULTILINE_DOUBLEQUOTED => {
        DOUBLEQUOTED_END => [ 'cb_stack_doublequoted', {
            DOUBLEQUOTE => [0, {
                EOL => [ 'cb_scalar_from_stack', [ \'NODE' ]],
            }],
        }],
        DOUBLEQUOTED_LINE => [ 'cb_stack_doublequoted', {
            LB => [0, [ \'MULTILINE_DOUBLEQUOTED' ] ],
        }],
    },
    RULE_PLAIN_KEY_OR_NODE => {
        SCALAR => [ 'cb_stack_plain', {
            COMMENT_EOL => [ 'cb_plain_single', [ \'NODE' ]],
            EOL => [ 'cb_multiscalar_from_stack', [ \'NODE' ]],
            'WS?' => [0, {
                COLON => [ 'cb_mapkey_from_stack', {
                    EOL => [ 'cb_eol', [ \'TYPE_FULLNODE' ]],
                    'WS?' => [ 'cb_ws', [ \'MAPVALUE' ]],
                }],
            }],
        }],
        COLON => [ 'cb_mapkey_from_stack', {
            EOL => [ 'cb_eol', [ \'TYPE_FULLNODE' ]],
            'WS?' => [ 'cb_ws', [ \'MAPVALUE' ]],
        }],
    },
    RULE_PLAIN => {
        SCALAR => ['cb_stack_plain', {
            COMMENT_EOL => ['cb_multiscalar_from_stack', [ \'NODE' ]],
            EOL => [ 'cb_multiscalar_from_stack', [ \'NODE' ]],
        }],
    },
    RULE_MAPKEY => {
        QUESTION => ['cb_question', {
            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
            WS => ['cb_ws', [ \'TYPE_FULLNODE' ]],
        }],
        ALIAS => [ 'cb_mapkey_alias', {
            WS => [0, {
                COLON => [0, {
                    EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                    WS => ['cb_ws', [ \'MAPVALUE' ]],
                }],
            }],
        }],
        DOUBLEQUOTE => [0, {
            DOUBLEQUOTED_SINGLE => ['cb_doublequoted_key', {
                DOUBLEQUOTE => [ 0, {
                    'WS?' => [0, {
                        COLON => [0, {
                            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                            WS => ['cb_ws', [ \'MAPVALUE' ]],
                        }],
                    }],
                }],
            }],
        }],
        SINGLEQUOTE => [0, {
            SINGLEQUOTED_SINGLE => [ 'cb_singlequoted_key', {
                SINGLEQUOTE => [0, {
                    'WS?' => [0, {
                        COLON => [0, {
                            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                            WS => ['cb_ws', [ \'MAPVALUE' ]],
                        }],
                    }],
                }],
            }],
        }],
        SCALAR => ['cb_mapkey', {
            'WS?' => [ 0, {
                COLON => [0, {
                    EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                    WS => ['cb_ws', [ \'MAPVALUE' ]],
                }],
            }],
        }],
        COLON => [ 'cb_empty_mapkey', {
            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
            WS => ['cb_ws', [ \'MAPVALUE' ]],
        }],
    },
    RULE_MAPSTART => {
        QUESTION => [ 'cb_questionstart', {
            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
            WS => ['cb_ws', [ \'TYPE_FULLNODE' ]],
        }],
        DOUBLEQUOTE => [0, {
            DOUBLEQUOTED => [ 'cb_doublequotedstart', {
                DOUBLEQUOTE => [0, {
                    'WS?' => [0, {
                        COLON => [0, {
                            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                            WS => ['cb_ws', [ \'MAPVALUE' ]],
                        }],
                    }],
                }],
            }],
        }],
        SINGLEQUOTE => [0, {
            SINGLEQUOTED => [ 'cb_singleequotedstart', {
                SINGLEQUOTE => [0, {
                    'WS?' => [0, {
                        COLON => [0, {
                            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                            WS => ['cb_ws', [ \'MAPVALUE' ]],
                        }],
                    }],
                }],
            }],
        }],
        SCALAR => [ 'cb_mapkeystart', {
            'WS?' => [0, {
                COLON => [0, {
                    EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
                    WS => ['cb_ws', [ \'MAPVALUE' ]],
                }],
            }],
        }],
    },
    RULE_SEQSTART => {
        DASH =>[ 'cb_seqstart', {
            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
            WS => ['cb_ws', [ \'TYPE_FULLNODE' ]],
        }],
    },
    RULE_SEQITEM => {
        DASH => [ 'cb_seqitem', {
            EOL => ['cb_eol', [ \'TYPE_FULLNODE' ]],
            WS => ['cb_ws', [ \'TYPE_FULLNODE' ]],
        }],
    },
    RULE_BLOCK_SCALAR => {
        LITERAL => [ 'cb_block_scalar', [ \'NODE' ]],
        FOLDED => [ 'cb_block_scalar', [ \'NODE' ]],
    },
#    RULE_FLOW_MAP => [
#        [['FLOW_MAP_START', 'cb_flow_map'],
#            \'ERROR'
#        ],
#    ],
#    RULE_FLOW_SEQ => [
#        [['FLOW_SEQ_START', 'cb_flow_seq'],
#            \'ERROR'
#        ],
#    ],


    ANCHOR_MAPKEY => {
        ANCHOR => ['cb_anchor', {
            WS => [0, [ \'MAPSTART' ] ],
        }],
    },
    TAG_MAPKEY => {
        TAG => ['cb_tag', {
            WS => [0, [ \'MAPSTART' ] ],
        }],
    },
    FULL_MAPKEY => {
        ANCHOR => ['cb_anchor', {
            WS => [0, {
                TAG => ['cb_tag', {
                    WS => [0, [ \'MAPKEY' ] ],
                }],
                DEFAULT => [0, [ \'MAPKEY' ]],
            }],
        }],
        TAG => ['cb_tag', {
            WS => [0, {
                ANCHOR => ['cb_anchor', {
                    WS => [0, [ \'MAPKEY' ] ],
                }],
                DEFAULT => [0, [ \'MAPKEY' ]],
            }],
        }],
        DEFAULT => [0, [ \'MAPKEY' ]],
    },
    PROP_MAPKEY => {
        ANCHOR => ['cb_anchor', {
            WS => [0, {
                TAG => ['cb_tag', {
                    WS => [0, [ \'MAPSTART' ] ],
                }],
                DEFAULT => [0, [ \'MAPSTART' ]],
            }],
        }],
        TAG => ['cb_tag', {
            WS => [0, {
                ANCHOR => ['cb_anchor', {
                    WS => [0, [ \'MAPSTART' ] ],
                }],
                DEFAULT => [0, [ \'MAPSTART' ]],
            }],
        }],
    },

    FULLNODE_ANCHOR => {
        TAG => ['cb_tag', {
            EOL => ['cb_property_eol', [ \'TYPE_FULLNODE_TAG_ANCHOR' ]],
            WS => [0, [
                \'ANCHOR_MAPKEY',
                # SCALAR
                \'NODE',
            ]],
        }],
        ANCHOR => ['cb_anchor', {
            WS => [0, [
                \'TAG_MAPKEY',
                \'MAPSTART',
            ]],
        }],
        DEFAULT => [0, [
            \'NODE',
        ]],
    },
    FULLNODE_TAG => {
        ANCHOR => ['cb_anchor', {
            EOL => ['cb_property_eol', [ \'TYPE_FULLNODE_TAG_ANCHOR' ]],
            WS => [0, [
                \'TAG_MAPKEY',
                # SCALAR
                \'NODE',
            ]],
        }],
        TAG => ['cb_tag', {
            WS => [0, [
                \'ANCHOR_MAPKEY',
                \'MAPSTART',
            ]],
        }],
        DEFAULT => [0, [ \'NODE' ]],
    },
    FULLNODE_TAG_ANCHOR => [
        \'PROP_MAPKEY',
        \'NODE',
    ],
    FULLNODE => {
        ANCHOR => ['cb_anchor', {
            EOL => ['cb_property_eol', [
                \'TYPE_FULLNODE_ANCHOR',
            ]],
            WS => [0, {
                TAG => ['cb_tag', {
                    EOL => ['cb_property_eol', [
                        \'TYPE_FULLNODE_TAG_ANCHOR'
                    ]],
                    # SCALAR
                    WS => [0, [ \'NODE' ] ],
                }],
                # SCALAR
                DEFAULT => [0, [
                    \'NODE',
                ]],
            }],
        }],
        TAG => ['cb_tag', {
            EOL => ['cb_property_eol', [ \'TYPE_FULLNODE_TAG' ]],
            WS => [0, {
                ANCHOR => ['cb_anchor', {
                    EOL => ['cb_property_eol', [
                        \'TYPE_FULLNODE_TAG_ANCHOR'
                    ]],
                    # SCALAR
                    WS => [0, [ \'NODE' ] ],
                }],
                # SCALAR
                DEFAULT => [0, [ \'NODE' ]],
            }],
        }],
        DEFAULT => [0, [
            \'PREVIOUS',
        ]],
    },
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
};

my %TYPE2RULE = (
    NODETYPE_MAP => {
        %{ $GRAMMAR->{RULE_MAPKEY} },
    },
    NODETYPE_MAPKEY => {
        %{ $GRAMMAR->{RULE_MAPKEY} },
    },
    NODETYPE_MAPSTART => {
        %{ $GRAMMAR->{RULE_MAPSTART} },
    },
    NODETYPE_SEQ => { %{ $GRAMMAR->{RULE_SEQITEM} } },
    NODETYPE_COMPLEX => {
        %{ $GRAMMAR->{RULE_COMPLEXVALUE} },
    },
    NODETYPE_STARTNODE => {
        %{ $GRAMMAR->{RULE_SINGLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_DOUBLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_BLOCK_SCALAR} },
        %{ $GRAMMAR->{RULE_PLAIN} },
    },
    NODETYPE_MAPVALUE => {
        %{ $GRAMMAR->{RULE_ALIAS_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_SINGLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_DOUBLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_BLOCK_SCALAR} },
        %{ $GRAMMAR->{RULE_PLAIN} },
    },
    NODETYPE_NODE => {
        %{ $GRAMMAR->{RULE_SEQSTART} },
        %{ $GRAMMAR->{RULE_COMPLEX} },
        %{ $GRAMMAR->{RULE_SINGLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_DOUBLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_BLOCK_SCALAR} },
        %{ $GRAMMAR->{RULE_ALIAS_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_PLAIN_KEY_OR_NODE} },
    },
);

%$GRAMMAR = (
    %$GRAMMAR,
    %TYPE2RULE,
);

1;
