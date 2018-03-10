#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 3;
use FindBin '$Bin';
use B ();
use Data::Dumper;
use YAML::PP;

my $failsafe = <<"EOM";
# just strings
---
- a string
- true
- false
- 23
- null
- # empty
EOM

my $failsafe_expected = [ "a string", "true", "false", "23", "null", "" ];

my $json = <<'EOM';
# json
---
booltrue: [ true ]
boolfalse: [ false ]
nulls:
- null
empty:
- # empty
ints: [ 0, -0, 1, -1, 42, -42 ]
floats: [ 0.3e3, -3.14 ]
...
# tags
---
- !!null
- !!null null
- !!bool true
- !!int -42
- !!float 0.3e3
- !!str # empty
- !!str true
...
# strings
---
[ TRUE, False, ~, +3.14, +3, .42 ]
EOM

my $json_expected = [
    {
        boolfalse => [ '' ],
        booltrue => [ 1 ],
        floats => [ 300.0, -3.14 ],
        ints => [ 0, 0, 1, -1, 42, -42 ],
        nulls => [ undef ],
        empty => [''],
    },
    [ undef, undef, 1, -42, 300.0, '', "true" ],
    [ "TRUE", "False", "~", "+3.14", "+3", ".42" ],
];

my $core = <<"EOM";
# core
---
booltrue: [ true, True, TRUE ]
boolfalse: [ false, False, FALSE ]
nulls:
- null
- Null
- NULL
- ~
- # empty
ints: [ 0, +0, -0, +1, -1, 42, -42, +42 ]
floats: [ .0, 0.0, .3e3, .3E-1, 3.3e+3, 0.3e3, -3.14, +3.14 ]
octal: [ 0o0, 0o7, 0o10 ]
hex: [ 0x0, 0xa, 0x10 ]
...
# tags
---
- !!null
- !!null null
- !!null ~
- !!bool true
- !!int +42
- !!int 0x42
- !!float +0.3e3
- !!str # empty
- !!str true
# strings
---
- yes
- no

EOM

my $core_expected = [
    {
        boolfalse => [ '', '', '' ],
        booltrue => [ 1, 1, 1 ],
        floats => [ 0.0, 0.0, 300.0, 0.03, 3300.0, 300.0, -3.14, 3.14 ],
        hex => [ 0, 10, 16 ],
        ints => [ 0, 0, 0, 1, -1, 42, -42, 42 ],
        nulls => [ undef, undef, undef, undef, undef ],
        octal => [ 0, 7, 8 ],
    },
    [ undef, undef, undef, 1, 42, 66, 300.0, '', "true" ],
    [ "yes", "no" ],
];

subtest failsafe => sub {
    my $ypp = YAML::PP->new(
        boolean => 'perl',
        schema => ['Failsafe'],
    );
    my $data = $ypp->load_string($failsafe);
    for my $string (@$data) {
        test_string($string);
    }
    is_deeply($data, $failsafe_expected, "Failsafe data looks like expected");
};

subtest json => sub {
    my $ypp = YAML::PP->new(
        boolean => 'perl',
        schema => ['JSON'],
    );
    my @docs = $ypp->load_string($json);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@docs], ['docs']);
    my $data_json = $docs[0];
    my $data_json_tags = $docs[1];
    my $strings = $docs[2];
    my $ints = $data_json->{ints};
    my $floats = $data_json->{floats};
    my $nulls = $data_json->{nulls};
    my $booltrue = $data_json->{booltrue};
    my $boolfalse = $data_json->{boolfalse};

    for my $string (@$strings) {
        test_string($string);
    }
    for my $int (@$ints) {
        test_int($int);
    }
    for my $float (@$floats) {
        test_float($float);
    }
    for my $null (@$nulls) {
        test_undef($null);
    }
    for my $bool (@$booltrue) {
        test_booltrue($bool);
    }
    for my $bool (@$boolfalse) {
        test_boolfalse($bool);
    }
    is_deeply(\@docs, $json_expected, "JSON data looks like expected");
};

subtest core => sub {
    my $ypp = YAML::PP->new(
        boolean => 'perl',
        schema => ['Core'],
    );
    my @docs = $ypp->load_string($core);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@docs], ['docs']);
    my $data_json = $docs[0];
    my $data_json_tags = $docs[1];
    my $strings = $docs[2];
    my $ints = $data_json->{ints};
    my $floats = $data_json->{floats};
    my $nulls = $data_json->{nulls};
    my $booltrue = $data_json->{booltrue};
    my $boolfalse = $data_json->{boolfalse};
    my $oct = $data_json->{octal};
    my $hex = $data_json->{hex};

    for my $string (@$strings) {
        test_string($string);
    }
    for my $int (@$ints) {
        test_int($int);
    }
    for my $float (@$floats) {
        test_float($float);
    }
    for my $null (@$nulls) {
        test_undef($null);
    }
    for my $bool (@$booltrue) {
        test_booltrue($bool);
    }
    for my $bool (@$boolfalse) {
        test_boolfalse($bool);
    }
    for my $o (@$oct) {
        test_int($o);
    }
    for my $h (@$hex) {
        test_int($h);
    }
    is_deeply(\@docs, $core_expected, "Core data looks like expected");
};

done_testing;

sub test_string {
    my ($item) = @_;
    my $flags = B::svref_2object(\$item)->FLAGS;
    ok($flags & B::SVp_POK, sprintf("'%s' has string flag", $item));
    ok(not($flags & B::SVp_IOK), sprintf("'%s' does not have int flag", $item));
}

sub test_int {
    my ($item) = @_;
    my $flags = B::svref_2object(\$item)->FLAGS;
    ok(not($flags & B::SVp_POK), sprintf("'%s' does not have string flag", $item));
    ok($flags & B::SVp_IOK, sprintf("'%s' has int flag", $item));
}

sub test_float {
    my ($item) = @_;
    my $flags = B::svref_2object(\$item)->FLAGS;
    ok(not($flags & B::SVp_POK), sprintf("'%s' does not have string flag", $item));
    ok($flags & B::SVp_NOK, sprintf("'%s' has double flag", $item));
}

sub test_undef {
    my ($item) = @_;
    ok(not(defined $item), "null value is undefined");
}

sub test_booltrue {
    my ($bool) = @_;
    cmp_ok($bool, 'eq', '1', "boolean true equals '1'");
}

sub test_boolfalse {
    my ($bool) = @_;
    cmp_ok($bool, 'eq', '', "boolean false equals ''");
}

