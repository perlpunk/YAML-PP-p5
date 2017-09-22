use strict;
use warnings;
package YAML::PP::Grammar;

our $VERSION = '0.000'; # VERSION

use base 'Exporter';

our @EXPORT_OK = qw/ $GRAMMAR /;

our $GRAMMAR = {};

# START OF GRAMMAR INLINE

# DO NOT CHANGE THIS
# This grammar is automatically generated from etc/grammar.yaml

$GRAMMAR = {
  'FULLNODE' => {
    'ANCHOR' => {
      'EOL' => {
        'match' => 'cb_property_eol',
        'new' => 'FULLNODE_ANCHOR',
        'return' => 1
      },
      'WS' => {
        'DEFAULT' => {
          'new' => 'NODETYPE_NODE'
        },
        'TAG' => {
          'EOL' => {
            'match' => 'cb_property_eol',
            'new' => 'FULLNODE_TAG_ANCHOR',
            'return' => 1
          },
          'WS' => {
            'new' => 'NODETYPE_NODE'
          },
          'match' => 'cb_tag'
        }
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'PREVIOUS'
    },
    'TAG' => {
      'EOL' => {
        'match' => 'cb_property_eol',
        'new' => 'FULLNODE_TAG',
        'return' => 1
      },
      'WS' => {
        'ANCHOR' => {
          'EOL' => {
            'match' => 'cb_property_eol',
            'new' => 'FULLNODE_TAG_ANCHOR',
            'return' => 1
          },
          'WS' => {
            'new' => 'NODETYPE_NODE'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_NODE'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'FULLNODE_ANCHOR' => {
    'ANCHOR' => {
      'WS' => {
        'DEFAULT' => {
          'new' => 'NODETYPE_MAPSTART'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_MAPSTART'
          },
          'match' => 'cb_tag'
        }
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'NODETYPE_NODE'
    },
    'TAG' => {
      'EOL' => {
        'match' => 'cb_property_eol',
        'new' => 'FULLNODE_TAG_ANCHOR',
        'return' => 1
      },
      'WS' => {
        'ANCHOR' => {
          'WS' => {
            'new' => 'NODETYPE_MAPSTART'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_NODE'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'FULLNODE_TAG' => {
    'ANCHOR' => {
      'EOL' => {
        'match' => 'cb_property_eol',
        'new' => 'FULLNODE_TAG_ANCHOR',
        'return' => 1
      },
      'WS' => {
        'DEFAULT' => {
          'new' => 'NODETYPE_NODE'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_MAPSTART'
          },
          'match' => 'cb_tag'
        }
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'NODETYPE_NODE'
    },
    'TAG' => {
      'WS' => {
        'ANCHOR' => {
          'WS' => {
            'new' => 'NODETYPE_MAPSTART'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_MAPSTART'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'FULLNODE_TAG_ANCHOR' => {
    'ANCHOR' => {
      'WS' => {
        'DEFAULT' => {
          'new' => 'NODETYPE_MAPSTART'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_MAPSTART'
          },
          'match' => 'cb_tag'
        }
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'NODETYPE_NODE'
    },
    'TAG' => {
      'WS' => {
        'ANCHOR' => {
          'WS' => {
            'new' => 'NODETYPE_MAPSTART'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_MAPSTART'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'FULL_MAPKEY' => {
    'ANCHOR' => {
      'WS' => {
        'DEFAULT' => {
          'new' => 'NODETYPE_MAPKEY'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_MAPKEY'
          },
          'match' => 'cb_tag'
        }
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'NODETYPE_MAPKEY'
    },
    'TAG' => {
      'WS' => {
        'ANCHOR' => {
          'WS' => {
            'new' => 'NODETYPE_MAPKEY'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_MAPKEY'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'MULTILINE_DOUBLEQUOTED' => {
    'DOUBLEQUOTED_END' => {
      'DOUBLEQUOTE' => {
        'EOL' => {
          'match' => 'cb_scalar_from_stack',
          'new' => 'NODE'
        }
      },
      'match' => 'cb_stack_doublequoted'
    },
    'DOUBLEQUOTED_LINE' => {
      'LB' => {
        'new' => 'MULTILINE_DOUBLEQUOTED'
      },
      'match' => 'cb_stack_doublequoted'
    }
  },
  'MULTILINE_SINGLEQUOTED' => {
    'SINGLEQUOTED_END' => {
      'SINGLEQUOTE' => {
        'EOL' => {
          'match' => 'cb_scalar_from_stack',
          'new' => 'NODE'
        }
      },
      'match' => 'cb_stack_singlequoted'
    },
    'SINGLEQUOTED_LINE' => {
      'LB' => {
        'new' => 'MULTILINE_SINGLEQUOTED'
      },
      'match' => 'cb_stack_singlequoted'
    }
  },
  'NODETYPE_COMPLEX' => {
    'COLON' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'match' => 'cb_complexcolon'
    },
    'DEFAULT' => {
      'DEFAULT' => {
        'new' => 'NODETYPE_MAP'
      },
      'QUESTION' => {
        'EOL' => {
          'new' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'new' => 'FULLNODE',
          'return' => 1
        },
        'match' => 'cb_question'
      },
      'match' => 'cb_empty_complexvalue'
    }
  },
  'NODETYPE_MAP' => {
    'ALIAS' => {
      'WS' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'MAPVALUE'
          }
        }
      },
      'match' => 'cb_mapkey_alias'
    },
    'COLON' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'MAPVALUE'
      },
      'match' => 'cb_empty_mapkey'
    },
    'DOUBLEQUOTE' => {
      'DOUBLEQUOTED_SINGLE' => {
        'DOUBLEQUOTE' => {
          'WS?' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'MAPVALUE'
              }
            }
          }
        },
        'match' => 'cb_doublequoted_key'
      }
    },
    'QUESTION' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'match' => 'cb_question'
    },
    'SCALAR' => {
      'WS?' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'MAPVALUE'
          }
        }
      },
      'match' => 'cb_mapkey'
    },
    'SINGLEQUOTE' => {
      'SINGLEQUOTED_SINGLE' => {
        'SINGLEQUOTE' => {
          'WS?' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'MAPVALUE'
              }
            }
          }
        },
        'match' => 'cb_singlequoted_key'
      }
    }
  },
  'NODETYPE_MAPSTART' => {
    'DOUBLEQUOTE' => {
      'DOUBLEQUOTED' => {
        'DOUBLEQUOTE' => {
          'WS?' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'MAPVALUE'
              }
            }
          }
        },
        'match' => 'cb_doublequotedstart'
      }
    },
    'QUESTION' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'match' => 'cb_questionstart'
    },
    'SCALAR' => {
      'WS?' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'MAPVALUE'
          }
        }
      },
      'match' => 'cb_mapkeystart'
    },
    'SINGLEQUOTE' => {
      'SINGLEQUOTED' => {
        'SINGLEQUOTE' => {
          'WS?' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'MAPVALUE'
              }
            }
          }
        },
        'match' => 'cb_singleequotedstart'
      }
    }
  },
  'NODETYPE_SEQ' => {
    'DASH' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'match' => 'cb_seqitem'
    }
  },
  'RULE_ALIAS_KEY_OR_NODE' => {
    'ALIAS' => {
      'EOL' => {
        'match' => 'cb_alias_from_stack',
        'new' => 'NODE'
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'MAPVALUE'
          },
          'match' => 'cb_alias_key_from_stack'
        }
      },
      'match' => 'cb_stack_alias'
    }
  },
  'RULE_BLOCK_SCALAR' => {
    'FOLDED' => {
      'match' => 'cb_block_scalar',
      'new' => 'NODE'
    },
    'LITERAL' => {
      'match' => 'cb_block_scalar',
      'new' => 'NODE'
    }
  },
  'RULE_COMPLEX' => {
    'QUESTION' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'match' => 'cb_questionstart'
    }
  },
  'RULE_DOUBLEQUOTED_KEY_OR_NODE' => {
    'DOUBLEQUOTE' => {
      'DOUBLEQUOTED_LINE' => {
        'LB' => {
          'new' => 'MULTILINE_DOUBLEQUOTED'
        },
        'match' => 'cb_stack_doublequoted'
      },
      'DOUBLEQUOTED_SINGLE' => {
        'DOUBLEQUOTE' => {
          'EOL' => {
            'match' => 'cb_scalar_from_stack',
            'new' => 'NODE'
          },
          'WS?' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'MAPVALUE'
              },
              'match' => 'cb_mapkey_from_stack'
            },
            'DEFAULT' => {
              'match' => 'cb_scalar_from_stack',
              'new' => 'ERROR'
            }
          }
        },
        'match' => 'cb_stack_doublequoted_single'
      }
    }
  },
  'RULE_PLAIN' => {
    'SCALAR' => {
      'COMMENT_EOL' => {
        'match' => 'cb_multiscalar_from_stack',
        'new' => 'NODE'
      },
      'EOL' => {
        'match' => 'cb_multiscalar_from_stack',
        'new' => 'NODE'
      },
      'match' => 'cb_stack_plain'
    }
  },
  'RULE_PLAIN_KEY_OR_NODE' => {
    'COLON' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'MAPVALUE'
      },
      'match' => 'cb_mapkey_from_stack'
    },
    'SCALAR' => {
      'COMMENT_EOL' => {
        'match' => 'cb_plain_single',
        'new' => 'NODE'
      },
      'EOL' => {
        'match' => 'cb_multiscalar_from_stack',
        'new' => 'NODE'
      },
      'WS?' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'MAPVALUE'
          },
          'match' => 'cb_mapkey_from_stack'
        }
      },
      'match' => 'cb_stack_plain'
    }
  },
  'RULE_SEQSTART' => {
    'DASH' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'match' => 'cb_seqstart'
    }
  },
  'RULE_SINGLEQUOTED_KEY_OR_NODE' => {
    'SINGLEQUOTE' => {
      'SINGLEQUOTED_LINE' => {
        'LB' => {
          'new' => 'MULTILINE_SINGLEQUOTED'
        },
        'match' => 'cb_stack_singlequoted'
      },
      'SINGLEQUOTED_SINGLE' => {
        'SINGLEQUOTE' => {
          'EOL' => {
            'match' => 'cb_scalar_from_stack',
            'new' => 'NODE'
          },
          'WS?' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'MAPVALUE'
              },
              'match' => 'cb_mapkey_from_stack'
            }
          }
        },
        'match' => 'cb_stack_singlequoted_single'
      }
    }
  }
};


# END OF GRAMMAR INLINE


my %TYPE2RULE = (
    NODETYPE_MAPKEY => {
        %{ $GRAMMAR->{NODETYPE_MAP} },
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

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Grammar

=head1 GRAMMAR

This is the Grammar in YAML

    # START OF YAML INLINE

    # DO NOT CHANGE THIS
    # This grammar is automatically generated from etc/grammar.yaml

    ---
    RULE_ALIAS_KEY_OR_NODE:
      ALIAS:
        match: cb_stack_alias
        EOL: { match: cb_alias_from_stack, new: NODE }
        WS:
          COLON:
            match: cb_alias_key_from_stack
            EOL: { new: FULLNODE, return: 1 }
            WS: { new: MAPVALUE }
    
    RULE_COMPLEX:
      QUESTION:
        match: cb_questionstart
        EOL: { new: FULLNODE, return: 1 }
        WS: { new: FULLNODE, return: 1 }
    
    NODETYPE_COMPLEX:
      COLON:
        match: cb_complexcolon
        EOL: { new: FULLNODE, return: 1 }
        WS: { new: FULLNODE, return: 1 }
      DEFAULT:
        match: cb_empty_complexvalue
        QUESTION:
          match: cb_question
          EOL: { new: FULLNODE, return: 1 }
          WS: { new: FULLNODE, return: 1 }
        DEFAULT: { new: NODETYPE_MAP }
    
    RULE_SINGLEQUOTED_KEY_OR_NODE:
      SINGLEQUOTE:
        SINGLEQUOTED_SINGLE:
          match: cb_stack_singlequoted_single
          SINGLEQUOTE:
            EOL: { match: cb_scalar_from_stack, new: NODE }
            WS?:
              COLON:
                match: cb_mapkey_from_stack
                EOL: { new: FULLNODE, return: 1 }
                WS: { new: MAPVALUE }
        SINGLEQUOTED_LINE:
          match: cb_stack_singlequoted
          LB: { new: MULTILINE_SINGLEQUOTED }
    
    MULTILINE_SINGLEQUOTED:
      SINGLEQUOTED_END:
        match: cb_stack_singlequoted
        SINGLEQUOTE:
          EOL: { match: cb_scalar_from_stack, new: NODE }
      SINGLEQUOTED_LINE:
        match: cb_stack_singlequoted
        LB: { new: MULTILINE_SINGLEQUOTED }
    
    RULE_DOUBLEQUOTED_KEY_OR_NODE:
      DOUBLEQUOTE:
        DOUBLEQUOTED_SINGLE:
          match: cb_stack_doublequoted_single
          DOUBLEQUOTE:
            EOL: { match: cb_scalar_from_stack, new: NODE }
            WS?:
              COLON:
                match: cb_mapkey_from_stack
                EOL: { new: FULLNODE , return: 1}
                WS: { new: MAPVALUE }
              DEFAULT: { match: cb_scalar_from_stack, new: ERROR }
        DOUBLEQUOTED_LINE:
          match: cb_stack_doublequoted
          LB: { new: MULTILINE_DOUBLEQUOTED  }
    
    MULTILINE_DOUBLEQUOTED:
      DOUBLEQUOTED_END:
        match: cb_stack_doublequoted
        DOUBLEQUOTE:
          EOL: { match: cb_scalar_from_stack, new: NODE }
      DOUBLEQUOTED_LINE:
        match: cb_stack_doublequoted
        LB: { new: MULTILINE_DOUBLEQUOTED  }
    
    RULE_PLAIN_KEY_OR_NODE:
      SCALAR:
        match: cb_stack_plain
        COMMENT_EOL: { match: cb_plain_single, new: NODE }
        EOL: { match: cb_multiscalar_from_stack, new: NODE }
        WS?:
          COLON:
            match: cb_mapkey_from_stack
            EOL: { new: FULLNODE , return: 1}
            WS: { new: MAPVALUE }
      COLON:
        match: cb_mapkey_from_stack
        EOL: { new: FULLNODE , return: 1}
        WS: { new: MAPVALUE }
    
    RULE_PLAIN:
      SCALAR:
        match: cb_stack_plain
        COMMENT_EOL: { match: cb_multiscalar_from_stack, new: NODE }
        EOL: { match: cb_multiscalar_from_stack, new: NODE }
    
    NODETYPE_MAP:
      QUESTION:
        match: cb_question
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLNODE , return: 1}
      ALIAS:
        match: cb_mapkey_alias
        WS:
          COLON:
            EOL: { new: FULLNODE , return: 1}
            WS: { new: MAPVALUE }
      DOUBLEQUOTE:
        DOUBLEQUOTED_SINGLE:
          match: cb_doublequoted_key
          DOUBLEQUOTE:
            WS?:
              COLON:
                EOL: { new: FULLNODE , return: 1}
                WS: { new: MAPVALUE }
      SINGLEQUOTE:
        SINGLEQUOTED_SINGLE:
          match: cb_singlequoted_key
          SINGLEQUOTE:
            WS?:
              COLON:
                EOL: { new: FULLNODE , return: 1}
                WS: { new: MAPVALUE }
      SCALAR:
        match: cb_mapkey
        WS?:
          COLON:
            EOL: { new: FULLNODE , return: 1}
            WS: { new: MAPVALUE }
      COLON:
        match: cb_empty_mapkey
        EOL: { new: FULLNODE , return: 1}
        WS: { new: MAPVALUE }
    
    NODETYPE_MAPSTART:
      QUESTION:
        match: cb_questionstart
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLNODE , return: 1}
      DOUBLEQUOTE:
        DOUBLEQUOTED:
          match: cb_doublequotedstart
          DOUBLEQUOTE:
            WS?:
              COLON:
                EOL: { new: FULLNODE , return: 1}
                WS: { new: MAPVALUE }
      SINGLEQUOTE:
        SINGLEQUOTED:
          match: cb_singleequotedstart
          SINGLEQUOTE:
            WS?:
              COLON:
                EOL: { new: FULLNODE , return: 1}
                WS: { new: MAPVALUE }
      SCALAR:
        match: cb_mapkeystart
        WS?:
          COLON:
            EOL: { new: FULLNODE , return: 1}
            WS: { new: MAPVALUE }
    
    RULE_SEQSTART:
      DASH:
        match: cb_seqstart
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLNODE , return: 1}
    
    NODETYPE_SEQ:
      DASH:
        match: cb_seqitem
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLNODE , return: 1}
    
    RULE_BLOCK_SCALAR:
      LITERAL: { match: cb_block_scalar, new: NODE }
      FOLDED: { match: cb_block_scalar, new: NODE }
    
    FULL_MAPKEY:
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_MAPKEY  }
          DEFAULT: { new: NODETYPE_MAPKEY }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_MAPKEY  }
          DEFAULT: { new: NODETYPE_MAPKEY }
      DEFAULT: { new: NODETYPE_MAPKEY }
    
    FULLNODE_ANCHOR:
      TAG:
        match: cb_tag
        EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_MAPSTART  }
          DEFAULT: { new: NODETYPE_NODE }
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_MAPSTART  }
          DEFAULT: { new: NODETYPE_MAPSTART }
      DEFAULT: { new: NODETYPE_NODE }
    
    FULLNODE_TAG:
      ANCHOR:
        match: cb_anchor
        EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_MAPSTART  }
          DEFAULT: { new: NODETYPE_NODE, }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_MAPSTART  }
          DEFAULT: { new: NODETYPE_MAPSTART }
      DEFAULT: { new: NODETYPE_NODE }
    
    FULLNODE_TAG_ANCHOR:
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_MAPSTART  }
          DEFAULT: { new: NODETYPE_MAPSTART }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_MAPSTART  }
          DEFAULT: { new: NODETYPE_MAPSTART }
      DEFAULT: { new: NODETYPE_NODE }
    
    FULLNODE:
      ANCHOR:
        match: cb_anchor
        EOL: { match: cb_property_eol, new: FULLNODE_ANCHOR , return: 1}
        WS:
          TAG:
            match: cb_tag
            EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
            WS: { new: NODETYPE_NODE  }
          DEFAULT: { new: NODETYPE_NODE }
      TAG:
        match: cb_tag
        EOL: { match: cb_property_eol, new: FULLNODE_TAG , return: 1}
        WS:
          ANCHOR:
            match: cb_anchor
            EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
            WS: { new: NODETYPE_NODE  }
          DEFAULT: { new: NODETYPE_NODE }
      DEFAULT: { new: PREVIOUS }
    


    # END OF YAML INLINE

=cut
