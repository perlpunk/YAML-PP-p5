#!/usr/bin/env perl
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";

use YAML::PP;

my $tests_perl = require "$Bin/schema-perl.pm";
my $tests_ixhash = require "$Bin/schema-ixhash.pm";

my %tests = (
    %$tests_perl,
    %$tests_ixhash,
);

my %all_data;
for my $name (sort keys %tests) {
    my $test = $tests{ $name };
    my $data = eval $test->[0];
    $all_data{ $name } = $data;
}

my $yp = YAML::PP->new( schema => [qw/ JSON Perl Tie::IxHash /] );
my $yaml = $yp->dump_string(\%all_data);
print $yaml;
