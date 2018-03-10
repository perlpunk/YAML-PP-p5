#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use FindBin '$Bin';
use YAML::PP::Dumper;
my $boolean = eval "use boolean; 1";
my $json_pp = eval "use JSON::PP; 1";

my $exp_yaml = <<"EOM";
---
bool false: false
bool true: true
EOM

SKIP: {
    skip "boolean not installed", 1 unless $boolean;
    my $data = {
        "bool true" => boolean::true(),
        "bool false" => boolean::false(),
    };
    my $yppd = YAML::PP::Dumper->new(boolean => 'boolean');
    my $yaml = $yppd->dump_string($data);
    cmp_ok($yaml, 'eq', $exp_yaml, "boolean.pm dump");
}

SKIP: {
    skip "JSON::PP not installed", 1 unless $json_pp;
    my $data = {
        "bool true" => JSON::PP::true(),
        "bool false" => JSON::PP::false(),
    };
    my $yppd = YAML::PP::Dumper->new(boolean => 'JSON::PP');
    my $yaml = $yppd->dump_string($data);
    cmp_ok($yaml, 'eq', $exp_yaml, "JSON::PP::Boolean dump");
}

done_testing;
