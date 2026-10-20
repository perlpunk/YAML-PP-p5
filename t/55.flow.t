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

my $yts = "$Bin/../test-suite/yaml-test-suite-data";

# skip tests that parser can't parse
my @skip = qw/
    4FJ6 87E4 8UDB
    CN3R
    L9U5 LQZ7 LX3P
    QF4Y
    Q9WF
/;

push @skip, qw/
    v014
    v033
/;

my $testsuite = YAML::PP::Test->new(
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
    valid => 1,
    events => 1,
    in_yaml => 1,
    emit_yaml => 1,
    tag => 'flow',
);

my ($testcases) = $testsuite->read_tests(
    skip => \@skip,
);

$testsuite->run_testcases(
    code => \&test,
);

$testsuite->print_stats(
    count => [qw/ SAME_EVENTS SAME_YAML DIFF_EVENTS DIFF_YAML ERROR TODO SKIP/],
    ids => [qw/ DIFF_YAML DIFF_EVENTS/],
);

sub test {
    my ($testsuite, $testcase) = @_;
    my $id = $testcase->{id};

    my $result = $testsuite->emit_yaml($testcase, { flow => 'keep' });
    $testsuite->compare_emit_yaml($testcase, $result);
}

done_testing;
exit;

