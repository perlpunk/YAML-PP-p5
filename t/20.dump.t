#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use YAML::PP::Test;
use Data::Dumper;
use YAML::PP;
use Encode;
use File::Basename qw/ dirname basename /;

my $json_pp = eval "use JSON::PP; 1";

unless ($json_pp) {
    plan skip_all => "Need JSON::PP for testing booleans";
    exit;
}

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
/;

my $testsuite = YAML::PP::Test->new(
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
    valid => 1,
    in_yaml => 1,
    out_yaml => 1,
);

my ($testcases) = $testsuite->read_tests(
    skip => \@skip,
);

$testsuite->run_testcases(
    code => \&test,
);

sub test {
    my ($testsuite, $testcase) = @_;

    my $result = $testsuite->dump_yaml($testcase);
    $testsuite->compare_dump_yaml($testcase, $result);
}

done_testing;

my $results = $testsuite->{stats};

my $diff_count = $results->{DIFF};
diag "OK: $results->{OK} DIFF: $diff_count ERROR: $results->{ERROR} TODO: $results->{TODO}";
diag "DIFF: (@{ $results->{DIFFS} })";

