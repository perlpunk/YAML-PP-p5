#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAML::PP;
use YAML::PP::Common qw/ :PRESERVE /;

use FindBin '$Bin';
use lib "$Bin/lib";

my $yp = YAML::PP->new(
    schema => [qw/ :MySchema /],
    preserve => PRESERVE_ORDER,
);

my $yaml = <<'EOM';
---
o1: !Class1
  z: 1
  a: 2
  y: 3
  b: 4
EOM

my $data = $yp->load_string($yaml);

$yaml = $yp->dump_string($data);

cmp_ok($yaml, 'eq', <<EOY, '$data serializes with the schema in t/lib/MySchema.pm');
---
o1: !Class1
  id: 23
  z: 1
  a: 2
  y: 3
  b: 4
EOY

done_testing;
