use strict;
use warnings;
package YAML::PP::Grammar;

our $VERSION = '0.000'; # VERSION

use base 'Exporter';

our @EXPORT_OK = qw/ $GRAMMAR /;

our $GRAMMAR = {
    RULE_ALIAS_KEY_OR_NODE => {
        ALIAS => {
            match => 'cb_stack_alias',
            EOL => { match => 'cb_alias_from_stack', new => \'NODE' },
            WS => {
                COLON => {
                    match => 'cb_alias_key_from_stack',
                    EOL => { new => \'TYPE_FULLNODE' },
                    WS => { new => \'MAPVALUE' },
                },
            },
        },
    },
    RULE_COMPLEX => {
        QUESTION => {
            match => 'cb_questionstart',
            EOL => { new => \'TYPE_FULLNODE' },
            WS => { new => \'TYPE_FULLNODE'},
        },
    },
    RULE_COMPLEXVALUE => {
        COLON => {
            match => 'cb_complexcolon',
            EOL => { new => \'TYPE_FULLNODE' },
            WS => { new => \'TYPE_FULLNODE' },
        },
        DEFAULT => {
            match => 'cb_empty_complexvalue',
            QUESTION => {
                match => 'cb_question',
                EOL => { new => \'TYPE_FULLNODE' },
                WS => { new => \'TYPE_FULLNODE' },
            },
            DEFAULT => { new => \'RULE_MAPKEY' },
        },
    },
    RULE_SINGLEQUOTED_KEY_OR_NODE => {
        SINGLEQUOTE => {
            SINGLEQUOTED_SINGLE => {
                match => 'cb_stack_singlequoted_single',
                SINGLEQUOTE => {
                    EOL => { match => 'cb_scalar_from_stack', new => \'NODE' },
                    'WS?' => {
                        COLON => {
                            match => 'cb_mapkey_from_stack',
                            EOL => { new => \'TYPE_FULLNODE' },
                            WS => { new => \'MAPVALUE' },
                        },
                    },
                },
            },
            SINGLEQUOTED_LINE => {
                match => 'cb_stack_singlequoted',
                LB => { new => \'MULTILINE_SINGLEQUOTED'  },
            },
        },
    },
    MULTILINE_SINGLEQUOTED => {
        SINGLEQUOTED_END => {
            match => 'cb_stack_singlequoted',
            SINGLEQUOTE => {
                EOL => { match => 'cb_scalar_from_stack', new => \'NODE' },
            },
        },
        SINGLEQUOTED_LINE => {
            match => 'cb_stack_singlequoted',
            LB => { new => \'MULTILINE_SINGLEQUOTED' },
        },
    },
    RULE_DOUBLEQUOTED_KEY_OR_NODE => {
        DOUBLEQUOTE => {
            DOUBLEQUOTED_SINGLE => {
                match => 'cb_stack_doublequoted_single',
                DOUBLEQUOTE => {
                    EOL => { match => 'cb_scalar_from_stack', new => \'NODE' },
                    'WS?' => {
                        COLON => {
                            match => 'cb_mapkey_from_stack',
                            EOL => { new => \'TYPE_FULLNODE' },
                            WS => { new => \'MAPVALUE' },
                        },
                        DEFAULT => { match => 'cb_scalar_from_stack', new => \'ERROR' },
                    },
                },
            },
            DOUBLEQUOTED_LINE => {
                match => 'cb_stack_doublequoted',
                LB => { new => \'MULTILINE_DOUBLEQUOTED'  },
            },
        },
    },
    MULTILINE_DOUBLEQUOTED => {
        DOUBLEQUOTED_END => {
            match => 'cb_stack_doublequoted',
            DOUBLEQUOTE => {
                EOL => { match => 'cb_scalar_from_stack', new => \'NODE' },
            },
        },
        DOUBLEQUOTED_LINE => {
            match => 'cb_stack_doublequoted',
            LB => { new => \'MULTILINE_DOUBLEQUOTED'  },
        },
    },
    RULE_PLAIN_KEY_OR_NODE => {
        SCALAR => {
            match => 'cb_stack_plain',
            COMMENT_EOL => { match => 'cb_plain_single', new => \'NODE' },
            EOL => { match => 'cb_multiscalar_from_stack', new => \'NODE' },
            'WS?' => {
                COLON => {
                    match => 'cb_mapkey_from_stack',
                    EOL => { new => \'TYPE_FULLNODE' },
                    'WS?' => { new => \'MAPVALUE' },
                },
            },
        },
        COLON => {
            match => 'cb_mapkey_from_stack',
            EOL => { new => \'TYPE_FULLNODE' },
            'WS?' => { new => \'MAPVALUE' },
        },
    },
    RULE_PLAIN => {
        SCALAR => {
            match => 'cb_stack_plain',
            COMMENT_EOL => { match => 'cb_multiscalar_from_stack', new => \'NODE' },
            EOL => { match => 'cb_multiscalar_from_stack', new => \'NODE' },
        },
    },
    RULE_MAPKEY => {
        QUESTION => {
            match => 'cb_question',
            EOL => { new => \'TYPE_FULLNODE' },
            WS => { new => \'TYPE_FULLNODE' },
        },
        ALIAS => {
            match => 'cb_mapkey_alias',
            WS => {
                COLON => {
                    EOL => { new => \'TYPE_FULLNODE' },
                    WS => { new => \'MAPVALUE' },
                },
            },
        },
        DOUBLEQUOTE => {
            DOUBLEQUOTED_SINGLE => {
                match => 'cb_doublequoted_key',
                DOUBLEQUOTE => {
                    'WS?' => {
                        COLON => {
                            EOL => { new => \'TYPE_FULLNODE' },
                            WS => { new => \'MAPVALUE' },
                        },
                    },
                },
            },
        },
        SINGLEQUOTE => {
            SINGLEQUOTED_SINGLE => {
                match => 'cb_singlequoted_key',
                SINGLEQUOTE => {
                    'WS?' => {
                        COLON => {
                            EOL => { new => \'TYPE_FULLNODE' },
                            WS => { new => \'MAPVALUE' },
                        },
                    },
                },
            },
        },
        SCALAR => {
            match => 'cb_mapkey',
            'WS?' => {
                COLON => {
                    EOL => { new => \'TYPE_FULLNODE' },
                    WS => { new => \'MAPVALUE' },
                },
            },
        },
        COLON => {
            match => 'cb_empty_mapkey',
            EOL => { new => \'TYPE_FULLNODE' },
            WS => { new => \'MAPVALUE' },
        },
    },
    RULE_MAPSTART => {
        QUESTION => {
            match => 'cb_questionstart',
            EOL => { new => \'TYPE_FULLNODE' },
            WS => { new => \'TYPE_FULLNODE' },
        },
        DOUBLEQUOTE => {
            DOUBLEQUOTED => {
                match => 'cb_doublequotedstart',
                DOUBLEQUOTE => {
                    'WS?' => {
                        COLON => {
                            EOL => { new => \'TYPE_FULLNODE' },
                            WS => { new => \'MAPVALUE' },
                        },
                    },
                },
            },
        },
        SINGLEQUOTE => {
            SINGLEQUOTED => {
                match => 'cb_singleequotedstart',
                SINGLEQUOTE => {
                    'WS?' => {
                        COLON => {
                            EOL => { new => \'TYPE_FULLNODE' },
                            WS => { new => \'MAPVALUE' },
                        },
                    },
                },
            },
        },
        SCALAR => {
            match => 'cb_mapkeystart',
            'WS?' => {
                COLON => {
                    EOL => { new => \'TYPE_FULLNODE' },
                    WS => { new => \'MAPVALUE' },
                },
            },
        },
    },
    RULE_SEQSTART => {
        DASH => {
            match => 'cb_seqstart',
            EOL => { new => \'TYPE_FULLNODE' },
            WS => { new => \'TYPE_FULLNODE' },
        },
    },
    RULE_SEQITEM => {
        DASH => {
            match => 'cb_seqitem',
            EOL => { new => \'TYPE_FULLNODE' },
            WS => { new => \'TYPE_FULLNODE' },
        },
    },
    RULE_BLOCK_SCALAR => {
        LITERAL => { match => 'cb_block_scalar', new => \'NODE' },
        FOLDED => { match => 'cb_block_scalar', new => \'NODE' },
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


    FULL_MAPKEY => {
        ANCHOR => {
            match => 'cb_anchor',
            WS => {
                TAG => {
                    match => 'cb_tag',
                    WS => { new => \'MAPKEY'  },
                },
                DEFAULT => { new => \'MAPKEY' },
            },
        },
        TAG => {
            match => 'cb_tag',
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    WS => { new => \'MAPKEY'  },
                },
                DEFAULT => { new => \'MAPKEY' },
            },
        },
        DEFAULT => { new => \'MAPKEY' },
    },

    FULLNODE_ANCHOR => {
        TAG => {
            match => 'cb_tag',
            EOL => { match => 'cb_property_eol', new => \'TYPE_FULLNODE_TAG_ANCHOR' },
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    WS => { new => \'MAPSTART'  },
                },
                DEFAULT => { new => \'NODE' }
            },
        },
        ANCHOR => {
            match => 'cb_anchor',
            WS => {
                TAG => {
                    match => 'cb_tag',
                    WS => { new => \'MAPSTART'  },
                },
                DEFAULT => { new => \'MAPSTART' },
            },
        },
        DEFAULT => { new => \'NODE' },
    },
    FULLNODE_TAG => {
        ANCHOR => {
            match => 'cb_anchor',
            EOL => { match => 'cb_property_eol', new => \'TYPE_FULLNODE_TAG_ANCHOR' },
            WS => {
                TAG => {
                    match => 'cb_tag',
                    WS => { new => \'MAPSTART'  },
                },
                DEFAULT => { new => \'NODE', },
            },
        },
        TAG => {
            match => 'cb_tag',
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    WS => { new => \'MAPSTART'  },
                },
                DEFAULT => { new => \'MAPSTART' },
            },
        },
        DEFAULT => { new => \'NODE' },
    },
    FULLNODE_TAG_ANCHOR => {
        ANCHOR => {
            match => 'cb_anchor',
            WS => {
                TAG => {
                    match => 'cb_tag',
                    WS => { new => \'MAPSTART'  },
                },
                DEFAULT => { new => \'MAPSTART' },
            },
        },
        TAG => {
            match => 'cb_tag',
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    WS => { new => \'MAPSTART'  },
                },
                DEFAULT => { new => \'MAPSTART' },
            },
        },
        DEFAULT => { new => \'NODE' }
    },
    FULLNODE => {
        ANCHOR => {
            match => 'cb_anchor',
            EOL => { match => 'cb_property_eol', new => \'TYPE_FULLNODE_ANCHOR' },
            WS => {
                TAG => {
                    match => 'cb_tag',
                    EOL => { match => 'cb_property_eol', new => \'TYPE_FULLNODE_TAG_ANCHOR' },
                    # SCALAR
                    WS => { new => \'NODE'  },
                },
                # SCALAR
                DEFAULT => { new => \'NODE' },
            },
        },
        TAG => {
            match => 'cb_tag',
            EOL => { match => 'cb_property_eol', new => \'TYPE_FULLNODE_TAG' },
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    EOL => { match => 'cb_property_eol', new => \'TYPE_FULLNODE_TAG_ANCHOR' },
                    # SCALAR
                    WS => { new => \'NODE'  },
                },
                # SCALAR
                DEFAULT => { new => \'NODE' },
            },
        },
        DEFAULT => { new => \'PREVIOUS' },
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
