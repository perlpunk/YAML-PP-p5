#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use YAML::PP::Dumper;
my $boolean = eval "use boolean; 1";
my $json_pp = eval "use JSON::PP; 1";

my $exp_yaml = <<"EOM";
---
false1: false
false2: false
true1: true
true2: true
EOM

SKIP: {
    skip "boolean not installed", 1 unless $boolean;
    my $data = {
        "true1" => boolean::true(),
        "false1" => boolean::false(),
        "true2" => boolean::true(),
        "false2" => boolean::false(),
    };
    my $yppd = YAML::PP->new(boolean => 'boolean');
    my $yaml = $yppd->dump_string($data);
    cmp_ok($yaml, 'eq', $exp_yaml, "boolean.pm dump");
}

SKIP: {
    skip "JSON::PP not installed", 1 unless $json_pp;
    my $data = {
        "true1" => JSON::PP::true(),
        "false1" => JSON::PP::false(),
        "true2" => JSON::PP::true(),
        "false2" => JSON::PP::false(),
    };
    my $yppd = YAML::PP->new(boolean => 'JSON::PP');
    my $yaml = $yppd->dump_string($data);
    cmp_ok($yaml, 'eq', $exp_yaml, "JSON::PP::Boolean dump");
}

SKIP: {
    skip "JSON::PP and boolean not installed", 1 unless ($json_pp and $boolean);
    my $data = {
        "true1" => boolean::true(),
        "false1" => boolean::false(),
        "true2" => JSON::PP::true(),
        "false2" => JSON::PP::false(),
    };

    my $yppd = YAML::PP->new(boolean => 'JSON::PP', schema => [qw/ + Perl /]);
    my $yaml = $yppd->dump_string($data);
    my $exp_json_pp = <<'EOM';
---
false1: !perl/scalar:boolean
  =: 0
false2: false
true1: !perl/scalar:boolean
  =: 1
true2: true
EOM
    cmp_ok($yaml, 'eq', $exp_json_pp, "JSON::PP::Boolean (no boolean) dump");

    $yppd = YAML::PP->new(boolean => 'boolean', schema => [qw/ + Perl /]);
    $yaml = $yppd->dump_string($data);
    my $exp_boolean = <<'EOM';
---
false1: false
false2: !perl/scalar:JSON::PP::Boolean
  =: 0
true1: true
true2: !perl/scalar:JSON::PP::Boolean
  =: 1
EOM
    cmp_ok($yaml, 'eq', $exp_boolean, "boolean (no JSON::PP::Boolean) dump");
}

done_testing;
