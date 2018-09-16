#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use YAML::PP::Test;
use Data::Dumper;
use YAML::PP::Parser;
use YAML::PP::Emitter;
use YAML::PP::Writer;
use Encode;

$ENV{YAML_PP_RESERVED_DIRECTIVE} = 'ignore';

$|++;

my $yts = "$Bin/../yaml-test-suite";

# skip tests that parser can't parse
my @skip = qw/
    4ABK 87E4 8CWC 8UDB 9MMW
    C2DT CN3R CT4Q DFF7
    FRK4
    KZN9 L9U5 LQZ7 LX3P
    Q9WF QF4Y
    UT92 WZ62

    6BFJ
    F6MC

/;

# emitter
push @skip, qw/
/;
# quoting
push @skip, qw/
36F6
82AN
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
EXG3
JDH8
MJS9


/;
# unicode
push @skip, qw/
H3Z8
/;

my $testsuite = YAML::PP::Test->new(
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
    valid => 1,
    in_yaml => 1,
    emit_yaml => 1,
);

my %skip_yaml_equal = (
    '4MUZ' => 1,
    '7ZZ5' => 1,
    'K858' => 1,
    'X38W' => 1,
    'Q5MG' => 1,
    'G4RS' => 1,
    '9DXL' => 1,
    '6ZKB' => 1,
    '6SLA' => 1,
    '6CK3' => 1,
    '5TYM' => 1,
    '565N' => 1,
);

my ($testcases) = $testsuite->read_tests(
    skip => \@skip,
);

$testsuite->run_testcases(
    code => \&test,
);

$testsuite->print_stats(
    count => [qw/ SAME_EVENTS SAME_YAML DIFF_EVENTS DIFF_YAML ERROR TODO SKIP /],
    ids => [qw/ DIFF_YAML DIFF_EVENTS /],
);

sub test {
    my ($testsuite, $testcase) = @_;
    my $id = $testcase->{id};

    my $result = $testsuite->emit_yaml($testcase);
    if ($skip_yaml_equal{ $id }) {
        delete $result->{emit_yaml};
    }
    $testsuite->compare_emit_yaml($testcase, $result);
}


done_testing;
exit;

