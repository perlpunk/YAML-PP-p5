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

my $yts = "$Bin/../test-suite/yaml-test-suite-data";

# skip tests that parser can't parse
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

$testsuite->print_stats(
    count => [qw/ OK DIFF ERROR TODO SKIP /],
    ids => [qw/ ERROR DIFF /],
);

