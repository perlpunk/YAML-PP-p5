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
  'FLOWMAP' => {
    'ALIAS' => {
      'match' => 'cb_send_alias',
      'return' => 1
    },
    'COLON' => {
      'EOL' => {
        'match' => 'cb_empty_flow_mapkey',
        'new' => 'RULE_FULLFLOWSCALAR',
        'return' => 1
      },
      'WS' => {
        'match' => 'cb_empty_flow_mapkey',
        'new' => 'RULE_FULLFLOWSCALAR'
      }
    },
    'FLOWMAP_START' => {
      'match' => 'cb_start_flowmap',
      'new' => 'NEWFLOWMAP'
    },
    'FLOWSEQ_START' => {
      'match' => 'cb_start_flowseq',
      'new' => 'NEWFLOWSEQ'
    },
    'PLAIN' => {
      'match' => 'cb_flowkey_plain',
      'return' => 1
    },
    'PLAIN_MULTI' => {
      'match' => 'cb_send_plain_multi',
      'return' => 1
    },
    'QUOTED' => {
      'match' => 'cb_flowkey_quoted',
      'return' => 1
    },
    'QUOTED_MULTILINE' => {
      'match' => 'cb_quoted_multiline',
      'return' => 1
    }
  },
  'FLOWSEQ' => {
    'ALIAS' => {
      'match' => 'cb_send_flow_alias',
      'new' => 'FLOWSEQ_NEXT'
    },
    'FLOWMAP_START' => {
      'match' => 'cb_start_flowmap',
      'new' => 'NEWFLOWMAP'
    },
    'FLOWSEQ_START' => {
      'match' => 'cb_start_flowseq',
      'new' => 'NEWFLOWSEQ'
    },
    'PLAIN' => {
      'match' => 'cb_flow_plain',
      'new' => 'FLOWSEQ_NEXT'
    },
    'PLAIN_MULTI' => {
      'match' => 'cb_send_plain_multi',
      'new' => 'FLOWSEQ_NEXT'
    },
    'QUOTED' => {
      'match' => 'cb_flowkey_quoted',
      'new' => 'FLOWSEQ_NEXT'
    },
    'QUOTED_MULTILINE' => {
      'match' => 'cb_quoted_multiline',
      'new' => 'FLOWSEQ_NEXT'
    }
  },
  'FLOWSEQ_NEXT' => {
    'EOL' => {
      'new' => 'FLOWSEQ_NEXT',
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
      'return' => 1
    },
    'WS' => {
      'new' => 'FLOWSEQ_NEXT'
    }
  },
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
  'NEWFLOWMAP' => {
    'ANCHOR' => {
      'EOL' => {
        'new' => 'NEWFLOWMAP_ANCHOR',
        'return' => 1
      },
      'WS' => {
        'new' => 'NEWFLOWMAP_ANCHOR'
      },
      'match' => 'cb_anchor'
    },
    'COLON' => {
      'EOL' => {
        'match' => 'cb_empty_flow_mapkey',
        'new' => 'RULE_FULLFLOWSCALAR',
        'return' => 1
      },
      'WS' => {
        'match' => 'cb_empty_flow_mapkey',
        'new' => 'RULE_FULLFLOWSCALAR'
      }
    },
    'DEFAULT' => {
      'new' => 'FLOWMAP'
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
    'QUESTION' => {
      'match' => 'cb_flow_question',
      'new' => 'NEWFLOWMAP'
    },
    'TAG' => {
      'EOL' => {
        'new' => 'NEWFLOWMAP_TAG',
        'return' => 1
      },
      'WS' => {
        'new' => 'NEWFLOWMAP_TAG'
      },
      'match' => 'cb_tag'
    },
    'WS' => {
      'new' => 'NEWFLOWMAP'
    }
  },
  'NEWFLOWMAP_ANCHOR' => {
    'DEFAULT' => {
      'new' => 'FLOWMAP'
    },
    'EOL' => {
      'new' => 'NEWFLOWMAP_ANCHOR',
      'return' => 1
    },
    'TAG' => {
      'EOL' => {
        'new' => 'FLOWMAP',
        'return' => 1
      },
      'WS' => {
        'new' => 'FLOWMAP'
      },
      'match' => 'cb_tag'
    },
    'WS' => {
      'new' => 'NEWFLOWMAP_ANCHOR'
    }
  },
  'NEWFLOWMAP_TAG' => {
    'ANCHOR' => {
      'EOL' => {
        'new' => 'FLOWMAP',
        'return' => 1
      },
      'WS' => {
        'new' => 'FLOWMAP'
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'FLOWMAP'
    },
    'EOL' => {
      'new' => 'NEWFLOWMAP_TAG',
      'return' => 1
    },
    'WS' => {
      'new' => 'NEWFLOWMAP_TAG'
    }
  },
  'NEWFLOWSEQ' => {
    'ANCHOR' => {
      'EOL' => {
        'new' => 'NEWFLOWSEQ_ANCHOR',
        'return' => 1
      },
      'WS' => {
        'new' => 'NEWFLOWSEQ_ANCHOR'
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'FLOWSEQ'
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
    'TAG' => {
      'EOL' => {
        'new' => 'NEWFLOWSEQ_TAG',
        'return' => 1
      },
      'WS' => {
        'new' => 'NEWFLOWSEQ_TAG'
      },
      'match' => 'cb_tag'
    },
    'WS' => {
      'new' => 'NEWFLOWSEQ'
    }
  },
  'NEWFLOWSEQ_ANCHOR' => {
    'DEFAULT' => {
      'new' => 'FLOWSEQ'
    },
    'EOL' => {
      'new' => 'NEWFLOWSEQ_ANCHOR',
      'return' => 1
    },
    'TAG' => {
      'EOL' => {
        'new' => 'FLOWSEQ',
        'return' => 1
      },
      'WS' => {
        'new' => 'FLOWSEQ'
      },
      'match' => 'cb_tag'
    },
    'WS' => {
      'new' => 'NEWFLOWSEQ_ANCHOR'
    }
  },
  'NEWFLOWSEQ_TAG' => {
    'ANCHOR' => {
      'EOL' => {
        'new' => 'FLOWSEQ',
        'return' => 1
      },
      'WS' => {
        'new' => 'FLOWSEQ'
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'FLOWSEQ'
    },
    'EOL' => {
      'new' => 'NEWFLOWSEQ_TAG',
      'return' => 1
    },
    'WS' => {
      'new' => 'NEWFLOWSEQ_TAG'
    }
  },
  'NODETYPE_COMPLEX' => {
    'COLON' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE'
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
      'new' => 'NEWFLOWMAP'
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
    'EOL' => {
      'new' => 'NODETYPE_FLOWMAPVALUE',
      'return' => 1
    },
    'FLOWMAP_END' => {
      'DEFAULT' => {
        'return' => 1
      },
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_end_flowmap_empty'
    },
    'FLOW_COMMA' => {
      'match' => 'cb_empty_flowmap_value',
      'return' => 1
    },
    'WS' => {
      'new' => 'NODETYPE_FLOWMAPVALUE'
    }
  },
  'NODETYPE_FLOWSEQ' => {
    'DEFAULT' => {
      'new' => 'NEWFLOWSEQ'
    },
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
    'BLOCK_SCALAR' => {
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_send_block_scalar'
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
      'EOL' => {
        'match' => 'cb_send_scalar',
        'return' => 1
      },
      'match' => 'cb_start_plain'
    },
    'PLAIN_MULTI' => {
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_send_plain_multi'
    },
    'QUOTED' => {
      'EOL' => {
        'match' => 'cb_send_scalar',
        'return' => 1
      },
      'match' => 'cb_take_quoted'
    },
    'QUOTED_MULTILINE' => {
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_quoted_multiline'
    }
  },
  'NODETYPE_NODE' => {
    'DASH' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE'
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
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'FULLMAPVALUE_INLINE'
          },
          'match' => 'cb_insert_map_alias'
        }
      },
      'match' => 'cb_alias'
    },
    'BLOCK_SCALAR' => {
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_send_block_scalar'
    },
    'COLON' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLMAPVALUE_INLINE'
      },
      'match' => 'cb_insert_empty_map'
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
      'COLON' => {
        'EOL' => {
          'new' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'new' => 'FULLMAPVALUE_INLINE'
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
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'FULLMAPVALUE_INLINE'
          },
          'match' => 'cb_insert_map'
        }
      },
      'match' => 'cb_start_plain'
    },
    'PLAIN_MULTI' => {
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_send_plain_multi'
    },
    'QUESTION' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE'
      },
      'match' => 'cb_questionstart'
    },
    'QUOTED' => {
      'COLON' => {
        'EOL' => {
          'new' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'new' => 'FULLMAPVALUE_INLINE'
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
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'FULLMAPVALUE_INLINE'
          },
          'match' => 'cb_insert_map'
        }
      },
      'match' => 'cb_take_quoted'
    },
    'QUOTED_MULTILINE' => {
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_quoted_multiline'
    },
    'WS' => {
      'new' => 'FULLMAPVALUE_INLINE'
    }
  },
  'NODETYPE_SEQ' => {
    'DASH' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE'
      },
      'match' => 'cb_seqitem'
    }
  },
  'RULE_FLOWSCALAR' => {
    'ALIAS' => {
      'match' => 'cb_send_alias',
      'return' => 1
    },
    'FLOWMAP_END' => {
      'DEFAULT' => {
        'return' => 1
      },
      'EOL' => {
        'return' => 1
      },
      'match' => 'cb_end_flowmap_empty'
    },
    'FLOWMAP_START' => {
      'match' => 'cb_start_flowmap',
      'new' => 'NEWFLOWMAP'
    },
    'FLOWSEQ_START' => {
      'match' => 'cb_start_flowseq',
      'new' => 'NEWFLOWSEQ'
    },
    'FLOW_COMMA' => {
      'match' => 'cb_empty_flow_mapkey',
      'return' => 1
    },
    'PLAIN' => {
      'DEFAULT' => {
        'match' => 'cb_send_scalar',
        'return' => 1
      },
      'EOL' => {
        'match' => 'cb_send_scalar',
        'return' => 1
      },
      'match' => 'cb_start_plain'
    },
    'PLAIN_MULTI' => {
      'match' => 'cb_send_plain_multi',
      'return' => 1
    },
    'QUOTED' => {
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
      },
      'match' => 'cb_take_quoted'
    },
    'QUOTED_MULTILINE' => {
      'match' => 'cb_quoted_multiline',
      'return' => 1
    }
  },
  'RULE_FULLFLOWSCALAR' => {
    'ANCHOR' => {
      'DEFAULT' => {
        'new' => 'RULE_FULLFLOWSCALAR_ANCHOR'
      },
      'EOL' => {
        'new' => 'RULE_FULLFLOWSCALAR_ANCHOR',
        'return' => 1
      },
      'match' => 'cb_anchor'
    },
    'DEFAULT' => {
      'new' => 'RULE_FLOWSCALAR'
    },
    'TAG' => {
      'DEFAULT' => {
        'new' => 'RULE_FULLFLOWSCALAR_TAG'
      },
      'EOL' => {
        'new' => 'RULE_FULLFLOWSCALAR_TAG',
        'return' => 1
      },
      'match' => 'cb_tag'
    }
  },
  'RULE_FULLFLOWSCALAR_ANCHOR' => {
    'DEFAULT' => {
      'new' => 'RULE_FLOWSCALAR'
    },
    'TAG' => {
      'EOL' => {
        'new' => 'RULE_FLOWSCALAR',
        'return' => 1
      },
      'WS' => {
        'new' => 'RULE_FLOWSCALAR'
      },
      'match' => 'cb_tag'
    },
    'WS' => {
      'new' => 'RULE_FULLFLOWSCALAR_ANCHOR'
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
    },
    'WS' => {
      'new' => 'RULE_FULLFLOWSCALAR_TAG'
    }
  },
  'RULE_MAPKEY' => {
    'ALIAS' => {
      'WS' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'FULLMAPVALUE_INLINE'
          }
        }
      },
      'match' => 'cb_send_alias'
    },
    'COLON' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLMAPVALUE_INLINE'
      },
      'match' => 'cb_empty_mapkey'
    },
    'PLAIN' => {
      'COLON' => {
        'EOL' => {
          'new' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'new' => 'FULLMAPVALUE_INLINE'
        },
        'match' => 'cb_send_mapkey'
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'FULLMAPVALUE_INLINE'
          },
          'match' => 'cb_send_mapkey'
        }
      },
      'match' => 'cb_mapkey'
    },
    'QUESTION' => {
      'EOL' => {
        'new' => 'FULLNODE',
        'return' => 1
      },
      'WS' => {
        'new' => 'FULLNODE'
      },
      'match' => 'cb_question'
    },
    'QUOTED' => {
      'COLON' => {
        'EOL' => {
          'new' => 'FULLNODE',
          'return' => 1
        },
        'WS' => {
          'new' => 'FULLMAPVALUE_INLINE'
        }
      },
      'WS' => {
        'COLON' => {
          'EOL' => {
            'new' => 'FULLNODE',
            'return' => 1
          },
          'WS' => {
            'new' => 'FULLMAPVALUE_INLINE'
          }
        }
      },
      'match' => 'cb_take_quoted_key'
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
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLNODE }
    
      DEFAULT: { new: NODETYPE_SCALAR_OR_MAP }
    
    NODETYPE_SCALAR_OR_MAP:
    
      # Flow nodes can follow tabs
      WS: { new: FULLMAPVALUE_INLINE }
    
      ALIAS:
        match: cb_alias
        EOL: { match: cb_send_alias_from_stack, return: 1 }
        WS:
          COLON:
            match: cb_insert_map_alias
            EOL: { new: FULLNODE, return: 1 }
            WS: { new: FULLMAPVALUE_INLINE }
    
      QUESTION:
        match: cb_questionstart
        EOL: { new: FULLNODE, return: 1 }
        WS: { new: FULLNODE }
    
      QUOTED:
        match: cb_take_quoted
        EOL: { match: cb_send_scalar, return: 1 }
        WS:
          COLON:
            match: cb_insert_map
            EOL: { new: FULLNODE , return: 1}
            WS: { new: FULLMAPVALUE_INLINE }
        COLON:
          match: cb_insert_map
          EOL: { new: FULLNODE , return: 1}
          WS: { new: FULLMAPVALUE_INLINE }
    
      QUOTED_MULTILINE:
        match: cb_quoted_multiline
        EOL: { return: 1 }
    
    
      PLAIN:
        match: cb_start_plain
        EOL:
          match: cb_send_scalar
          return: 1
        WS:
          COLON:
            match: cb_insert_map
            EOL: { new: FULLNODE , return: 1}
            WS: { new: FULLMAPVALUE_INLINE }
        COLON:
          match: cb_insert_map
          EOL: { new: FULLNODE , return: 1}
          WS: { new: FULLMAPVALUE_INLINE }
    
      PLAIN_MULTI:
        match: cb_send_plain_multi
        EOL: { return: 1 }
    
      COLON:
        match: cb_insert_empty_map
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLMAPVALUE_INLINE }
    
      BLOCK_SCALAR:
        match: cb_send_block_scalar
        EOL: { return: 1 }
    
      FLOWSEQ_START:
        match: cb_start_flowseq
        DEFAULT: { new: NEWFLOWSEQ }
    
      FLOWMAP_START:
        match: cb_start_flowmap
        DEFAULT: { new: NEWFLOWMAP }
    
    
    
    
    NODETYPE_COMPLEX:
      COLON:
        match: cb_complexcolon
        EOL: { new: FULLNODE, return: 1 }
        WS: { new: FULLNODE }
      DEFAULT:
        match: cb_empty_complexvalue
        new: NODETYPE_MAP
    
    RULE_FULLFLOWSCALAR:
      ANCHOR:
        match: cb_anchor
        EOL: { new: RULE_FULLFLOWSCALAR_ANCHOR, return: 1 }
        DEFAULT: { new: RULE_FULLFLOWSCALAR_ANCHOR }
      TAG:
        match: cb_tag
        EOL: { new: RULE_FULLFLOWSCALAR_TAG, return: 1 }
        DEFAULT: { new: RULE_FULLFLOWSCALAR_TAG }
      DEFAULT: { new: RULE_FLOWSCALAR }
    
    RULE_FULLFLOWSCALAR_ANCHOR:
      WS: { new: RULE_FULLFLOWSCALAR_ANCHOR }
      TAG:
        match: cb_tag
        WS: { new: RULE_FLOWSCALAR }
        EOL: { new: RULE_FLOWSCALAR, return: 1 }
      DEFAULT: { new: RULE_FLOWSCALAR }
    
    RULE_FULLFLOWSCALAR_TAG:
      WS: { new: RULE_FULLFLOWSCALAR_TAG }
      ANCHOR:
        match: cb_anchor
        WS: { new: RULE_FLOWSCALAR }
        EOL: { new: RULE_FLOWSCALAR, return: 1 }
      DEFAULT: { new: RULE_FLOWSCALAR }
    
    RULE_FLOWSCALAR:
      FLOWSEQ_START: { match: cb_start_flowseq, new: NEWFLOWSEQ }
      FLOWMAP_START: { match: cb_start_flowmap, new: NEWFLOWMAP }
    
      ALIAS: { match: cb_send_alias, return: 1 }
    
      QUOTED:
        match: cb_take_quoted
        EOL: { match: cb_send_scalar, return: 1 }
        WS: { match: cb_send_scalar, return: 1 }
        DEFAULT: { match: cb_send_scalar, return: 1 }
    
      QUOTED_MULTILINE: { match: cb_quoted_multiline, return: 1 }
    
      PLAIN:
        match: cb_start_plain
        EOL: { match: cb_send_scalar, return: 1 }
        DEFAULT: { match: cb_send_scalar, return: 1 }
    
      PLAIN_MULTI: { match: cb_send_plain_multi, return: 1 }
    
      FLOW_COMMA: { match: cb_empty_flow_mapkey, return: 1 }
    
      FLOWMAP_END:
        match: cb_end_flowmap_empty
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
    
    FLOWSEQ:
      FLOWSEQ_START: { match: cb_start_flowseq, new: NEWFLOWSEQ }
      FLOWMAP_START: { match: cb_start_flowmap, new: NEWFLOWMAP }
    
      ALIAS: { match: cb_send_flow_alias, new: FLOWSEQ_NEXT }
    
      PLAIN: { match: cb_flow_plain, new: FLOWSEQ_NEXT }
      PLAIN_MULTI: { match: cb_send_plain_multi, new: FLOWSEQ_NEXT }
    
      QUOTED: { match: cb_flowkey_quoted, new: FLOWSEQ_NEXT }
      QUOTED_MULTILINE: { match: cb_quoted_multiline, new: FLOWSEQ_NEXT }
    
    FLOWSEQ_NEXT:
      WS: { new: FLOWSEQ_NEXT }
      EOL: { new: FLOWSEQ_NEXT, return: 1 }
    
      FLOW_COMMA:
        match: cb_flow_comma
        return: 1
    
      FLOWSEQ_END:
        match: cb_end_flowseq
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
    
    FLOWMAP:
      FLOWSEQ_START: { match: cb_start_flowseq, new: NEWFLOWSEQ }
      FLOWMAP_START: { match: cb_start_flowmap, new: NEWFLOWMAP }
    
      ALIAS: { match: cb_send_alias, return: 1 }
    
      PLAIN: { match: cb_flowkey_plain, return: 1 }
      PLAIN_MULTI: { match: cb_send_plain_multi, return: 1 }
    
      QUOTED: { match: cb_flowkey_quoted, return: 1 }
      QUOTED_MULTILINE: { match: cb_quoted_multiline, return: 1 }
    
      COLON:
        WS:
          match: cb_empty_flow_mapkey
          new: RULE_FULLFLOWSCALAR
        EOL:
          match: cb_empty_flow_mapkey
          new: RULE_FULLFLOWSCALAR
          return: 1
    
    
    NEWFLOWSEQ:
      EOL: { new: NEWFLOWSEQ, return: 1 }
      WS: { new: NEWFLOWSEQ }
    
      ANCHOR:
        match: cb_anchor
        WS: { new: NEWFLOWSEQ_ANCHOR }
        EOL: { new: NEWFLOWSEQ_ANCHOR, return: 1 }
      TAG:
        match: cb_tag
        WS: { new: NEWFLOWSEQ_TAG }
        EOL: { new: NEWFLOWSEQ_TAG, return: 1 }
    
      FLOWSEQ_END:
        match: cb_end_flowseq
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
    
      DEFAULT: { new: FLOWSEQ }
    
    NODETYPE_FLOWSEQ:
      EOL: { new: NODETYPE_FLOWSEQ, return: 1 }
      WS: { new: NODETYPE_FLOWSEQ }
      FLOWSEQ_END:
        match: cb_end_flowseq
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
      DEFAULT: { new: NEWFLOWSEQ }
    
    NODETYPE_FLOWMAPVALUE:
      WS: { new: NODETYPE_FLOWMAPVALUE }
      EOL: { new: NODETYPE_FLOWMAPVALUE, return: 1 }
      COLON:
        match: cb_flow_colon
        WS: { new: RULE_FULLFLOWSCALAR }
        EOL: { new: RULE_FULLFLOWSCALAR, return: 1 }
        DEFAULT: { new: RULE_FULLFLOWSCALAR }
      FLOW_COMMA:
        match: cb_empty_flowmap_value
        return: 1
      FLOWMAP_END:
        match: cb_end_flowmap_empty
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
    
    NEWFLOWSEQ_ANCHOR:
      WS: { new: NEWFLOWSEQ_ANCHOR }
      EOL: { new: NEWFLOWSEQ_ANCHOR, return: 1 }
      TAG:
        match: cb_tag
        WS: { new: FLOWSEQ }
        EOL: { new: FLOWSEQ, return: 1 }
      DEFAULT: { new: FLOWSEQ }
    
    NEWFLOWSEQ_TAG:
      WS: { new: NEWFLOWSEQ_TAG }
      EOL: { new: NEWFLOWSEQ_TAG, return: 1 }
      ANCHOR:
        match: cb_anchor
        WS: { new: FLOWSEQ }
        EOL: { new: FLOWSEQ, return: 1 }
      DEFAULT: { new: FLOWSEQ }
    
    
    NEWFLOWMAP_ANCHOR:
      WS: { new: NEWFLOWMAP_ANCHOR }
      EOL: { new: NEWFLOWMAP_ANCHOR, return: 1 }
      TAG:
        match: cb_tag
        WS: { new: FLOWMAP }
        EOL: { new: FLOWMAP, return: 1 }
      DEFAULT: { new: FLOWMAP }
    
    NEWFLOWMAP_TAG:
      WS: { new: NEWFLOWMAP_TAG }
      EOL: { new: NEWFLOWMAP_TAG, return: 1 }
      ANCHOR:
        match: cb_anchor
        WS: { new: FLOWMAP }
        EOL: { new: FLOWMAP, return: 1 }
      DEFAULT: { new: FLOWMAP }
    
    NEWFLOWMAP:
      EOL: { new: NEWFLOWMAP, return: 1 }
      WS: { new: NEWFLOWMAP }
      # TODO
      QUESTION: { match: cb_flow_question, new: NEWFLOWMAP }
    
      ANCHOR:
        match: cb_anchor
        WS: { new: NEWFLOWMAP_ANCHOR }
        EOL: { new: NEWFLOWMAP_ANCHOR, return: 1 }
      TAG:
        match: cb_tag
        WS: { new: NEWFLOWMAP_TAG }
        EOL: { new: NEWFLOWMAP_TAG, return: 1 }
    
      FLOWMAP_END:
        match: cb_end_flowmap
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
    
      COLON:
        WS:
          match: cb_empty_flow_mapkey
          new: RULE_FULLFLOWSCALAR
        EOL:
          match: cb_empty_flow_mapkey
          new: RULE_FULLFLOWSCALAR
          return: 1
    
      DEFAULT: { new: FLOWMAP }
    
    NODETYPE_FLOWMAP:
      EOL: { new: NODETYPE_FLOWMAP, return: 1 }
      WS: { new: NODETYPE_FLOWMAP }
      FLOWMAP_END:
        match: cb_end_flowmap
        EOL: { return: 1 }
        DEFAULT: { return: 1 }
      FLOW_COMMA: { match: cb_flow_comma, new: NEWFLOWMAP }
      DEFAULT: { new: NEWFLOWMAP }
    
    
    RULE_MAPKEY:
      QUESTION:
        match: cb_question
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLNODE }
      ALIAS:
        match: cb_send_alias
        WS:
          COLON:
            EOL: { new: FULLNODE , return: 1}
            WS: { new: FULLMAPVALUE_INLINE }
    
      QUOTED:
        match: cb_take_quoted_key
        WS:
          COLON:
            EOL: { new: FULLNODE , return: 1}
            WS: { new: FULLMAPVALUE_INLINE }
        COLON:
          EOL: { new: FULLNODE , return: 1}
          WS: { new: FULLMAPVALUE_INLINE }
    
      PLAIN:
        match: cb_mapkey
        WS:
          COLON:
            match: cb_send_mapkey
            EOL: { new: FULLNODE , return: 1}
            WS: { new: FULLMAPVALUE_INLINE }
        COLON:
          match: cb_send_mapkey
          EOL: { new: FULLNODE , return: 1}
          WS: { new: FULLMAPVALUE_INLINE }
    
      COLON:
        match: cb_empty_mapkey
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLMAPVALUE_INLINE }
    
    NODETYPE_SEQ:
      DASH:
        match: cb_seqitem
        EOL: { new: FULLNODE , return: 1}
        WS: { new: FULLNODE }
    
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
    
      QUOTED:
        match: cb_take_quoted
        EOL: { match: cb_send_scalar, return: 1 }
    
      QUOTED_MULTILINE:
        match: cb_quoted_multiline
        EOL: { return: 1 }
    
      PLAIN:
        match: cb_start_plain
        EOL:
          match: cb_send_scalar
          return: 1
    
      PLAIN_MULTI:
        match: cb_send_plain_multi
        EOL: { return: 1 }
    
      BLOCK_SCALAR:
        match: cb_send_block_scalar
        EOL: { return: 1 }
    
      FLOWSEQ_START:
        match: cb_start_flowseq
        DEFAULT: { new: NEWFLOWSEQ }
    
      FLOWMAP_START:
        match: cb_start_flowmap
        DEFAULT: { new: NEWFLOWMAP }


    # END OF YAML INLINE

=cut
