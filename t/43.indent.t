#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use YAML::PP;
use Data::Dumper;

my $in = <<'EOM';
---
a:
 b:
  c: d
list:
- 1
- 2
EOM
my $out_expected = <<'EOM';
---
a:
    b:
        c: d
list:
- 1
- 2
EOM

my $yp = YAML::PP->new(
    indent => 4,
);

my $data = $yp->load_string($in);
my $out = $yp->dump_string($data);
cmp_ok($out, 'eq', $out_expected, "Dumping with indent");

done_testing;

