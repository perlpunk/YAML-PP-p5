#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin '$Bin';
use lib "$Bin/lib";
use YAML::PP::Test;
use YAML::PP;
use Data::Dumper;

my $in = <<'EOM';
---
a:
 b:
  c: d
list:
- 1
- x: 2
  y: 3
nested1:
- - a
  - b
nested2:
- - a
- b
EOM

my $out_expected1 = <<'EOM';
---
a:
 b:
  c: d
list:
- 1
- x: 2
  y: 3
nested1:
- - a
  - b
nested2:
- - a
- b
EOM
my $out_expected4 = <<'EOM';
---
a:
    b:
        c: d
list:
- 1
-   x: 2
    y: 3
nested1:
-   - a
    - b
nested2:
-   - a
- b
EOM

my @events;
my $parser = YAML::PP::Parser->new(
    receiver => sub {
        my ($parser, $name, $info) = @_;
        push @events, $info;
    },
);

$parser->parse_string( $in );
my $writer = YAML::PP::Writer->new;
my $emitter = YAML::PP::Emitter->new( indent => 1);
$emitter->set_writer($writer);
$emitter->init;
for my $event (@events) {
    my $type = $event->{name};
    $emitter->$type($event);
}
my $out1 = $emitter->writer->output;
cmp_ok($out1, 'eq', $out_expected1, "Emitting with indent 1");

$emitter->set_indent(4);

$emitter->init;
for my $event (@events) {
    my $type = $event->{name};
    $emitter->$type($event);
}
my $out4 = $emitter->writer->output;
cmp_ok($out4, 'eq', $out_expected4, "Emitting with indent 4");


$ENV{YAML_PP_RESERVED_DIRECTIVE} = 'ignore';

$|++;

my $yts = "$Bin/../test-suite/yaml-test-suite-data";

# skip tests that parser can't parse
my @skip = qw/
    4FJ6 4ABK 87E4 8CWC 8UDB 9MMW
    CN3R CT4Q
    FRK4
    L9U5 LQZ7 LX3P
    Q9WF QF4Y

    6BFJ
    F6MC
    NB6Z
    CFD4

/;

# emitter
push @skip, qw/
/;
# quoting
push @skip, qw/
36F6
9YRD
HS5T
EX5H
NAT4
/;
# tags
push @skip, qw/
v014
/;
# block scalar
push @skip, qw/
4QFQ
6VJK
7T8X

R4YG
/;

# test
push @skip, qw/
XLQ9
K54U
PUW8
3MYT
MJS9


/;
# TODO fix testsuite
# 4QFQ

# unicode
push @skip, qw/
H3Z8
/;
push @skip, qw/
    X38W
/;

my $testsuite = YAML::PP::Test->new(
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
    valid => 1,
    in_yaml => 1,
    emit_yaml => 1,
);

my %skip_yaml_equal = (

    'X38W' => 1,
    'G4RS' => 1,
    '6CK3' => 1,
    '5TYM' => 1,
    '565N' => 1,
    # fix testsuite
    'K858' => 1,
    '4MUZ' => 1,
    '8KB6' => 1,
    '9BXH' => 1,
    '6ZKB' => 1,
    '6SLA' => 1,
    '9DXL' => 1,
);

my ($testcases) = $testsuite->read_tests(
    skip => \@skip,
);

my $indent = 1;
subtest "indent-$indent" => sub {
    $testsuite->run_testcases(
        code => sub { test(@_, $indent) },
    );
};
subtest "indent-$indent" => sub {
    $indent = 3;
    $testsuite->run_testcases(
        code => sub { test(@_, $indent) },
    );
};
subtest "indent-$indent" => sub {
    $indent = 4;
    $testsuite->run_testcases(
        code => sub { test(@_, $indent) },
    );
};

$testsuite->print_stats(
    count => [qw/ SAME_EVENTS SAME_YAML DIFF_EVENTS DIFF_YAML ERROR TODO SKIP /],
    ids => [qw/ DIFF_YAML DIFF_EVENTS /],
);

sub test {
    my ($testsuite, $testcase, $indent) = @_;
    my $id = $testcase->{id};

    my $result = $testsuite->emit_yaml($testcase, { indent => $indent });
    delete $result->{emit_yaml};
    $testsuite->compare_emit_yaml($testcase, $result);
}




done_testing;

