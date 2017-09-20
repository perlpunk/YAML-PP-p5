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
FALSE: false
TRUE: true
EOM

SKIP: {
    skip "boolean not installed", 1 unless $boolean;
    my $data = {
        TRUE => JSON::PP::true(),
        FALSE => JSON::PP::false(),
    };
    my $yppd = YAML::PP::Dumper->new(boolean => 'boolean');
    my $yaml = $yppd->dump_string($data);
    cmp_ok($yaml, 'eq', $exp_yaml, "boolean.pm dump");
}

SKIP: {
    skip "JSON::PP not installed", 1 unless $json_pp;
    my $data = {
        TRUE => JSON::PP::true(),
        FALSE => JSON::PP::false(),
    };
    my $yppd = YAML::PP::Dumper->new(boolean => 'JSON::PP');
    my $yaml = $yppd->dump_string($data);
    cmp_ok($yaml, 'eq', $exp_yaml, "JSON::PP::Boolean dump");
}

done_testing;
