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
  'FULLMAPVALUE_INLINE' => {
    'ANCHOR' => {
      'EOL' => {
        'match' => 'cb_property_eol',
        'new' => 'FULLNODE_ANCHOR',
        'return' => 1
      },
      'WS' => {
        'DEFAULT' => {
          'new' => 'NODETYPE_MAPVALUE_INLINE'
        },
        'TAG' => {
          'EOL' => {
            'match' => 'cb_property_eol',
            'new' => 'FULLNODE_TAG_ANCHOR',
            'return' => 1
          },
          'WS' => {
            'new' => 'NODETYPE_MAPVALUE_INLINE'
          },
          'match' => 'cb_tag'
        }
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'NODETYPE_MAPVALUE_INLINE'
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
            'new' => 'NODETYPE_MAPVALUE_INLINE'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_MAPVALUE_INLINE'
        }
      },
      'match' => 'cb_tag'
    }
  },
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
      'new' => 'NODETYPE_NODE'
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
          'new' => 'NODETYPE_NODE'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_NODE'
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
            'new' => 'NODETYPE_NODE'
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
  'FULLNODE_TAG_ANCHOR' => {
    'ANCHOR' => {
      'WS' => {
        'DEFAULT' => {
          'new' => 'NODETYPE_NODE'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_NODE'
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
  'MULTILINE_DOUBLEQUOTED' => {
    'DOUBLEQUOTED_LINE' => {
      'DOUBLEQUOTE' => {
        'EOL' => {
          'match' => 'cb_got_scalar',
          'return' => 1
        }
      },
      'EOL' => {
        'match' => 'cb_fetch_tokens_quoted',
        'new' => 'MULTILINE_DOUBLEQUOTED'
      },
      'match' => 'cb_take'
    },
    'EOL' => {
      'match' => 'cb_empty_quoted_line',
      'new' => 'MULTILINE_DOUBLEQUOTED'
    }
  },
  'MULTILINE_SINGLEQUOTED' => {
    'EOL' => {
      'match' => 'cb_empty_quoted_line',
      'new' => 'MULTILINE_SINGLEQUOTED'
    },
    'SINGLEQUOTED_LINE' => {
      'EOL' => {
        'match' => 'cb_fetch_tokens_quoted',
        'new' => 'MULTILINE_SINGLEQUOTED'
      },
      'SINGLEQUOTE' => {
        'EOL' => {
          'match' => 'cb_got_scalar',
          'return' => 1
        }
      },
      'match' => 'cb_take'
    }
  },
  'NODETYPE_COMPLEX' => {
    'COLON' => {
      'EOL' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'node' => 'FULLNODE',
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
          'node' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'node' => 'FULLNODE',
          'return' => 1
        },
        'match' => 'cb_question'
      },
      'match' => 'cb_empty_complexvalue'
    }
  },
  'NODETYPE_MAP' => {
    'ANCHOR' => {
      'WS' => {
        'DEFAULT' => {
          'new' => 'RULE_MAPKEY'
        },
        'TAG' => {
          'WS' => {
            'new' => 'RULE_MAPKEY'
          },
          'match' => 'cb_tag'
        }
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'RULE_MAPKEY'
    },
    'TAG' => {
      'WS' => {
        'ANCHOR' => {
          'WS' => {
            'new' => 'RULE_MAPKEY'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'RULE_MAPKEY'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'NODETYPE_MAPVALUE_INLINE' => {
    'ALIAS' => {
      'EOL' => {
        'match' => 'cb_got_scalar',
        'return' => 1
      },
      'match' => 'cb_start_alias'
    },
    'DOUBLEQUOTE' => {
      'DOUBLEQUOTED' => {
        'DOUBLEQUOTE' => {
          'EOL' => {
            'match' => 'cb_got_scalar',
            'return' => 1
          },
          'WS' => {
            'match' => 'cb_got_scalar'
          }
        },
        'match' => 'cb_take'
      },
      'DOUBLEQUOTED_LINE' => {
        'EOL' => {
          'match' => 'cb_fetch_tokens_quoted',
          'new' => 'MULTILINE_DOUBLEQUOTED'
        },
        'match' => 'cb_take'
      },
      'match' => 'cb_start_quoted'
    },
    'FOLDED' => {
      'match' => 'cb_block_scalar',
      'new' => 'RULE_BLOCK_SCALAR_HEADER'
    },
    'LITERAL' => {
      'match' => 'cb_block_scalar',
      'new' => 'RULE_BLOCK_SCALAR_HEADER'
    },
    'PLAIN' => {
      'COMMENT' => {
        'EOL' => {
          'return' => 1
        },
        'match' => 'cb_got_scalar'
      },
      'EOL' => {
        'match' => 'cb_fetch_tokens_plain',
        'new' => 'RULE_PLAIN_MULTI'
      },
      'match' => 'cb_start_plain'
    },
    'SINGLEQUOTE' => {
      'SINGLEQUOTED' => {
        'SINGLEQUOTE' => {
          'EOL' => {
            'match' => 'cb_got_scalar',
            'return' => 1
          }
        },
        'match' => 'cb_take'
      },
      'SINGLEQUOTED_LINE' => {
        'EOL' => {
          'match' => 'cb_fetch_tokens_quoted',
          'new' => 'MULTILINE_SINGLEQUOTED'
        },
        'match' => 'cb_take'
      },
      'match' => 'cb_start_quoted'
    }
  },
  'NODETYPE_SEQ' => {
    'DASH' => {
      'EOL' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'node' => 'FULLNODE',
        'return' => 1
      }
    }
  },
  'RULE_ALIAS_KEY_OR_NODE' => {
    'ALIAS' => {
      'EOL' => {
        'match' => 'cb_got_scalar',
        'return' => 1
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'node' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'node' => 'FULLMAPVALUE_INLINE',
            'return' => 1
          },
          'match' => 'cb_insert_map'
        }
      },
      'match' => 'cb_start_alias'
    }
  },
  'RULE_BLOCK_SCALAR' => {
    'FOLDED' => {
      'match' => 'cb_block_scalar',
      'new' => 'RULE_BLOCK_SCALAR_HEADER'
    },
    'LITERAL' => {
      'match' => 'cb_block_scalar',
      'new' => 'RULE_BLOCK_SCALAR_HEADER'
    }
  },
  'RULE_BLOCK_SCALAR_CONTENT' => {
    'END' => {
      'return' => 1
    },
    'EOL' => {
      'match' => 'cb_block_scalar_empty_line',
      'new' => 'RULE_BLOCK_SCALAR_CONTENT'
    },
    'INDENT' => {
      'BLOCK_SCALAR_CONTENT' => {
        'EOL' => {
          'match' => 'cb_fetch_tokens_block_scalar',
          'new' => 'RULE_BLOCK_SCALAR_CONTENT'
        },
        'match' => 'cb_block_scalar_content'
      },
      'EOL' => {
        'match' => 'cb_block_scalar_empty_line',
        'new' => 'RULE_BLOCK_SCALAR_CONTENT'
      }
    }
  },
  'RULE_BLOCK_SCALAR_HEADER' => {
    'BLOCK_SCALAR_CHOMP' => {
      'BLOCK_SCALAR_INDENT' => {
        'EOL' => {
          'match' => 'cb_fetch_tokens_block_scalar',
          'new' => 'RULE_BLOCK_SCALAR_START'
        },
        'match' => 'cb_add_block_scalar_indent'
      },
      'EOL' => {
        'match' => 'cb_fetch_tokens_block_scalar',
        'new' => 'RULE_BLOCK_SCALAR_START'
      },
      'match' => 'cb_add_block_scalar_chomp'
    },
    'BLOCK_SCALAR_INDENT' => {
      'BLOCK_SCALAR_CHOMP' => {
        'EOL' => {
          'match' => 'cb_fetch_tokens_block_scalar',
          'new' => 'RULE_BLOCK_SCALAR_START'
        },
        'match' => 'cb_add_block_scalar_chomp'
      },
      'EOL' => {
        'match' => 'cb_fetch_tokens_block_scalar',
        'new' => 'RULE_BLOCK_SCALAR_START'
      },
      'match' => 'cb_add_block_scalar_indent'
    },
    'EOL' => {
      'match' => 'cb_fetch_tokens_block_scalar',
      'new' => 'RULE_BLOCK_SCALAR_START'
    }
  },
  'RULE_BLOCK_SCALAR_START' => {
    'END' => {
      'return' => 1
    },
    'EOL' => {
      'match' => 'cb_block_scalar_empty_line',
      'new' => 'RULE_BLOCK_SCALAR_START'
    },
    'INDENT' => {
      'BLOCK_SCALAR_CONTENT' => {
        'EOL' => {
          'match' => 'cb_fetch_tokens_block_scalar',
          'new' => 'RULE_BLOCK_SCALAR_CONTENT'
        },
        'match' => 'cb_block_scalar_start_content'
      },
      'EOL' => {
        'match' => 'cb_block_scalar_empty_line',
        'new' => 'RULE_BLOCK_SCALAR_START'
      },
      'match' => 'cb_block_scalar_start_indent'
    }
  },
  'RULE_COMPLEX' => {
    'QUESTION' => {
      'EOL' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'match' => 'cb_questionstart'
    }
  },
  'RULE_DOUBLEQUOTED_KEY_OR_NODE' => {
    'DOUBLEQUOTE' => {
      'DOUBLEQUOTED' => {
        'DOUBLEQUOTE' => {
          'COLON' => {
            'EOL' => {
              'node' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'node' => 'FULLMAPVALUE_INLINE',
              'return' => 1
            },
            'match' => 'cb_insert_map'
          },
          'EOL' => {
            'match' => 'cb_got_scalar',
            'return' => 1
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'node' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'node' => 'FULLMAPVALUE_INLINE',
                'return' => 1
              },
              'match' => 'cb_insert_map'
            },
            'match' => 'cb_got_scalar'
          }
        },
        'match' => 'cb_take'
      },
      'DOUBLEQUOTED_LINE' => {
        'EOL' => {
          'match' => 'cb_fetch_tokens_quoted',
          'new' => 'MULTILINE_DOUBLEQUOTED'
        },
        'match' => 'cb_take'
      },
      'match' => 'cb_start_quoted'
    }
  },
  'RULE_MAPKEY' => {
    'ALIAS' => {
      'WS' => {
        'COLON' => {
          'EOL' => {
            'node' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'node' => 'FULLMAPVALUE_INLINE',
            'return' => 1
          }
        }
      },
      'match' => 'cb_mapkey_alias'
    },
    'COLON' => {
      'EOL' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'node' => 'FULLMAPVALUE_INLINE',
        'return' => 1
      },
      'match' => 'cb_empty_mapkey'
    },
    'DOUBLEQUOTE' => {
      'DOUBLEQUOTED' => {
        'DOUBLEQUOTE' => {
          'COLON' => {
            'EOL' => {
              'node' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'node' => 'FULLMAPVALUE_INLINE',
              'return' => 1
            }
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'node' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'node' => 'FULLMAPVALUE_INLINE',
                'return' => 1
              }
            }
          }
        },
        'match' => 'cb_doublequoted_key'
      }
    },
    'PLAIN' => {
      'COLON' => {
        'EOL' => {
          'node' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'node' => 'FULLMAPVALUE_INLINE',
          'return' => 1
        }
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'node' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'node' => 'FULLMAPVALUE_INLINE',
            'return' => 1
          }
        }
      },
      'match' => 'cb_mapkey'
    },
    'QUESTION' => {
      'EOL' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'match' => 'cb_question'
    },
    'SINGLEQUOTE' => {
      'SINGLEQUOTED' => {
        'SINGLEQUOTE' => {
          'COLON' => {
            'EOL' => {
              'node' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'node' => 'FULLMAPVALUE_INLINE',
              'return' => 1
            }
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'node' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'node' => 'FULLMAPVALUE_INLINE',
                'return' => 1
              }
            }
          }
        },
        'match' => 'cb_singlequoted_key'
      }
    }
  },
  'RULE_PLAIN' => {
    'PLAIN' => {
      'COMMENT' => {
        'EOL' => {
          'return' => 1
        },
        'match' => 'cb_got_scalar'
      },
      'EOL' => {
        'match' => 'cb_fetch_tokens_plain',
        'new' => 'RULE_PLAIN_MULTI'
      },
      'match' => 'cb_start_plain'
    }
  },
  'RULE_PLAIN_KEY_OR_NODE' => {
    'COLON' => {
      'EOL' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'node' => 'FULLMAPVALUE_INLINE',
        'return' => 1
      },
      'match' => 'cb_insert_map'
    },
    'PLAIN' => {
      'COLON' => {
        'EOL' => {
          'node' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'node' => 'FULLMAPVALUE_INLINE',
          'return' => 1
        },
        'match' => 'cb_insert_map'
      },
      'COMMENT' => {
        'EOL' => {
          'return' => 1
        },
        'match' => 'cb_got_scalar'
      },
      'EOL' => {
        'match' => 'cb_fetch_tokens_plain',
        'new' => 'RULE_PLAIN_MULTI'
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'node' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'node' => 'FULLMAPVALUE_INLINE',
            'return' => 1
          },
          'match' => 'cb_insert_map'
        }
      },
      'match' => 'cb_start_plain'
    }
  },
  'RULE_PLAIN_MULTI' => {
    'END' => {
      'return' => 1
    },
    'EOL' => {
      'match' => 'cb_empty_plain',
      'new' => 'RULE_PLAIN_MULTI'
    },
    'INDENT' => {
      'WS' => {
        'PLAIN' => {
          'COMMENT' => {
            'EOL' => {
              'return' => 1
            }
          },
          'EOL' => {
            'match' => 'cb_fetch_tokens_plain',
            'new' => 'RULE_PLAIN_MULTI'
          },
          'match' => 'cb_take'
        }
      }
    },
    'WS' => {
      'PLAIN' => {
        'COMMENT' => {
          'EOL' => {
            'return' => 1
          }
        },
        'EOL' => {
          'match' => 'cb_fetch_tokens_plain',
          'new' => 'RULE_PLAIN_MULTI'
        },
        'match' => 'cb_take'
      }
    }
  },
  'RULE_SEQSTART' => {
    'DASH' => {
      'EOL' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'match' => 'cb_seqstart'
    }
  },
  'RULE_SINGLEQUOTED_KEY_OR_NODE' => {
    'SINGLEQUOTE' => {
      'SINGLEQUOTED' => {
        'SINGLEQUOTE' => {
          'COLON' => {
            'EOL' => {
              'node' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'node' => 'FULLMAPVALUE_INLINE',
              'return' => 1
            },
            'match' => 'cb_insert_map'
          },
          'EOL' => {
            'match' => 'cb_got_scalar',
            'return' => 1
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'node' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'node' => 'FULLMAPVALUE_INLINE',
                'return' => 1
              },
              'match' => 'cb_insert_map'
            }
          }
        },
        'match' => 'cb_take'
      },
      'SINGLEQUOTED_LINE' => {
        'EOL' => {
          'match' => 'cb_fetch_tokens_quoted',
          'new' => 'MULTILINE_SINGLEQUOTED'
        },
        'match' => 'cb_take'
      },
      'match' => 'cb_start_quoted'
    }
  }
};


# END OF GRAMMAR INLINE


my %TYPE2RULE = (
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
        match: cb_start_alias
        EOL: { match: cb_got_scalar, return: 1 }
        WS:
          COLON:
            match: cb_insert_map
            EOL: { node: FULLNODE, return: 1 }
            WS: { node: FULLMAPVALUE_INLINE, return: 1 }
    
    RULE_COMPLEX:
      QUESTION:
        match: cb_questionstart
        EOL: { node: FULLNODE, return: 1 }
        WS: { node: FULLNODE, return: 1 }
    
    NODETYPE_COMPLEX:
      COLON:
        match: cb_complexcolon
        EOL: { node: FULLNODE, return: 1 }
        WS: { node: FULLNODE, return: 1 }
      DEFAULT:
        match: cb_empty_complexvalue
        QUESTION:
          match: cb_question
          EOL: { node: FULLNODE, return: 1 }
          WS: { node: FULLNODE, return: 1 }
        DEFAULT: { new: NODETYPE_MAP }
    
    RULE_SINGLEQUOTED_KEY_OR_NODE:
      SINGLEQUOTE:
        match: cb_start_quoted
        SINGLEQUOTED:
          match: cb_take
          SINGLEQUOTE:
            EOL: { match: cb_got_scalar, return: 1 }
            COLON:
              match: cb_insert_map
              EOL: { node: FULLNODE, return: 1 }
              WS: { node: FULLMAPVALUE_INLINE, return: 1 }
            WS:
              COLON:
                match: cb_insert_map
                EOL: { node: FULLNODE, return: 1 }
                WS: { node: FULLMAPVALUE_INLINE, return: 1 }
        SINGLEQUOTED_LINE:
          match: cb_take
          EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_SINGLEQUOTED }
    
    MULTILINE_SINGLEQUOTED:
      SINGLEQUOTED_LINE:
        match: cb_take
        EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_SINGLEQUOTED }
        SINGLEQUOTE:
          EOL: { match: cb_got_scalar, return: 1 }
      EOL: { match: cb_empty_quoted_line, new: MULTILINE_SINGLEQUOTED }
    
    RULE_DOUBLEQUOTED_KEY_OR_NODE:
      DOUBLEQUOTE:
        match: cb_start_quoted
        DOUBLEQUOTED:
          match: cb_take
          DOUBLEQUOTE:
            EOL: { match: cb_got_scalar, return: 1 }
            WS:
              match: cb_got_scalar
              COLON:
                match: cb_insert_map
                EOL: { node: FULLNODE , return: 1}
                WS: { node: FULLMAPVALUE_INLINE, return: 1 }
            COLON:
              match: cb_insert_map
              EOL: { node: FULLNODE , return: 1}
              WS: { node: FULLMAPVALUE_INLINE, return: 1 }
        DOUBLEQUOTED_LINE:
          match: cb_take
          EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_DOUBLEQUOTED  }
    
    MULTILINE_DOUBLEQUOTED:
      DOUBLEQUOTED_LINE:
        match: cb_take
        EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_DOUBLEQUOTED  }
        DOUBLEQUOTE:
          EOL: { match: cb_got_scalar, return: 1 }
      EOL: { match: cb_empty_quoted_line, new: MULTILINE_DOUBLEQUOTED }
    
    RULE_PLAIN_KEY_OR_NODE:
      PLAIN:
        match: cb_start_plain
        COMMENT:
          match: cb_got_scalar
          EOL: { return: 1 }
        EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI }
        WS:
          COLON:
            match: cb_insert_map
            EOL: { node: FULLNODE , return: 1}
            WS: { node: FULLMAPVALUE_INLINE, return: 1 }
        COLON:
          match: cb_insert_map
          EOL: { node: FULLNODE , return: 1}
          WS: { node: FULLMAPVALUE_INLINE, return: 1 }
      COLON:
        match: cb_insert_map
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLMAPVALUE_INLINE, return: 1 }
    
    RULE_PLAIN:
      PLAIN:
        match: cb_start_plain
        COMMENT:
          match: cb_got_scalar
          EOL: { return: 1 }
        EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI }
    
    RULE_PLAIN_MULTI:
      END: { return: 1 }
      EOL: { match: cb_empty_plain, new: RULE_PLAIN_MULTI }
      WS:
        PLAIN:
          match: cb_take
          EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI }
          COMMENT:
            EOL: { return: 1 }
      INDENT:
        WS:
          PLAIN:
            match: cb_take
            EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI }
            COMMENT:
              EOL: { return: 1 }
    
    
    RULE_MAPKEY:
      QUESTION:
        match: cb_question
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLNODE , return: 1}
      ALIAS:
        match: cb_mapkey_alias
        WS:
          COLON:
            EOL: { node: FULLNODE , return: 1}
            WS: { node: FULLMAPVALUE_INLINE, return: 1 }
      DOUBLEQUOTE:
        DOUBLEQUOTED:
          match: cb_doublequoted_key
          DOUBLEQUOTE:
            WS:
              COLON:
                EOL: { node: FULLNODE , return: 1}
                WS: { node: FULLMAPVALUE_INLINE, return: 1 }
            COLON:
              EOL: { node: FULLNODE , return: 1}
              WS: { node: FULLMAPVALUE_INLINE, return: 1 }
      SINGLEQUOTE:
        SINGLEQUOTED:
          match: cb_singlequoted_key
          SINGLEQUOTE:
            WS:
              COLON:
                EOL: { node: FULLNODE , return: 1}
                WS: { node: FULLMAPVALUE_INLINE, return: 1 }
            COLON:
              EOL: { node: FULLNODE , return: 1}
              WS: { node: FULLMAPVALUE_INLINE, return: 1 }
      PLAIN:
        match: cb_mapkey
        WS:
          COLON:
            EOL: { node: FULLNODE , return: 1}
            WS: { node: FULLMAPVALUE_INLINE, return: 1 }
        COLON:
          EOL: { node: FULLNODE , return: 1}
          WS: { node: FULLMAPVALUE_INLINE, return: 1 }
      COLON:
        match: cb_empty_mapkey
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLMAPVALUE_INLINE, return: 1 }
    
    RULE_SEQSTART:
      DASH:
        match: cb_seqstart
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLNODE , return: 1}
    
    NODETYPE_SEQ:
      DASH:
    #    match: cb_seqitem
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLNODE , return: 1}
    
    RULE_BLOCK_SCALAR:
      LITERAL:
        match: cb_block_scalar
        new: RULE_BLOCK_SCALAR_HEADER
      FOLDED:
        match: cb_block_scalar
        new: RULE_BLOCK_SCALAR_HEADER
    
    RULE_BLOCK_SCALAR_HEADER:
      BLOCK_SCALAR_INDENT:
        match: cb_add_block_scalar_indent
        BLOCK_SCALAR_CHOMP:
          match: cb_add_block_scalar_chomp
          EOL:
            match: cb_fetch_tokens_block_scalar
            new: RULE_BLOCK_SCALAR_START
        EOL:
          match: cb_fetch_tokens_block_scalar
          new: RULE_BLOCK_SCALAR_START
      BLOCK_SCALAR_CHOMP:
        match: cb_add_block_scalar_chomp
        BLOCK_SCALAR_INDENT:
          match: cb_add_block_scalar_indent
          EOL:
            match: cb_fetch_tokens_block_scalar
            new: RULE_BLOCK_SCALAR_START
        EOL:
          match: cb_fetch_tokens_block_scalar
          new: RULE_BLOCK_SCALAR_START
      EOL:
        match: cb_fetch_tokens_block_scalar
        new: RULE_BLOCK_SCALAR_START
    
    RULE_BLOCK_SCALAR_START:
      EOL: { match: cb_block_scalar_empty_line, new: RULE_BLOCK_SCALAR_START }
      INDENT:
        match: cb_block_scalar_start_indent
        EOL: { match: cb_block_scalar_empty_line, new: RULE_BLOCK_SCALAR_START }
        BLOCK_SCALAR_CONTENT:
          match: cb_block_scalar_start_content
          EOL: { match: cb_fetch_tokens_block_scalar, new: RULE_BLOCK_SCALAR_CONTENT }
      END: { return: 1 }
    
    RULE_BLOCK_SCALAR_CONTENT:
      EOL: { match: cb_block_scalar_empty_line, new: RULE_BLOCK_SCALAR_CONTENT }
      INDENT:
        EOL: { match: cb_block_scalar_empty_line, new: RULE_BLOCK_SCALAR_CONTENT }
        BLOCK_SCALAR_CONTENT:
          match: cb_block_scalar_content
          EOL: { match: cb_fetch_tokens_block_scalar, new: RULE_BLOCK_SCALAR_CONTENT }
      END: { return: 1 }
    
    NODETYPE_MAP:
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: RULE_MAPKEY  }
          DEFAULT: { new: RULE_MAPKEY }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: RULE_MAPKEY  }
          DEFAULT: { new: RULE_MAPKEY }
      DEFAULT: { new: RULE_MAPKEY }
    
    FULLNODE_ANCHOR:
      TAG:
        match: cb_tag
        EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_NODE  }
          DEFAULT: { new: NODETYPE_NODE }
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_NODE  }
          DEFAULT: { new: NODETYPE_NODE }
      DEFAULT: { new: NODETYPE_NODE }
    
    FULLNODE_TAG:
      ANCHOR:
        match: cb_anchor
        EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_NODE  }
          DEFAULT: { new: NODETYPE_NODE, }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_NODE  }
          DEFAULT: { new: NODETYPE_NODE }
      DEFAULT: { new: NODETYPE_NODE }
    
    FULLNODE_TAG_ANCHOR:
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_NODE  }
          DEFAULT: { new: NODETYPE_NODE }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_NODE  }
          DEFAULT: { new: NODETYPE_NODE }
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
      DEFAULT: { new: NODETYPE_NODE }
    
    FULLMAPVALUE_INLINE:
      ANCHOR:
        match: cb_anchor
        EOL: { match: cb_property_eol, new: FULLNODE_ANCHOR , return: 1}
        WS:
          TAG:
            match: cb_tag
            EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
            WS: { new: NODETYPE_MAPVALUE_INLINE  }
          DEFAULT: { new: NODETYPE_MAPVALUE_INLINE }
      TAG:
        match: cb_tag
        EOL: { match: cb_property_eol, new: FULLNODE_TAG , return: 1}
        WS:
          ANCHOR:
            match: cb_anchor
            EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
            WS: { new: NODETYPE_MAPVALUE_INLINE  }
          DEFAULT: { new: NODETYPE_MAPVALUE_INLINE }
      DEFAULT: { new: NODETYPE_MAPVALUE_INLINE }
    
    
    NODETYPE_MAPVALUE_INLINE:
      ALIAS:
        match: cb_start_alias
        EOL: { match: cb_got_scalar, return: 1 }
    
      SINGLEQUOTE:
        match: cb_start_quoted
        SINGLEQUOTED:
          match: cb_take
          SINGLEQUOTE:
            EOL: { match: cb_got_scalar, return: 1 }
        SINGLEQUOTED_LINE:
          match: cb_take
          EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_SINGLEQUOTED }
    
      DOUBLEQUOTE:
        match: cb_start_quoted
        DOUBLEQUOTED:
          match: cb_take
          DOUBLEQUOTE:
            EOL: { match: cb_got_scalar, return: 1 }
            WS:
              match: cb_got_scalar
        DOUBLEQUOTED_LINE:
          match: cb_take
          EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_DOUBLEQUOTED  }
    
      PLAIN:
        match: cb_start_plain
        COMMENT:
          match: cb_got_scalar
          EOL: { return: 1 }
        EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI }
    
      LITERAL:
        match: cb_block_scalar
        new: RULE_BLOCK_SCALAR_HEADER
      FOLDED:
        match: cb_block_scalar
        new: RULE_BLOCK_SCALAR_HEADER
    


    # END OF YAML INLINE

=cut
