#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin '$Bin';
use lib "$Bin/lib";

use YAML::PP::Test;
use YAML::PP;
use YAML::PP::Parser;
use Data::Dumper;

$ENV{YAML_PP_RESERVED_DIRECTIVE} = 'ignore';

$|++;

my $yts = "$Bin/../test-suite/yaml-test-suite-data";

my @skip = qw/
    4FJ6 87E4 8CWC 8UDB 9MMW
    CN3R CT4Q
    L9U5 LQZ7 LX3P
    Q9WF QF4Y

    6BFJ
    CFD4

/;

my $testsuite = YAML::PP::Test->new(
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
    valid => 1,
    in_yaml => 1,
);

my ($testcases) = $testsuite->read_tests(
    skip => \@skip,
);

$testsuite->run_testcases(
    code => \&test,
);

sub test {
    my ($testsuite, $testcase) = @_;

    my $result = $testsuite->parse_tokens($testcase);

    $testsuite->compare_tokens($testcase, $result);
    return $result;
}

done_testing;

