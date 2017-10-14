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
          'new' => 'NODETYPE_MAP'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_MAP'
          },
          'match' => 'cb_tag'
        }
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'NODETYPE_MAP'
    },
    'TAG' => {
      'WS' => {
        'ANCHOR' => {
          'WS' => {
            'new' => 'NODETYPE_MAP'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_MAP'
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
          'new' => 'END'
        }
      },
      'EOL' => {
        'new' => 'MULTILINE_DOUBLEQUOTED'
      },
      'match' => 'cb_take'
    }
  },
  'MULTILINE_SINGLEQUOTED' => {
    'SINGLEQUOTED_LINE' => {
      'EOL' => {
        'new' => 'MULTILINE_SINGLEQUOTED'
      },
      'SINGLEQUOTE' => {
        'EOL' => {
          'match' => 'cb_got_scalar',
          'new' => 'END'
        }
      },
      'match' => 'cb_take'
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
        'new' => 'FULL_MAPKEY'
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
            'new' => 'FULLMAPVALUE',
            'return' => 1
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
        'new' => 'FULLMAPVALUE',
        'return' => 1
      },
      'match' => 'cb_empty_mapkey'
    },
    'DOUBLEQUOTE' => {
      'DOUBLEQUOTED' => {
        'DOUBLEQUOTE' => {
          'COLON' => {
            'EOL' => {
              'new' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'new' => 'FULLMAPVALUE',
              'return' => 1
            }
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'FULLMAPVALUE',
                'return' => 1
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
      'COLON' => {
        'EOL' => {
          'new' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'new' => 'FULLMAPVALUE',
          'return' => 1
        }
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'FULLMAPVALUE',
            'return' => 1
          }
        }
      },
      'match' => 'cb_mapkey'
    },
    'SINGLEQUOTE' => {
      'SINGLEQUOTED' => {
        'SINGLEQUOTE' => {
          'COLON' => {
            'EOL' => {
              'new' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'new' => 'FULLMAPVALUE',
              'return' => 1
            }
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'FULLMAPVALUE',
                'return' => 1
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
          'COLON' => {
            'EOL' => {
              'new' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'new' => 'FULLMAPVALUE',
              'return' => 1
            }
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'FULLMAPVALUE',
                'return' => 1
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
      'COLON' => {
        'EOL' => {
          'new' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'new' => 'FULLMAPVALUE',
          'return' => 1
        }
      },
      'WS' => {
        'COLON' => $GRAMMAR->{'NODETYPE_MAPSTART'}{'SCALAR'}{'COLON'}
      },
      'match' => 'cb_mapkeystart'
    },
    'SINGLEQUOTE' => {
      'SINGLEQUOTED' => {
        'SINGLEQUOTE' => {
          'COLON' => {
            'EOL' => {
              'new' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'new' => 'FULLMAPVALUE',
              'return' => 1
            }
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'FULLMAPVALUE',
                'return' => 1
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
        'match' => 'cb_got_scalar',
        'new' => 'END'
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'FULLMAPVALUE',
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
  'RULE_BLOCK_SCALAR_HEADER' => {
    'BLOCK_SCALAR_CHOMP' => {
      'BLOCK_SCALAR_INDENT' => {
        'EOL' => {
          'match' => 'cb_read_block_scalar',
          'new' => 'END'
        },
        'match' => 'cb_add_block_scalar_indent'
      },
      'EOL' => {
        'match' => 'cb_read_block_scalar',
        'new' => 'END'
      },
      'match' => 'cb_add_block_scalar_chomp'
    },
    'BLOCK_SCALAR_INDENT' => {
      'BLOCK_SCALAR_CHOMP' => {
        'EOL' => {
          'match' => 'cb_read_block_scalar',
          'new' => 'END'
        },
        'match' => 'cb_add_block_scalar_chomp'
      },
      'EOL' => {
        'match' => 'cb_read_block_scalar',
        'new' => 'END'
      },
      'match' => 'cb_add_block_scalar_indent'
    },
    'EOL' => {
      'match' => 'cb_read_block_scalar',
      'new' => 'END'
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
      'DOUBLEQUOTED' => {
        'DOUBLEQUOTE' => {
          'COLON' => {
            'EOL' => {
              'new' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'new' => 'FULLMAPVALUE',
              'return' => 1
            },
            'match' => 'cb_insert_map'
          },
          'DEFAULT' => {
            'new' => 'ERROR'
          },
          'EOL' => {
            'match' => 'cb_got_scalar',
            'new' => 'END'
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'FULLMAPVALUE',
                'return' => 1
              },
              'match' => 'cb_insert_map'
            },
            'DEFAULT' => {
              'match' => 'cb_got_scalar',
              'new' => 'ERROR'
            }
          }
        },
        'match' => 'cb_take'
      },
      'DOUBLEQUOTED_LINE' => {
        'EOL' => {
          'new' => 'MULTILINE_DOUBLEQUOTED'
        },
        'match' => 'cb_take'
      },
      'match' => 'cb_start_quoted'
    }
  },
  'RULE_PLAIN' => {
    'SCALAR' => {
      'COMMENT' => {
        'EOL' => {
          'new' => 'END'
        },
        'match' => 'cb_got_multiscalar'
      },
      'EOL' => {
        'match' => 'cb_got_multiscalar',
        'new' => 'END'
      },
      'match' => 'cb_start_plain'
    }
  },
  'RULE_PLAIN_KEY_OR_NODE' => {
    'COLON' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLMAPVALUE',
        'return' => 1
      },
      'match' => 'cb_insert_map'
    },
    'SCALAR' => {
      'COLON' => {
        'EOL' => {
          'new' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'new' => 'FULLMAPVALUE',
          'return' => 1
        },
        'match' => 'cb_insert_map'
      },
      'COMMENT' => {
        'EOL' => {
          'new' => 'END'
        },
        'match' => 'cb_got_scalar'
      },
      'EOL' => {
        'match' => 'cb_got_multiscalar',
        'new' => 'END'
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'FULLMAPVALUE',
            'return' => 1
          },
          'match' => 'cb_insert_map'
        }
      },
      'match' => 'cb_start_plain'
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
      'SINGLEQUOTED' => {
        'SINGLEQUOTE' => {
          'COLON' => {
            'EOL' => {
              'new' => 'FULLNODE',
              'return' => 1
            },
            'WS' => {
              'new' => 'FULLMAPVALUE',
              'return' => 1
            },
            'match' => 'cb_insert_map'
          },
          'EOL' => {
            'match' => 'cb_got_scalar',
            'new' => 'END'
          },
          'WS' => {
            'COLON' => {
              'EOL' => {
                'new' => 'FULLNODE',
                'return' => 1
              },
              'WS' => {
                'new' => 'FULLMAPVALUE',
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
    FULLMAPVALUE => $GRAMMAR->{FULLNODE},
    FULLSTARTNODE => $GRAMMAR->{FULLNODE},
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
        EOL: { match: cb_got_scalar, new: END }
        WS:
          COLON:
            match: cb_insert_map
            EOL: { new: FULLNODE, return: 1 }
            WS: { new: FULLMAPVALUE, return: 1 }
    
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
        DEFAULT: { new: FULL_MAPKEY }
    
    RULE_SINGLEQUOTED_KEY_OR_NODE:
      SINGLEQUOTE:
        match: cb_start_quoted
        SINGLEQUOTED:
          match: cb_take
          SINGLEQUOTE:
            EOL: { match: cb_got_scalar, new: END }
            COLON:
              match: cb_insert_map
              EOL: { new: FULLNODE, return: 1 }
              WS: { new: FULLMAPVALUE, return: 1 }
            WS:
              COLON:
                match: cb_insert_map
                EOL: { new: FULLNODE, return: 1 }
                WS: { new: FULLMAPVALUE, return: 1 }
        SINGLEQUOTED_LINE:
          match: cb_take
          EOL: { new: MULTILINE_SINGLEQUOTED }
    
    MULTILINE_SINGLEQUOTED:
      SINGLEQUOTED_LINE:
        match: cb_take
        EOL: { new: MULTILINE_SINGLEQUOTED }
        SINGLEQUOTE:
          EOL: { match: cb_got_scalar, new: END }
    
    RULE_DOUBLEQUOTED_KEY_OR_NODE:
      DOUBLEQUOTE:
        match: cb_start_quoted
        DOUBLEQUOTED:
          match: cb_take
          DOUBLEQUOTE:
            EOL: { match: cb_got_scalar, new: END }
            WS:
              COLON:
                match: cb_insert_map
                EOL: { new: FULLNODE , return: 1}
                WS: { new: FULLMAPVALUE, return: 1 }
              DEFAULT: { match: cb_got_scalar, new: ERROR }
            COLON:
              match: cb_insert_map
              EOL: { new: FULLNODE , return: 1}
              WS: { new: FULLMAPVALUE, return: 1 }
            DEFAULT: { new: ERROR }
        DOUBLEQUOTED_LINE:
          match: cb_take
          EOL: { new: MULTILINE_DOUBLEQUOTED  }
    
    MULTILINE_DOUBLEQUOTED:
      DOUBLEQUOTED_LINE:
        match: cb_take
        EOL: { new: MULTILINE_DOUBLEQUOTED  }
        DOUBLEQUOTE:
          EOL: { match: cb_got_scalar, new: END }
    
    RULE_PLAIN_KEY_OR_NODE:
      SCALAR:
        match: cb_start_plain
        COMMENT:
          match: cb_got_scalar
          EOL: { new: END }
        EOL: { match: cb_got_multiscalar, new: END }
        WS:
          COLON:
            match: cb_insert_map
            EOL: { new: FULLNODE , return: 1}
            WS: { new: FULLMAPVALUE, return: 1 }
        COLON:
          match: cb_insert_map
          EOL: { new: FULLNODE , return: 1}
          WS: { new: FULLMAPVALUE, return: 1 }
      COLON:
        match: cb_insert_map
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLMAPVALUE, return: 1 }
    
    RULE_PLAIN:
      SCALAR:
        match: cb_start_plain
        COMMENT:
          match: cb_got_multiscalar
          EOL: { new: END }
        EOL: { match: cb_got_multiscalar, new: END }
    
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
            WS: { new: FULLMAPVALUE, return: 1 }
      DOUBLEQUOTE:
        DOUBLEQUOTED:
          match: cb_doublequoted_key
          DOUBLEQUOTE:
            WS:
              COLON:
                EOL: { new: FULLNODE , return: 1}
                WS: { new: FULLMAPVALUE, return: 1 }
            COLON:
              EOL: { new: FULLNODE , return: 1}
              WS: { new: FULLMAPVALUE, return: 1 }
      SINGLEQUOTE:
        SINGLEQUOTED:
          match: cb_singlequoted_key
          SINGLEQUOTE:
            WS:
              COLON:
                EOL: { new: FULLNODE , return: 1}
                WS: { new: FULLMAPVALUE, return: 1 }
            COLON:
              EOL: { new: FULLNODE , return: 1}
              WS: { new: FULLMAPVALUE, return: 1 }
      SCALAR:
        match: cb_mapkey
        WS:
          COLON:
            EOL: { new: FULLNODE , return: 1}
            WS: { new: FULLMAPVALUE, return: 1 }
        COLON:
          EOL: { new: FULLNODE , return: 1}
          WS: { new: FULLMAPVALUE, return: 1 }
      COLON:
        match: cb_empty_mapkey
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLMAPVALUE, return: 1 }
    
    NODETYPE_MAPSTART:
      QUESTION:
        match: cb_questionstart
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLNODE , return: 1}
      DOUBLEQUOTE:
        DOUBLEQUOTED:
          match: cb_doublequotedstart
          DOUBLEQUOTE:
            WS:
              COLON:
                EOL: { new: FULLNODE , return: 1}
                WS: { new: FULLMAPVALUE, return: 1 }
            COLON:
              EOL: { new: FULLNODE , return: 1}
              WS: { new: FULLMAPVALUE, return: 1 }
      SINGLEQUOTE:
        SINGLEQUOTED:
          match: cb_singleequotedstart
          SINGLEQUOTE:
            WS:
              COLON:
                EOL: { new: FULLNODE , return: 1}
                WS: { new: FULLMAPVALUE, return: 1 }
            COLON:
              EOL: { new: FULLNODE , return: 1}
              WS: { new: FULLMAPVALUE, return: 1 }
      SCALAR:
        match: cb_mapkeystart
        WS:
          COLON: &new-mapvalue
            EOL: { new: FULLNODE , return: 1}
            WS: { new: FULLMAPVALUE, return: 1 }
        COLON: *new-mapvalue
    
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
            match: cb_read_block_scalar
            new: END
        EOL:
          match: cb_read_block_scalar
          new: END
      BLOCK_SCALAR_CHOMP:
        match: cb_add_block_scalar_chomp
        BLOCK_SCALAR_INDENT:
          match: cb_add_block_scalar_indent
          EOL:
            match: cb_read_block_scalar
            new: END
        EOL:
          match: cb_read_block_scalar
          new: END
      EOL:
        match: cb_read_block_scalar
        new: END
    
    FULL_MAPKEY:
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_MAP  }
          DEFAULT: { new: NODETYPE_MAP }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_MAP  }
          DEFAULT: { new: NODETYPE_MAP }
      DEFAULT: { new: NODETYPE_MAP }
    
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
