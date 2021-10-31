#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use YAML::PP::Test;
use Data::Dumper;
use YAML::PP::Parser;
use Encode;

$ENV{YAML_PP_RESERVED_DIRECTIVE} = 'ignore';

$|++;

my $yts = "$Bin/../test-suite/yaml-test-suite-data";

my @skip = qw/
    4FJ6 8CWC 9MMW
    LX3P
    Q9WF
    6BFJ


    CT4Q
/;

my $testsuite = YAML::PP::Test->new(
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
    valid => 1,
    events => 1,
    in_yaml => 1,
    linecount => 1,
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
    ids => [qw/ DIFF ERROR /],
);

for my $type (sort keys %errors) {
    diag "ERRORS($type): (@{ $errors{ $type } })";
}

sub test {
    my ($testsuite, $testcase) = @_;
    my $id = $testcase->{id};

    my $result = $testsuite->parse_events($testcase);
    my $err = $result->{err};
    if ($err) {
        diag "ERROR($id): $err";
        my $error_type = 'unknown';
        if ($err =~ m/^(Expected) *:/m) {
            $error_type = "$1";
        }
        elsif ($err =~ m/(Not Implemented: .*?) at/) {
            $error_type = "$1";
        }
        elsif ($err =~ m/(Unexpected .*?) at/) {
            $error_type = "$1";
        }
        push @{ $errors{ $error_type } }, $id;
    }

    $testsuite->compare_parse_events($testcase, $result);
    return $result;
}

done_testing;

