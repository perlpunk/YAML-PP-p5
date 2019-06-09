#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;

my $yp = YAML::PP->new(
    cyclic_refs => 'fatal',
    schema => ['Failsafe'],
);

my $string = 'bar';
my $data = { foo => bless \$string, 'Foo' };
my $invalid = <<'EOM';
---
foo: @invalid
EOM

eval {
    $yp->load_string($invalid);
};
ok($@, "load invalid YAML");
eval {
    $yp->dump_string($data);
};
ok($@, "dump unsupported data");

my $clone = $yp->clone;

my $valid = <<'EOM';
---
foo: bar
EOM

my $valid_data = { foo => 'bar' };
my $load = $clone->load_string($valid);
is_deeply($load, $valid_data, "Second load ok");

my $dump = $clone->dump_string($load);
my $exp_dump = <<'EOM';
---
foo: bar
EOM
cmp_ok($dump, 'eq', $exp_dump, "Second dump ok");


done_testing;
