#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;

my $file = "$Bin/data/billion.yaml";

subtest "nested aliases limit reached" => sub {
    my $yp = YAML::PP->new(
        schema => ['Failsafe'],
        limit => {
            alias_depth => 100,
        },
    );

    eval {
        my $data = $yp->load_file($file);
    };
    my $error = $@;
    note $error;
    like($error, qr{Limit of nested aliases reached});
};

subtest "nested aliases ok" => sub {
    my $yp = YAML::PP->new(
        schema => ['Failsafe'],
        limit => {
            alias_depth => 1000_000_000,
        },
    );

    my $data = $yp->load_file($file);
    is($data->{data}->{i}->[0]->[0]->[0]->[0]->[0]->[0]->[0]->[0]->[0], 'lol');
};

done_testing;
