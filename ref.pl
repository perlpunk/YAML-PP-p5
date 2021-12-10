#!/usr/bin/env perl
use strict;
use warnings;
use 5.020;
use Data::Dumper;
use YAML::PP::Ref;

my $ypp = YAML::PP->new( parser => YAML::PP::Ref->new );

my $yaml = <<'EOM';
---
foo:
- bar
- boo
EOM
my $data = $ypp->load_string($yaml);
warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$data], ['data']);
