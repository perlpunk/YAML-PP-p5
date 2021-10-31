#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use YAML::PP::Test;
use Data::Dumper;
use YAML::PP::Parser;

$|++;

my $yts = "$Bin/../test-suite/yaml-test-suite-data";

my @skip = qw/
    CXX2

    9KBC
    S98Z
    T833
    5LLU
/;

# in case of error events might not be exactly matching
my %skip_events = (
    Q4CL => 1,
    JY7Z => 1,
    '3HFZ' => 1,
    X4QW => 1,
    SU5Z => 1,
    W9L4 => 1,
    ZL4Z => 1,
    '9KBC' => 1,
    SY6V => 1,
    C2SP => 1,
    'NTY5' => 1,
    '4EJS' => 1,
    '2CMS' => 1,
    'HU3P' => 1,
    'EW3V' => 1,
    'G9HC' => 1,
    '4H7K' => 1,
    BS4K => 1,
    EB22 => 1,
);


my $testsuite = YAML::PP::Test->new(
    test_suite_dir => "$yts",
    dir => "$Bin/invalid",
    valid => 0,
    events => 1,
    in_yaml => 1,
);
my ($testcases) = $testsuite->read_tests(
    skip => \@skip,
);
my %errors;
$testsuite->run_testcases(
    code => \&test,
);

$testsuite->print_stats(
    count => [qw/ OK DIFF ERROR TODO SKIP /],
    ids => [qw/ OK DIFF /],
);

for my $type (sort keys %errors) {
    diag "ERRORS($type): (@{ $errors{ $type } })" if $ENV{TEST_VERBOSE};
}

done_testing;
exit;


sub test {
    my ($testsuite, $testcase) = @_;
    my $id = $testcase->{id};

    my $result = $testsuite->parse_events($testcase);
    my $err = $result->{err};
    if ($err) {
        diag "ERROR: $err" if $ENV{YAML_PP_TRACE};
        my $error_type = 'unknown';
        if ($@ =~ m/( Expected .*?)/) {
            $error_type = "$1";
        }
        elsif ($@ =~ m/( Not Implemented: .*?)/) {
            $error_type = "$1";
        }
        push @{ $errors{ $error_type } }, $id;
    }
    if ($skip_events{ $id }) {
        delete $result->{events};
    }
    $testsuite->compare_invalid_parse_events($testcase, $result);
    return $result;
}

