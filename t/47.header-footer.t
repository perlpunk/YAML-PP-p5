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

subtest require_footer => sub {
    my $good1 = <<'EOM';
a: 1
...
EOM
    my $good2 = <<'EOM';
a: 1
...
---
a: 2
...
EOM
    my $bad1 = <<'EOM';
a: 1
---
a: 2
...
EOM
    my $bad2 = <<'EOM';
a: 1
...
---
a: 2
EOM
    my $bad3 = <<'EOM';
a: 1
---
a: 2
EOM
    my $yp = YAML::PP->new( require_footer => 1 );
    my $data;
    local $@;

    $data = eval { $yp->load_string($good1) };
    is $@, '', "good 1";
    $data = eval { $yp->load_string($good2) };
    is $@, '', "good 2";

    my $re = qr{Document .\d+. did not end with '...' .require_footer=1.};
    $data = eval { $yp->load_string($bad1) };
    like $@, $re, "bad 1";
    $data = eval { $yp->load_string($bad1) };
    like $@, $re, "bad 2";
    $data = eval { $yp->load_string($bad1) };
    like $@, $re, "bad 3";
};

done_testing;

