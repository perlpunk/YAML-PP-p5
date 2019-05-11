#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use YAML::PP;
use Encode;
use Data::Dumper;

my $yp = YAML::PP->new;

subtest mac => sub {
    my $yaml = qq{x: "a\r b"\ry: b\r};
    my $data = $yp->load_string($yaml);
    my $expected = {
        x => 'a b',
        y => 'b',
    };
    is_deeply($data, $expected, 'Mac \r line endings');
};

subtest win => sub {
    my $yaml = qq{x: "a\r\n b"\ry: b\r};
    my $data = $yp->load_string($yaml);
    my $expected = {
        x => 'a b',
        y => 'b',
    };
    is_deeply($data, $expected, 'Win \r\n line endings');
};

done_testing;
