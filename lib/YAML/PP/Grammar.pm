use strict;
use warnings;
package YAML::PP::Grammar;

our $VERSION = '0.000'; # VERSION

use base 'Exporter';

our @EXPORT_OK = qw/ $GRAMMAR /;

our $GRAMMAR = {
    RULE_ALIAS_KEY_OR_NODE => {
        ALIAS => [\&cb_stack_alias, {
            EOL => [ \&cb_alias_from_stack, [ \'NODE' ]],
            WS => [0, {
                COLON => [ \&cb_alias_key_from_stack, {
                    EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                    WS => [\&cb_ws, [ \'MAPVALUE' ]],
                }],
            }],
        }],
    },
    RULE_COMPLEX => {
        QUESTION => [ \&cb_questionstart, {
            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
            WS => [\&cb_ws, [\'TYPE_FULLNODE']],
        }],
    },
    RULE_COMPLEXVALUE => {
        COLON => [ \&cb_complexcolon, {
            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
            WS => [\&cb_ws, [ \'TYPE_FULLNODE' ]],
        }],
        DEFAULT => [\&cb_empty_complexvalue, {
            QUESTION => [\&cb_question, {
                EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                WS => [\&cb_ws, [ \'TYPE_FULLNODE' ]],
            }],
            DEFAULT => [0, [
                \'RULE_MAPKEY_ALIAS',
                \'RULE_MAPKEY',
            ]],
        }],
    },
    RULE_SINGLEQUOTED_KEY_OR_NODE => {
        SINGLEQUOTE => [0, {
            SINGLEQUOTED_SINGLE => [ \&cb_stack_singlequoted_single, {
                SINGLEQUOTE => [0, {
                    EOL => [ \&cb_scalar_from_stack, [ \'NODE' ]],
                    'WS?' => [0, {
                        COLON => [ \&cb_mapkey_from_stack, {
                            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                            WS => [\&cb_ws, [ \'MAPVALUE' ]],
                        }],
                        EOL => [ \&cb_scalar_from_stack, [
                            \'TYPE_FULLNODE',
                        ]],
                    }],
                }],
                LB => [0, [ \'MULTILINE_SINGLEQUOTED' ]],
            }],
            SINGLEQUOTED_LINE => [ \&cb_stack_singlequoted, {
                LB => [0, [ \'MULTILINE_SINGLEQUOTED' ] ],
            }],
        }],
    },
    MULTILINE_SINGLEQUOTED => {
        SINGLEQUOTED_END => [ \&cb_stack_singlequoted, {
            SINGLEQUOTE => [0, {
                EOL => [ \&cb_scalar_from_stack, [ \'NODE' ]],
            }],
        }],
        SINGLEQUOTED_LINE => [ \&cb_stack_singlequoted, {
            LB => [0, [ \'MULTILINE_SINGLEQUOTED' ]],
        }],
    },
    RULE_DOUBLEQUOTED_KEY_OR_NODE => {
        DOUBLEQUOTE => [0, {
            DOUBLEQUOTED_SINGLE => [ \&cb_stack_doublequoted_single, {
                DOUBLEQUOTE => [ 0, {
                    EOL => [ \&cb_scalar_from_stack, [ \'NODE' ]],
                    'WS?' => [0, {
                        COLON => [ \&cb_mapkey_from_stack, {
                            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                            WS => [\&cb_ws, [ \'MAPVALUE' ]],
                        }],
                        DEFAULT => [ \&cb_scalar_from_stack, [
                            \'ERROR',
                        ]],
                    }],
                }],
            }],
            DOUBLEQUOTED_LINE => [ \&cb_stack_doublequoted, {
                LB => [0, [ \'MULTILINE_DOUBLEQUOTED' ] ],
            }],
        }],
    },
    MULTILINE_DOUBLEQUOTED => {
        DOUBLEQUOTED_END => [ \&cb_stack_doublequoted, {
            DOUBLEQUOTE => [0, {
                EOL => [ \&cb_scalar_from_stack, [ \'NODE' ]],
            }],
        }],
        DOUBLEQUOTED_LINE => [ \&cb_stack_doublequoted, {
            LB => [0, [ \'MULTILINE_DOUBLEQUOTED' ] ],
        }],
    },
    RULE_PLAIN_KEY_OR_NODE => {
        SCALAR => [ \&cb_stack_plain, {
            COMMENT_EOL => [ \&cb_plain_single, [ \'NODE' ]],
            EOL => [ \&cb_multiscalar_from_stack, [ \'NODE' ]],
            'WS?' => [0, {
                COLON => [ \&cb_mapkey_from_stack, {
                    EOL => [ \&cb_eol, [ \'TYPE_FULLNODE' ]],
                    'WS?' => [ \&cb_ws, [ \'MAPVALUE' ]],
                }],
            }],
        }],
        COLON => [ \&cb_mapkey_from_stack, {
            EOL => [ \&cb_eol, [ \'TYPE_FULLNODE' ]],
            'WS?' => [ \&cb_ws, [ \'MAPVALUE' ]],
        }],
    },
    RULE_PLAIN => {
        SCALAR => [\&cb_stack_plain, {
            COMMENT_EOL => [\&cb_multiscalar_from_stack, [ \'NODE' ]],
            EOL => [ \&cb_multiscalar_from_stack, [ \'NODE' ]],
        }],
    },
    RULE_MAPKEY_ALIAS => {
        ALIAS => [ \&cb_mapkey_alias, {
            WS => [0, {
                COLON => [0, {
                    EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                    WS => [\&cb_ws, [ \'MAPVALUE' ]],
                }],
            }],
        }],
    },
    RULE_MAPKEY => {
        QUESTION => [\&cb_question, {
            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
            WS => [\&cb_ws, [ \'TYPE_FULLNODE' ]],
        }],
        DOUBLEQUOTE => [0, {
            DOUBLEQUOTED_SINGLE => [\&cb_doublequoted_key, {
                DOUBLEQUOTE => [ 0, {
                    'WS?' => [0, {
                        COLON => [0, {
                            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                            WS => [\&cb_ws, [ \'MAPVALUE' ]],
                        }],
                    }],
                }],
            }],
        }],
        SINGLEQUOTE => [0, {
            SINGLEQUOTED_SINGLE => [ \&cb_singlequoted_key, {
                SINGLEQUOTE => [0, {
                    'WS?' => [0, {
                        COLON => [0, {
                            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                            WS => [\&cb_ws, [ \'MAPVALUE' ]],
                        }],
                    }],
                }],
            }],
        }],
        SCALAR => [\&cb_mapkey, {
            'WS?' => [ 0, {
                COLON => [0, {
                    EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                    WS => [\&cb_ws, [ \'MAPVALUE' ]],
                }],
            }],
        }],
        COLON => [ \&cb_empty_mapkey, {
            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
            WS => [\&cb_ws, [ \'MAPVALUE' ]],
        }],
    },
    RULE_MAPSTART => {
        QUESTION => [ \&cb_questionstart, {
            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
            WS => [\&cb_ws, [ \'TYPE_FULLNODE' ]],
        }],
        DOUBLEQUOTE => [0, {
            DOUBLEQUOTED => [ \&cb_doublequotedstart, {
                DOUBLEQUOTE => [0, {
                    'WS?' => [0, {
                        COLON => [0, {
                            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                            WS => [\&cb_ws, [ \'MAPVALUE' ]],
                        }],
                    }],
                }],
            }],
        }],
        SINGLEQUOTE => [0, {
            SINGLEQUOTED => [ \&cb_singleequotedstart, {
                SINGLEQUOTE => [0, {
                    'WS?' => [0, {
                        COLON => [0, {
                            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                            WS => [\&cb_ws, [ \'MAPVALUE' ]],
                        }],
                    }],
                }],
            }],
        }],
        SCALAR => [ \&cb_mapkeystart, {
            'WS?' => [0, {
                COLON => [0, {
                    EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
                    WS => [\&cb_ws, [ \'MAPVALUE' ]],
                }],
            }],
        }],
    },
    RULE_SEQSTART => {
        DASH =>[ \&cb_seqstart, {
            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
            WS => [\&cb_ws, [ \'TYPE_FULLNODE' ]],
        }],
    },
    RULE_SEQITEM => {
        DASH => [ \&cb_seqitem, {
            EOL => [\&cb_eol, [ \'TYPE_FULLNODE' ]],
            WS => [\&cb_ws, [ \'TYPE_FULLNODE' ]],
        }],
    },
    RULE_BLOCK_SCALAR => {
        LITERAL => [ \&cb_block_scalar, [ \'NODE' ]],
        FOLDED => [ \&cb_block_scalar, [ \'NODE' ]],
    },
#    RULE_FLOW_MAP => [
#        [['FLOW_MAP_START', \&cb_flow_map],
#            \'ERROR'
#        ],
#    ],
#    RULE_FLOW_SEQ => [
#        [['FLOW_SEQ_START', \&cb_flow_seq],
#            \'ERROR'
#        ],
#    ],


    ANCHOR_MAPKEY => {
        ANCHOR => [\&cb_anchor, {
            WS => [0, [ \'MAPSTART' ] ],
        }],
    },
    TAG_MAPKEY => {
        TAG => [\&cb_tag, {
            WS => [0, [ \'MAPSTART' ] ],
        }],
    },
    FULL_MAPKEY => {
        ANCHOR => [\&cb_anchor, {
            WS => [0, {
                TAG => [\&cb_tag, {
                    WS => [0, [ \'MAPKEY' ] ],
                }],
                DEFAULT => [0, [ \'MAPKEY' ]],
            }],
        }],
        TAG => [\&cb_tag, {
            WS => [0, {
                ANCHOR => [\&cb_anchor, {
                    WS => [0, [ \'MAPKEY' ] ],
                }],
                DEFAULT => [0, [ \'MAPKEY' ]],
            }],
        }],
        DEFAULT => [0, [ \'MAPKEY' ]],
    },
    PROP_MAPKEY => {
        ANCHOR => [\&cb_anchor, {
            WS => [0, {
                TAG => [\&cb_tag, {
                    WS => [0, [ \'MAPSTART' ] ],
                }],
                DEFAULT => [0, [ \'MAPSTART' ]],
            }],
        }],
        TAG => [\&cb_tag, {
            WS => [0, {
                ANCHOR => [\&cb_anchor, {
                    WS => [0, [ \'MAPSTART' ] ],
                }],
                DEFAULT => [0, [ \'MAPSTART' ]],
            }],
        }],
    },

    FULLNODE_ANCHOR => {
        TAG => [\&cb_tag, {
            EOL => [\&cb_property_eol, [ \'TYPE_FULLNODE_TAG_ANCHOR' ]],
            WS => [0, [
                \'ANCHOR_MAPKEY',
                # SCALAR
                \'NODE',
            ]],
        }],
        ANCHOR => [\&cb_anchor, {
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
        ANCHOR => [\&cb_anchor, {
            EOL => [\&cb_property_eol, [ \'TYPE_FULLNODE_TAG_ANCHOR' ]],
            WS => [0, [
                \'TAG_MAPKEY',
                # SCALAR
                \'NODE',
            ]],
        }],
        TAG => [\&cb_tag, {
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
        ANCHOR => [\&cb_anchor, {
            EOL => [\&cb_property_eol, [
                \'TYPE_FULLNODE_ANCHOR',
            ]],
            WS => [0, {
                TAG => [\&cb_tag, {
                    EOL => [\&cb_property_eol, [
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
        TAG => [\&cb_tag, {
            EOL => [\&cb_property_eol, [ \'TYPE_FULLNODE_TAG' ]],
            WS => [0, {
                ANCHOR => [\&cb_anchor, {
                    EOL => [\&cb_property_eol, [
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

sub cb_empty_mapkey {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ value => undef, {
        style => ':',
        value => undef,
    }];
}

sub cb_mapkeystart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ value => undef, {
            style => ':',
            value => $self->tokens->[-1]->[1],
        }];
    $res->{name} = 'MAPSTART';
}

sub cb_doublequoted_key {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    my $value = $self->tokens->[-1]->[1];
    push @{ $self->stack->{events} }, [ value => undef, {
        style => '"',
        value => [ $value ],
    }];
}

sub cb_doublequotedstart {
    my ($self, $res) = @_;
    my $value = $self->tokens->[-1]->[1];
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ value => undef, {
            style => '"',
            value => [ $value ],
        }];
    $res->{name} = 'MAPSTART';
}

sub cb_singlequoted_key {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ value => undef, {
        style => "'",
        value => [ $self->tokens->[-1]->[1] ],
    }];
}

sub cb_singleequotedstart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ value => undef, {
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

sub cb_alias_key_from_stack {
    my ($self, $res) = @_;
    my $stack = delete $self->stack->{res};
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ alias => undef, {
            alias => $stack->{alias},
        }];
    # TODO
    $res->{name} = 'MAPKEY';
}

sub cb_alias_from_stack {
    my ($self, $res) = @_;
    my $stack = delete $self->stack->{res};
    push @{ $self->stack->{events} }, [ alias => undef, {
        alias => $stack->{alias},
    }];
    # TODO
    $res->{name} = 'SCALAR';
    $res->{eol} = 1;
}

sub cb_stack_alias {
    my ($self, $res) = @_;
    my $alias = $self->tokens->[-1]->[1];
    $alias = substr($alias, 1);
    $self->stack->{res} ||= {
        alias => $alias,
    };
}

sub cb_stack_singlequoted_single {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => "'",
        value => [$self->tokens->[-1]->[1]],
    };
}

sub cb_stack_singlequoted {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => "'",
        value => [],
    };
    push @{ $self->stack->{res}->{value} }, $self->tokens->[-1]->[1];
}

sub cb_stack_doublequoted_single {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => '"',
        value => [$self->tokens->[-1]->[1]],
    };
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
    my $t = $self->tokens->[-1];
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
    my $stack = $self->stack->{res} || { style => ':', value => undef };
    undef $self->stack->{res};
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ value => undef, {
            %$stack,
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
    my $first = $stack->{res}->{value}->[0];
    $res->{eol} = delete $multi->{eol};
    unshift @{ $multi->{value} }, $first;
    push @{ $stack->{events} }, [ value => undef, {
        %$multi,
    }];
    undef $stack->{res};
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

1;
