#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use YAML::PP;
use Data::Dumper;

my $in = <<'EOM';
--- foo
---
a: 1
---
- a
- b
...
EOM

subtest header_no_footer => sub {
    my $out_expected = <<'EOM';
--- foo
---
a: 1
---
- a
- b
EOM

    my $yp = YAML::PP->new(
        header => 1,
        footer => 0,
    );

    my @docs = $yp->load_string($in);
    my $out = $yp->dump_string(@docs);
    cmp_ok($out, 'eq', $out_expected, "Dumping with indent");
};

subtest no_header_no_footer => sub {
    my $out_expected = <<'EOM';
foo
---
a: 1
---
- a
- b
EOM

    my $yp = YAML::PP->new(
        header => 0,
        footer => 0,
    );

    my @docs = $yp->load_string($in);
    my $out = $yp->dump_string(@docs);
    cmp_ok($out, 'eq', $out_expected, "Dumping with indent");
};

subtest header_footer => sub {
    my $out_expected = <<'EOM';
--- foo
...
---
a: 1
...
---
- a
- b
...
EOM

    my $yp = YAML::PP->new(
        header => 1,
        footer => 1,
    );

    my @docs = $yp->load_string($in);
    my $out = $yp->dump_string(@docs);
    cmp_ok($out, 'eq', $out_expected, "Dumping with indent");
};

subtest no_header_footer => sub {
    my $out_expected = <<'EOM';
foo
...
---
a: 1
...
---
- a
- b
...
EOM

    my $yp = YAML::PP->new(
        header => 0,
        footer => 1,
    );

    my @docs = $yp->load_string($in);
    my $out = $yp->dump_string(@docs);
    cmp_ok($out, 'eq', $out_expected, "Dumping with indent");
};


done_testing;

