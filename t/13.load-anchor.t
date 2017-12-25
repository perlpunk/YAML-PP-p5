#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;

my $yaml = <<'EOM';
foo: &sequence
    - a
    - b
    - c
bar: *sequence
copies:
- &alias A
- *alias
EOM

my $data = YAML::PP->new->load_string($yaml);
cmp_ok($data->{copies}->[0],'eq', 'A', "Scalar anchor");
cmp_ok($data->{copies}->[0],'eq', $data->{copies}->[1], "Scalar alias equals anchor");

$data->{foo}->[-1] = "changed";

cmp_ok($data->{bar}->[-1],'eq', 'changed', "Alias changes when anchor changes");

done_testing;
