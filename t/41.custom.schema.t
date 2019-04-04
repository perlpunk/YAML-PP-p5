#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAML::PP;

use FindBin '$Bin';
use lib "$Bin/lib";

my $yp = YAML::PP->new(
    schema => [qw/ :MySchema /],
);

my $data = {
  o1 => (bless {}, 'Class1'),
};

my $yaml = $yp->dump_string($data);

cmp_ok($yaml, 'eq', <<EOY, '$data serializes with the schema in t/lib/MySchema.pm');
---
o1: !Class1 ''
EOY

done_testing;
