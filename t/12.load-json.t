#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use Data::Dumper;
use YAML::PP::Test;
use YAML::PP;
use Encode;

$ENV{YAML_PP_RESERVED_DIRECTIVE} = 'ignore';

my $json_pp = eval "use JSON::PP; 1";
unless ($json_pp) {
    plan skip_all => "JSON::PP not installed";
    exit;
}

my $yts = "$Bin/../yaml-test-suite";


$|++;

my @skip = qw/
    87E4
    8CWC
    8UDB
    C2DT
    CN3R
    CT4Q
    L9U5
    LQZ7
    QF4Y

    UT92
    WZ62

/;

my $testsuite = YAML::PP::Test->new(
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
    valid => 1,
    in_json => 1,
    in_yaml => 1,
);

my ($testcases) = $testsuite->read_tests(
    skip => \@skip,
);

$testsuite->run_testcases(
    code => \&test,
);

my $results = $testsuite->{stats};
diag sprintf "OK: %d DIFF: %d ERROR: %d TODO: %d SKIP: %d",
    $results->{OK}, $results->{DIFF}, $results->{ERROR},
    $results->{TODO}, $results->{SKIP};
diag "DIFF: (@{ $results->{DIFFS} })" if $results->{DIFF};

done_testing;
exit;

sub test {
    my ($testsuite, $testcase) = @_;

    my $result = $testsuite->load_json($testcase);
    $testsuite->compare_load_json($testcase, $result);
}

