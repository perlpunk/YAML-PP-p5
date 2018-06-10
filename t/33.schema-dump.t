#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 6;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;
my $boolean = eval "use boolean; 1";
my $json_pp = eval "use JSON::PP; 1";

my $data_common = [
    # quoted
    "",
    '@array',
    "`cmd`",
    "!string",
    "*string",
    "- a",
    "? x",
    "foo: bar",
    "#no comment",
    "also #no comment",
    "foo\nbar",
    "x\ty\rz",
    "string:",
    "string ",
    "string\t",
    "'string",
    "x\n\"y\\z",
    # not quoted
    "string",
    "^string",
    'x"y',
    'foo\bar',
    "string#",
    !1,
];
my $yaml_common = <<'EOM';
---
- ''
- '@array'
- '`cmd`'
- '!string'
- '*string'
- '- a'
- '? x'
- 'foo: bar'
- '#no comment'
- 'also #no comment'
- |-
  foo
  bar
- "x\ty\rz"
- 'string:'
- 'string '
- "string\t"
- '''string'
- |-
  x
  "y\z
- string
- ^string
- x"y
- foo\bar
- string#
- ''
EOM

my $data_failsafe = [
    1,
    3.14159,
    42.0,
    undef,
    "~",
    "0",
    "3.14159",
    "0x10",
    "0o7",
    "1e23",
    "true",
    "false",
    "null",
    "NULL",
    "TRUE",
    "False",
];
my $yaml_failsafe = <<'EOM';
---
- 1
- 3.14159
- 42
- ''
- ~
- 0
- 3.14159
- 0x10
- 0o7
- 1e23
- true
- false
- null
- NULL
- TRUE
- False
EOM

my $data_json = $data_failsafe;
my $yaml_json = <<'EOM';
---
- 1
- 3.14159
- 42.0
- null
- ~
- '0'
- '3.14159'
- 0x10
- 0o7
- '1e23'
- 'true'
- 'false'
- 'null'
- NULL
- TRUE
- False
EOM
my $data_core = [@$data_json];
push @$data_core, (
    0+"inf",
    0-"inf",
    0+"nan",
);
my $yaml_core = <<'EOM';
---
- 1
- 3.14159
- 42.0
- null
- '~'
- '0'
- '3.14159'
- '0x10'
- '0o7'
- '1e23'
- 'true'
- 'false'
- 'null'
- 'NULL'
- 'TRUE'
- 'False'
- .inf
- -.inf
- .nan
EOM

my $yaml_boolean = <<'EOM';
---
- true
- false
EOM

subtest common => sub {
    my $ypp = YAML::PP->new(
        schema => ['Failsafe'],
    );
    my $yaml = $ypp->dump_string($data_common);
    #diag "YAML:\n$yaml";
    cmp_ok($yaml, 'eq', $yaml_common, "Common quoted and unquoted scalars (Failsafe)");

    $ypp = YAML::PP->new(
        schema => ['JSON'],
    );
    $yaml = $ypp->dump_string($data_common);
    #diag "YAML:\n$yaml";
    cmp_ok($yaml, 'eq', $yaml_common, "Common quoted and unquoted scalars (JSON)");

    $ypp = YAML::PP->new(
        schema => ['Core'],
    );
    $yaml = $ypp->dump_string($data_common);
    #diag "YAML:\n$yaml";
    cmp_ok($yaml, 'eq', $yaml_common, "Common quoted and unquoted scalars (Core)");
};

subtest failsafe => sub {
    my $ypp = YAML::PP->new(
        schema => ['Failsafe'],
    );
    my $yaml = $ypp->dump_string($data_failsafe);
    #diag "YAML:\n$yaml";
    cmp_ok($yaml, 'eq', $yaml_failsafe, "Schema Failsafe dump");
};

subtest json => sub {
    my $ypp = YAML::PP->new(
        schema => ['JSON'],
    );
    my $yaml = $ypp->dump_string($data_json);
    #diag "YAML:\n$yaml";
    cmp_ok($yaml, 'eq', $yaml_json, "Schema JSON dump");
};

subtest core => sub {
    my $ypp = YAML::PP->new(
        schema => ['Core'],
    );
    my $yaml = $ypp->dump_string($data_core);
    #diag "YAML:\n$yaml";
    cmp_ok($yaml, 'eq', $yaml_core, "Schema Core dump");
};

SKIP: {
    skip "boolean not installed", 1 unless $boolean;
    my $data_boolean = [
        boolean::true(),
        boolean::false(),
    ];
    subtest bool_boolean => sub {
        my $ypp = YAML::PP->new(
            boolean => 'boolean',
            schema => ['JSON'],
        );
        my $yaml = $ypp->dump_string($data_boolean);
        #diag "YAML:\n$yaml";
        cmp_ok($yaml, 'eq', $yaml_boolean, "boolean.pm dump");
    };
}

SKIP: {
    skip "JSON::PP not installed", 1 unless $json_pp;
    my $data_jsonpp = [
        JSON::PP::true(),
        JSON::PP::false(),
    ];
    subtest bool_jsonpp => sub {
        my $ypp = YAML::PP->new(
            boolean => 'JSON::PP',
            schema => ['JSON'],
        );
        my $yaml = $ypp->dump_string($data_jsonpp);
        #diag "YAML:\n$yaml";
        cmp_ok($yaml, 'eq', $yaml_boolean, "boolean.pm dump");
    };
}

