#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;
use Test::Deep;

# https://yaml.org/type/merge.html

my $yp = YAML::PP->new(
    schema => [qw/ JSON Merge /],
);

subtest merge => sub {

    my $yaml = <<'EOM';
---
- &CENTER { x: 1, y: 2 }
- &LEFT { x: 0, y: 2 }
- &BIG { r: 10 }
- &SMALL { r: 1 }

# All the following maps are equal:

- # Explicit keys
  x: 1
  y: 2
  r: 10
  label: center/big

- # Merge one map
  << : *CENTER
  r: 10
  label: center/big

- # Merge multiple maps
  << : [ *CENTER, *BIG ]
  label: center/big

- # Override
  << : [ *BIG, *LEFT, *SMALL ]
  x: 1
  label: center/big
EOM

    my $data = $yp->load_string($yaml);

    my $expected = {
        label => 'center/big',
        x => 1,
        y => 2,
        r => 10,
    };

    is_deeply($data->[4], $expected, "Merge: Explicit keys");
    is_deeply($data->[5], $expected, "Merge: Merge one map");
    is_deeply($data->[6], $expected, "Merge: Merge multiple maps");
    is_deeply($data->[7], $expected, "Merge: Override");
};

subtest errors => sub {
    my $error1 = <<'EOM';
---
scalar: &scalar test
merge:
  <<: *scalar
EOM

    my $error2 = <<'EOM';
---
scalar: &scalar test
merge:
  <<: [*scalar]
EOM

    my $error3 = <<'EOM';
---
list: &list [23]
merge:
  <<: [*list]
EOM

    eval {
        my $data = $yp->load_string($error1);
    };
    my $error = $@;
    cmp_ok($error, '=~', qr{Expected hash}, "Merge: invalid scalar");

    eval {
        my $data = $yp->load_string($error2);
    };
    $error = $@;
    cmp_ok($error, '=~', qr{Expected hash}, "Merge: invalid scalar");

    eval {
        my $data = $yp->load_string($error3);
    };
    $error = $@;
    cmp_ok($error, '=~', qr{Expected hash}, "Merge: invalid list");
};

done_testing;
