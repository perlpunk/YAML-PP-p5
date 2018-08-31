#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use YAML::PP::Dumper;

my $hash = { a => "b" };
my $seq = [ "a", "b" ];
my $data1 = {
    hash => $hash,
    hashcopy => $hash,
    seq => $seq,
    seqcopy => $seq,
};

my $exp_yaml1 = <<"EOM";
---
hash: &1
  a: b
hashcopy: *1
seq: &2
- a
- b
seqcopy: *2
EOM

my $refa = { name => "a" };
my $refb = { name => "b", link => $refa };
$refa->{link} = $refb;
my $data2 = {
    a => $refa,
    b => $refb,
};

# cyclic
my $exp_yaml2 = <<"EOM";
---
a: &1
  link: &2
    link: *1
    name: b
  name: a
b: *2
EOM

my $yppd = YAML::PP::Dumper->new;
my $yaml = $yppd->dump_string($data1);
cmp_ok($yaml, 'eq', $exp_yaml1, "dump anchors");

$yaml = $yppd->dump_string($data2);
cmp_ok($yaml, 'eq', $exp_yaml2, "dump cyclic data structure");

done_testing;
