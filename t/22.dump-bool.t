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
    skip "JSON::PP and boolean not installed", 2 unless ($json_pp and $boolean);
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

SKIP: {
    skip "JSON::PP and boolean not installed", 6 unless ($json_pp and $boolean);
    my @tests = (
        'JSON::PP,boolean',
        'boolean,JSON::PP',
        'boolean,*',
        'JSON::PP,*',
        '*',
        'perl,*',
    );

    my $data = {
        "true1" => boolean::true(),
        "false1" => boolean::false(),
        "true2" => JSON::PP::true(),
        "false2" => JSON::PP::false(),
    };
    for my $test (@tests) {
        my $yppd = YAML::PP->new(boolean => $test);
        my $yaml = $yppd->dump_string($data);
        my $exp_json_pp = <<'EOM';
---
false1: false
false2: false
true1: true
true2: true
EOM
        cmp_ok($yaml, 'eq', $exp_json_pp, "$test dump");
    }

}

SKIP: {
    skip "perl version < v5.36", 1 unless $] >= 5.036000;
    my $data = {
        "true1" => !!1,
        "false1" => !!0,
    };
    my $yppd = YAML::PP->new(boolean => 'perl_experimental');
    my $yaml = $yppd->dump_string($data);
    my $exp_json_pp = <<'EOM';
---
false1: false
true1: true
EOM
    cmp_ok($yaml, 'eq', $exp_json_pp, "perl_experimental dump");
}
SKIP: {
    skip "perl version < v5.36", 1 unless $] >= 5.036000;
    my $data = {
        "true1" => !!1,
        "false1" => !!0,
    };
    my $yppd = YAML::PP->new(boolean => '');
    my $yaml = $yppd->dump_string($data);
    my $exp_json_pp = <<'EOM';
---
false1: ''
true1: 1
EOM
    cmp_ok($yaml, 'eq', $exp_json_pp, "no booleans dump");
}

SKIP: {
    skip "perl version < v5.36", 3 unless $] >= 5.036000;
    skip "JSON::PP and boolean not installed", 3 unless ($json_pp and $boolean);

    my @tests = (
        'perl_experimental,JSON::PP,boolean',
        'perl_experimental,boolean,JSON::PP',
        'perl_experimental,*',
    );

    my $data = {
        "true1" => boolean::true(),
        "false1" => boolean::false(),
        "true2" => JSON::PP::true(),
        "false2" => JSON::PP::false(),
        "true3" => !!1,
        "false3" => !!0,
    };
    for my $test (@tests) {
        my $yppd = YAML::PP->new(boolean => $test);
        my $yaml = $yppd->dump_string($data);
        my $exp_json_pp = <<'EOM';
---
false1: false
false2: false
false3: false
true1: true
true2: true
true3: true
EOM
        cmp_ok($yaml, 'eq', $exp_json_pp, "$test dump");
    }

}

done_testing;
