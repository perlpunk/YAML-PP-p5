#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;
my $ixhash = eval { require Tie::IxHash };
unless ($ixhash) {
    plan skip_all => "Tie::IxHash not installed";
    exit;
}

my $tests = require "$Bin/../examples/schema-ixhash.pm";

my $yp = YAML::PP->new(
    schema => [qw/ JSON Perl Tie::IxHash /],
);

my @tests = sort keys %$tests;
for my $name (@tests) {
    my $test = $tests->{ $name };
    my ($code, $yaml) = @$test;
    my $data = eval $code;
    my $out = $yp->dump_string([$data, $data]);
    if (ref $yaml) {
        cmp_ok($out, '=~', $yaml, "$name: dump_string()");
    }
    else {
        cmp_ok($out, 'eq', $yaml, "$name: dump_string()");
    }
}

done_testing;
