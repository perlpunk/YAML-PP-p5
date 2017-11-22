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
          'new' => 'NODETYPE_SCALAR_OR_MAP'
        },
        'TAG' => {
          'EOL' => {
            'match' => 'cb_property_eol',
            'new' => 'FULLNODE_TAG_ANCHOR',
            'return' => 1
          },
          'WS' => {
            'new' => 'NODETYPE_SCALAR_OR_MAP'
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
            'new' => 'NODETYPE_SCALAR_OR_MAP'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_SCALAR_OR_MAP'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'FULLNODE_ANCHOR' => {
    'ANCHOR' => {
      'WS' => {
        'DEFAULT' => {
          'new' => 'NODETYPE_SCALAR_OR_MAP'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_SCALAR_OR_MAP'
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
            'new' => 'NODETYPE_SCALAR_OR_MAP'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_SCALAR_OR_MAP'
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
          'new' => 'NODETYPE_SCALAR_OR_MAP'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_SCALAR_OR_MAP'
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
            'new' => 'NODETYPE_SCALAR_OR_MAP'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_SCALAR_OR_MAP'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'FULLNODE_TAG_ANCHOR' => {
    'ANCHOR' => {
      'WS' => {
        'DEFAULT' => {
          'new' => 'NODETYPE_SCALAR_OR_MAP'
        },
        'TAG' => {
          'WS' => {
            'new' => 'NODETYPE_SCALAR_OR_MAP'
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
            'new' => 'NODETYPE_SCALAR_OR_MAP'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'NODETYPE_SCALAR_OR_MAP'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'MULTILINE_DOUBLEQUOTED' => {
    'DOUBLEQUOTED_LINE' => {
      'DOUBLEQUOTE' => {
        'DEFAULT' => {
          'match' => 'cb_send_scalar',
          'return' => 1
        },
        'EOL' => {
          'match' => 'cb_send_scalar',
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
        'DEFAULT' => {
          'match' => 'cb_send_scalar',
          'return' => 1
        },
        'EOL' => {
          'match' => 'cb_send_scalar',
          'return' => 1
        }
      },
      'match' => 'cb_take'
    }
  },
  'NEWFLOWMAP' => {
    'DEFAULT' => {
      'new' => 'RULE_FULLFLOWSCALAR'
    },
    'EOL' => {
      'new' => 'NEWFLOWMAP',
      'return' => 1
    },
    'FLOWMAP_END' => {
      'DEFAULT' => {
        'return' => 1
      },
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_end_flowmap'
    },
    'WS' => {
      'new' => 'NEWFLOWMAP'
    }
  },
  'NEWFLOWSEQ' => {
    'DEFAULT' => {
      'new' => 'RULE_FULLFLOWSCALAR'
    },
    'EOL' => {
      'new' => 'NEWFLOWSEQ',
      'return' => 1
    },
    'FLOWSEQ_END' => {
      'DEFAULT' => {
        'return' => 1
      },
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_end_flowseq'
    },
    'WS' => {
      'new' => 'NEWFLOWSEQ'
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
      'match' => 'cb_empty_complexvalue',
      'new' => 'NODETYPE_MAP'
    }
  },
  'NODETYPE_FLOWMAP' => {
    'DEFAULT' => {
      'new' => 'RULE_FULLFLOWSCALAR'
    },
    'EOL' => {
      'new' => 'NODETYPE_FLOWMAP',
      'return' => 1
    },
    'FLOWMAP_END' => {
      'DEFAULT' => {
        'return' => 1
      },
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_end_flowmap'
    },
    'FLOW_COMMA' => {
      'match' => 'cb_flow_comma',
      'new' => 'NEWFLOWMAP'
    },
    'WS' => {
      'new' => 'NODETYPE_FLOWMAP'
    }
  },
  'NODETYPE_FLOWMAPVALUE' => {
    'COLON' => {
      'DEFAULT' => {
        'new' => 'RULE_FULLFLOWSCALAR'
      },
      'EOL' => {
        'new' => 'RULE_FULLFLOWSCALAR',
        'return' => 1
      },
      'WS' => {
        'new' => 'RULE_FULLFLOWSCALAR'
      },
      'match' => 'cb_flow_colon'
    },
    'DEFAULT' => {
      'match' => 'cb_empty_flowmap_value',
      'return' => 1
    },
    'WS' => {
      'new' => 'NODETYPE_FLOWMAPVALUE'
    }
  },
  'NODETYPE_FLOWSEQ' => {
    'EOL' => {
      'new' => 'NODETYPE_FLOWSEQ',
      'return' => 1
    },
    'FLOWSEQ_END' => {
      'DEFAULT' => {
        'return' => 1
      },
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_end_flowseq'
    },
    'FLOW_COMMA' => {
      'match' => 'cb_flow_comma',
      'new' => 'NEWFLOWSEQ'
    },
    'WS' => {
      'new' => 'NODETYPE_FLOWSEQ'
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
        'return' => 1
      },
      'match' => 'cb_send_alias'
    },
    'DOUBLEQUOTE' => {
      'DOUBLEQUOTED' => {
        'DOUBLEQUOTE' => {
          'EOL' => {
            'match' => 'cb_send_scalar',
            'return' => 1
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
    'FLOWMAP_START' => {
      'DEFAULT' => {
        'new' => 'NEWFLOWMAP'
      },
      'match' => 'cb_start_flowmap'
    },
    'FLOWSEQ_START' => {
      'DEFAULT' => {
        'new' => 'NEWFLOWSEQ'
      },
      'match' => 'cb_start_flowseq'
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
        'match' => 'cb_send_scalar'
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
            'match' => 'cb_send_scalar',
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
  'NODETYPE_NODE' => {
    'DASH' => {
      'EOL' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'node' => 'FULLNODE'
      },
      'match' => 'cb_seqstart'
    },
    'DEFAULT' => {
      'new' => 'NODETYPE_SCALAR_OR_MAP'
    }
  },
  'NODETYPE_SCALAR_OR_MAP' => {
    'ALIAS' => {
      'EOL' => {
        'match' => 'cb_send_alias_from_stack',
        'return' => 1
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'node' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'node' => 'FULLMAPVALUE_INLINE'
          },
          'match' => 'cb_insert_map_alias'
        }
      },
      'match' => 'cb_alias'
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
      'match' => 'cb_insert_empty_map'
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
            },
            'match' => 'cb_insert_map'
          },
          'EOL' => {
            'match' => 'cb_send_scalar',
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
      'DOUBLEQUOTED_LINE' => {
        'EOL' => {
          'match' => 'cb_fetch_tokens_quoted',
          'new' => 'MULTILINE_DOUBLEQUOTED'
        },
        'match' => 'cb_take'
      },
      'match' => 'cb_start_quoted'
    },
    'FLOWMAP_START' => {
      'DEFAULT' => {
        'new' => 'NEWFLOWMAP'
      },
      'match' => 'cb_start_flowmap'
    },
    'FLOWSEQ_START' => {
      'DEFAULT' => {
        'new' => 'NEWFLOWSEQ'
      },
      'match' => 'cb_start_flowseq'
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
        'match' => 'cb_send_scalar'
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
      'match' => 'cb_questionstart'
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
            },
            'match' => 'cb_insert_map'
          },
          'EOL' => {
            'match' => 'cb_send_scalar',
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
  },
  'NODETYPE_SEQ' => {
    'DASH' => {
      'EOL' => {
        'node' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'node' => 'FULLNODE'
      },
      'match' => 'cb_seqitem'
    }
  },
  'RULE_BLOCK_SCALAR_CONTENT' => {
    'END' => {
      'match' => 'cb_send_scalar',
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
      'match' => 'cb_send_scalar',
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
  'RULE_FLOWSCALAR' => {
    'ALIAS' => {
      'match' => 'cb_send_alias',
      'return' => 1
    },
    'DOUBLEQUOTE' => {
      'DOUBLEQUOTED' => {
        'DOUBLEQUOTE' => {
          'DEFAULT' => {
            'match' => 'cb_send_scalar',
            'return' => 1
          },
          'EOL' => {
            'match' => 'cb_send_scalar',
            'return' => 1
          },
          'WS' => {
            'match' => 'cb_send_scalar',
            'return' => 1
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
    'FLOWMAP_START' => {
      'DEFAULT' => {
        'new' => 'NEWFLOWMAP'
      },
      'match' => 'cb_start_flowmap'
    },
    'FLOWSEQ_START' => {
      'DEFAULT' => {
        'new' => 'NEWFLOWSEQ'
      },
      'match' => 'cb_start_flowseq'
    },
    'PLAIN' => {
      'COMMENT' => {
        'match' => 'cb_send_scalar',
        'return' => 1
      },
      'DEFAULT' => {
        'match' => 'cb_send_scalar',
        'return' => 1
      },
      'EOL' => {
        'match' => 'cb_fetch_tokens_plain',
        'new' => 'RULE_PLAIN_MULTI_FLOW'
      },
      'match' => 'cb_start_plain'
    },
    'SINGLEQUOTE' => {
      'SINGLEQUOTED' => {
        'SINGLEQUOTE' => {
          'EOL' => {
            'match' => 'cb_send_scalar',
            'return' => 1
          },
          'WS' => {
            'match' => 'cb_send_scalar',
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
  'RULE_FULLFLOWSCALAR' => {
    'ANCHOR' => {
      'DEFAULT' => {
        'new' => 'RULE_FLOWSCALAR'
      },
      'EOL' => {
        'new' => 'RULE_FULLFLOWSCALAR_ANCHOR',
        'return' => 1
      },
      'WS' => {
        'DEFAULT' => {
          'new' => 'RULE_FLOWSCALAR'
        },
        'TAG' => {
          'WS' => {
            'new' => 'RULE_FLOWSCALAR'
          },
          'match' => 'cb_tag'
        }
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'RULE_FLOWSCALAR'
    },
    'TAG' => {
      'DEFAULT' => {
        'new' => 'RULE_FLOWSCALAR'
      },
      'EOL' => {
        'new' => 'RULE_FULLFLOWSCALAR_TAG',
        'return' => 1
      },
      'WS' => {
        'ANCHOR' => {
          'WS' => {
            'new' => 'RULE_FLOWSCALAR'
          },
          'match' => 'cb_anchor'
        },
        'DEFAULT' => {
          'new' => 'RULE_FLOWSCALAR'
        }
      },
      'match' => 'cb_tag'
    }
  },
  'RULE_FULLFLOWSCALAR_TAG' => {
    'ANCHOR' => {
      'EOL' => {
        'new' => 'RULE_FLOWSCALAR',
        'return' => 1
      },
      'WS' => {
        'new' => 'RULE_FLOWSCALAR'
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'RULE_FLOWSCALAR'
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
      'match' => 'cb_send_alias'
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
          },
          'match' => 'cb_send_mapkey'
        },
        'match' => 'cb_take'
      },
      'match' => 'cb_start_quoted'
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
        'match' => 'cb_send_mapkey'
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
          'match' => 'cb_send_mapkey'
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
          },
          'match' => 'cb_send_mapkey'
        },
        'match' => 'cb_take'
      },
      'match' => 'cb_start_quoted'
    }
  },
  'RULE_PLAIN_MULTI' => {
    'END' => {
      'match' => 'cb_send_scalar',
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
              'match' => 'cb_send_scalar',
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
            'match' => 'cb_send_scalar',
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
  'RULE_PLAIN_MULTI_FLOW' => {
    'DEFAULT' => {
      'match' => 'cb_send_scalar',
      'return' => 1
    },
    'END' => {
      'match' => 'cb_send_scalar',
      'return' => 1
    },
    'EOL' => {
      'match' => 'cb_empty_plain',
      'new' => 'RULE_PLAIN_MULTI'
    },
    'INDENT' => {
      'WS' => {
        'DEFAULT' => {
          'match' => 'cb_send_scalar',
          'return' => 1
        },
        'PLAIN' => {
          'COMMENT' => {
            'EOL' => {
              'match' => 'cb_send_scalar',
              'return' => 1
            }
          },
          'DEFAULT' => {
            'match' => 'cb_send_scalar',
            'return' => 1
          },
          'EOL' => {
            'match' => 'cb_fetch_tokens_plain',
            'new' => 'RULE_PLAIN_MULTI_FLOW'
          },
          'match' => 'cb_take'
        }
      }
    },
    'WS' => {
      'PLAIN' => {
        'COMMENT' => {
          'EOL' => {
            'match' => 'cb_send_scalar',
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
  }
};


# END OF GRAMMAR INLINE

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
    NODETYPE_NODE:
      DASH:
        match: cb_seqstart
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLNODE }
    
      DEFAULT: { new: NODETYPE_SCALAR_OR_MAP }
    
    NODETYPE_SCALAR_OR_MAP:
      ALIAS:
        match: cb_alias
        EOL: { match: cb_send_alias_from_stack, return: 1 }
        WS:
          COLON:
            match: cb_insert_map_alias
            EOL: { node: FULLNODE, return: 1 }
            WS: { node: FULLMAPVALUE_INLINE }
    
      QUESTION:
        match: cb_questionstart
        EOL: { node: FULLNODE, return: 1 }
        WS: { node: FULLNODE, return: 1 }
    
      SINGLEQUOTE:
        match: cb_start_quoted
        SINGLEQUOTED:
          match: cb_take
          SINGLEQUOTE:
            EOL: { match: cb_send_scalar, return: 1 }
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
    
      DOUBLEQUOTE:
        match: cb_start_quoted
        DOUBLEQUOTED:
          match: cb_take
          DOUBLEQUOTE:
            EOL: { match: cb_send_scalar, return: 1 }
            WS:
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
    
      PLAIN:
        match: cb_start_plain
        COMMENT:
          match: cb_send_scalar
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
        match: cb_insert_empty_map
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLMAPVALUE_INLINE, return: 1 }
    
      LITERAL:
        match: cb_block_scalar
        new: RULE_BLOCK_SCALAR_HEADER
      FOLDED:
        match: cb_block_scalar
        new: RULE_BLOCK_SCALAR_HEADER
    
      FLOWSEQ_START:
        match: cb_start_flowseq
        DEFAULT: { new: NEWFLOWSEQ }
    
      FLOWMAP_START:
        match: cb_start_flowmap
        DEFAULT: { new: NEWFLOWMAP }
    
    
    
    
    NODETYPE_COMPLEX:
      COLON:
        match: cb_complexcolon
        EOL: { node: FULLNODE, return: 1 }
        WS: { node: FULLNODE, return: 1 }
      DEFAULT:
        match: cb_empty_complexvalue
        new: NODETYPE_MAP
    
    MULTILINE_SINGLEQUOTED:
      SINGLEQUOTED_LINE:
        match: cb_take
        EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_SINGLEQUOTED }
        SINGLEQUOTE:
          EOL: { match: cb_send_scalar, return: 1 }
          DEFAULT: { match: cb_send_scalar, return: 1 }
      EOL: { match: cb_empty_quoted_line, new: MULTILINE_SINGLEQUOTED }
    
    MULTILINE_DOUBLEQUOTED:
      DOUBLEQUOTED_LINE:
        match: cb_take
        EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_DOUBLEQUOTED  }
        DOUBLEQUOTE:
          EOL: { match: cb_send_scalar, return: 1 }
          DEFAULT: { match: cb_send_scalar, return: 1 }
      EOL: { match: cb_empty_quoted_line, new: MULTILINE_DOUBLEQUOTED }
    
    RULE_FULLFLOWSCALAR:
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: RULE_FLOWSCALAR }
          DEFAULT: { new: RULE_FLOWSCALAR }
        EOL: { new: RULE_FULLFLOWSCALAR_ANCHOR, return: 1 }
        DEFAULT: { new: RULE_FLOWSCALAR }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: RULE_FLOWSCALAR }
          DEFAULT: { new: RULE_FLOWSCALAR }
        EOL: { new: RULE_FULLFLOWSCALAR_TAG, return: 1 }
        DEFAULT: { new: RULE_FLOWSCALAR }
      DEFAULT: { new: RULE_FLOWSCALAR }
    
    RULE_FULLFLOWSCALAR_TAG:
      ANCHOR:
        match: cb_anchor
        WS: { new: RULE_FLOWSCALAR }
        EOL: { new: RULE_FLOWSCALAR, return: 1 }
      DEFAULT: { new: RULE_FLOWSCALAR }
    
    RULE_FLOWSCALAR:
      FLOWSEQ_START:
        match: cb_start_flowseq
        DEFAULT: { new: NEWFLOWSEQ }
      FLOWMAP_START:
        match: cb_start_flowmap
        DEFAULT: { new: NEWFLOWMAP }
    
      ALIAS:
        match: cb_send_alias
        return: 1
    
      SINGLEQUOTE:
        match: cb_start_quoted
        SINGLEQUOTED:
          match: cb_take
          SINGLEQUOTE:
            EOL: { match: cb_send_scalar, return: 1 }
            WS: { match: cb_send_scalar, return: 1 }
        SINGLEQUOTED_LINE:
          match: cb_take
          EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_SINGLEQUOTED }
    
      DOUBLEQUOTE:
        match: cb_start_quoted
        DOUBLEQUOTED:
          match: cb_take
          DOUBLEQUOTE:
            EOL: { match: cb_send_scalar, return: 1 }
            WS: { match: cb_send_scalar, return: 1 }
            DEFAULT: { match: cb_send_scalar, return: 1 }
        DOUBLEQUOTED_LINE:
          match: cb_take
          EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_DOUBLEQUOTED  }
    
      PLAIN:
        match: cb_start_plain
        EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI_FLOW }
        COMMENT:
          match: cb_send_scalar
          return: 1
        DEFAULT:
          match: cb_send_scalar
          return: 1
    
    #  DEFAULT: { match: cb_empty_flowmap_value, return: 1 }
    
    
    NEWFLOWSEQ:
      EOL: { new: NEWFLOWSEQ, return: 1 }
      WS: { new: NEWFLOWSEQ }
      FLOWSEQ_END:
        match: cb_end_flowseq
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
      DEFAULT: { new: RULE_FULLFLOWSCALAR }
    
    NODETYPE_FLOWSEQ:
      EOL: { new: NODETYPE_FLOWSEQ, return: 1 }
      WS: { new: NODETYPE_FLOWSEQ }
      FLOWSEQ_END:
        match: cb_end_flowseq
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
      FLOW_COMMA: { match: cb_flow_comma, new: NEWFLOWSEQ }
    
    NODETYPE_FLOWMAPVALUE:
      COLON:
        match: cb_flow_colon
        WS: { new: RULE_FULLFLOWSCALAR }
        EOL: { new: RULE_FULLFLOWSCALAR, return: 1 }
        DEFAULT: { new: RULE_FULLFLOWSCALAR }
      WS: { new: NODETYPE_FLOWMAPVALUE }
      DEFAULT:
        match: cb_empty_flowmap_value
        return: 1
    
    
    NEWFLOWMAP:
      EOL: { new: NEWFLOWMAP, return: 1 }
      WS: { new: NEWFLOWMAP }
      FLOWMAP_END:
        match: cb_end_flowmap
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
      DEFAULT: { new: RULE_FULLFLOWSCALAR }
    
    NODETYPE_FLOWMAP:
      EOL: { new: NODETYPE_FLOWMAP, return: 1 }
      WS: { new: NODETYPE_FLOWMAP }
      FLOWMAP_END:
        match: cb_end_flowmap
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
      FLOW_COMMA: { match: cb_flow_comma, new: NEWFLOWMAP }
      DEFAULT: { new: RULE_FULLFLOWSCALAR }
    
    
    
    RULE_PLAIN_MULTI:
      END: { match: cb_send_scalar, return: 1 }
      EOL: { match: cb_empty_plain, new: RULE_PLAIN_MULTI }
      WS:
        PLAIN:
          match: cb_take
          EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI }
          COMMENT:
            EOL: { match: cb_send_scalar, return: 1 }
      INDENT:
        WS:
          PLAIN:
            match: cb_take
            EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI }
            COMMENT:
              EOL: { match: cb_send_scalar, return: 1 }
    
    RULE_PLAIN_MULTI_FLOW:
      END: { match: cb_send_scalar, return: 1 }
      EOL: { match: cb_empty_plain, new: RULE_PLAIN_MULTI }
      WS:
        PLAIN:
          match: cb_take
          EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI }
          COMMENT:
            EOL: { match: cb_send_scalar, return: 1 }
      INDENT:
        WS:
          PLAIN:
            match: cb_take
            EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI_FLOW }
            COMMENT:
              EOL: { match: cb_send_scalar, return: 1 }
            DEFAULT: { match: cb_send_scalar, return: 1 }
          DEFAULT: { match: cb_send_scalar, return: 1 }
      DEFAULT: { match: cb_send_scalar, return: 1 }
    
    
    RULE_MAPKEY:
      QUESTION:
        match: cb_question
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLNODE , return: 1}
      ALIAS:
        match: cb_send_alias
        WS:
          COLON:
            EOL: { node: FULLNODE , return: 1}
            WS: { node: FULLMAPVALUE_INLINE, return: 1 }
      DOUBLEQUOTE:
        match: cb_start_quoted
        DOUBLEQUOTED:
          match: cb_take
          DOUBLEQUOTE:
            match: cb_send_mapkey
            WS:
              COLON:
                EOL: { node: FULLNODE , return: 1}
                WS: { node: FULLMAPVALUE_INLINE, return: 1 }
            COLON:
              EOL: { node: FULLNODE , return: 1}
              WS: { node: FULLMAPVALUE_INLINE, return: 1 }
      SINGLEQUOTE:
        match: cb_start_quoted
        SINGLEQUOTED:
          match: cb_take
          SINGLEQUOTE:
            match: cb_send_mapkey
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
            match: cb_send_mapkey
            EOL: { node: FULLNODE , return: 1}
            WS: { node: FULLMAPVALUE_INLINE, return: 1 }
        COLON:
          match: cb_send_mapkey
          EOL: { node: FULLNODE , return: 1}
          WS: { node: FULLMAPVALUE_INLINE, return: 1 }
      COLON:
        match: cb_empty_mapkey
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLMAPVALUE_INLINE, return: 1 }
    
    NODETYPE_SEQ:
      DASH:
        match: cb_seqitem
        EOL: { node: FULLNODE , return: 1}
        WS: { node: FULLNODE }
    
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
      END: { match: cb_send_scalar, return: 1 }
    
    RULE_BLOCK_SCALAR_CONTENT:
      EOL: { match: cb_block_scalar_empty_line, new: RULE_BLOCK_SCALAR_CONTENT }
      INDENT:
        EOL: { match: cb_block_scalar_empty_line, new: RULE_BLOCK_SCALAR_CONTENT }
        BLOCK_SCALAR_CONTENT:
          match: cb_block_scalar_content
          EOL: { match: cb_fetch_tokens_block_scalar, new: RULE_BLOCK_SCALAR_CONTENT }
      END: { match: cb_send_scalar, return: 1 }
    
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
            WS: { new: NODETYPE_SCALAR_OR_MAP  }
          DEFAULT: { new: NODETYPE_SCALAR_OR_MAP }
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_SCALAR_OR_MAP  }
          DEFAULT: { new: NODETYPE_SCALAR_OR_MAP }
      DEFAULT: { new: NODETYPE_NODE }
    
    FULLNODE_TAG:
      ANCHOR:
        match: cb_anchor
        EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_SCALAR_OR_MAP  }
          DEFAULT: { new: NODETYPE_SCALAR_OR_MAP, }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_SCALAR_OR_MAP  }
          DEFAULT: { new: NODETYPE_SCALAR_OR_MAP }
      DEFAULT: { new: NODETYPE_NODE }
    
    FULLNODE_TAG_ANCHOR:
      ANCHOR:
        match: cb_anchor
        WS:
          TAG:
            match: cb_tag
            WS: { new: NODETYPE_SCALAR_OR_MAP  }
          DEFAULT: { new: NODETYPE_SCALAR_OR_MAP }
      TAG:
        match: cb_tag
        WS:
          ANCHOR:
            match: cb_anchor
            WS: { new: NODETYPE_SCALAR_OR_MAP  }
          DEFAULT: { new: NODETYPE_SCALAR_OR_MAP }
      DEFAULT: { new: NODETYPE_NODE }
    
    FULLNODE:
      ANCHOR:
        match: cb_anchor
        EOL: { match: cb_property_eol, new: FULLNODE_ANCHOR , return: 1}
        WS:
          TAG:
            match: cb_tag
            EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
            WS: { new: NODETYPE_SCALAR_OR_MAP  }
          DEFAULT: { new: NODETYPE_SCALAR_OR_MAP }
      TAG:
        match: cb_tag
        EOL: { match: cb_property_eol, new: FULLNODE_TAG , return: 1}
        WS:
          ANCHOR:
            match: cb_anchor
            EOL: { match: cb_property_eol, new: FULLNODE_TAG_ANCHOR , return: 1}
            WS: { new: NODETYPE_SCALAR_OR_MAP  }
          DEFAULT: { new: NODETYPE_SCALAR_OR_MAP }
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
        match: cb_send_alias
        EOL: { return: 1 }
    
      SINGLEQUOTE:
        match: cb_start_quoted
        SINGLEQUOTED:
          match: cb_take
          SINGLEQUOTE:
            EOL: { match: cb_send_scalar, return: 1 }
        SINGLEQUOTED_LINE:
          match: cb_take
          EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_SINGLEQUOTED }
    
      DOUBLEQUOTE:
        match: cb_start_quoted
        DOUBLEQUOTED:
          match: cb_take
          DOUBLEQUOTE:
            EOL: { match: cb_send_scalar, return: 1 }
        DOUBLEQUOTED_LINE:
          match: cb_take
          EOL: { match: cb_fetch_tokens_quoted, new: MULTILINE_DOUBLEQUOTED  }
    
      PLAIN:
        match: cb_start_plain
        COMMENT:
          match: cb_send_scalar
          EOL: { return: 1 }
        EOL: { match: cb_fetch_tokens_plain, new: RULE_PLAIN_MULTI }
    
      LITERAL:
        match: cb_block_scalar
        new: RULE_BLOCK_SCALAR_HEADER
      FOLDED:
        match: cb_block_scalar
        new: RULE_BLOCK_SCALAR_HEADER
    
      FLOWSEQ_START:
        match: cb_start_flowseq
        DEFAULT: { new: NEWFLOWSEQ }
    
      FLOWMAP_START:
        match: cb_start_flowmap
        DEFAULT: { new: NEWFLOWMAP }


    # END OF YAML INLINE

=cut
