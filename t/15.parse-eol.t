#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Parser;

my @yaml = (
    'foo: bar',
    'foo: bar #end',
    'foo',
    '- a',
    '-',

    "|\nfoo",
    ">\nfoo",
    "|",
    '"foo"',
    '"foo" ',

    'foo:',
    'foo: ',
    '&foo',
    '&foo ',
    '!foo',

    "foo\n ",
    '---',
    '--- ',
    '...',
    '... ',
);

my $ypp = YAML::PP::Parser->new(
    receiver => sub {}
);
if (my $num = $ENV{TEST_NUM}) {
    @yaml = $yaml[$num-1];
}
for my $yaml (@yaml) {
    my $display = $yaml;
    $display =~ s/\n/\\n/g;
    $display =~ s/\r/\\r/g;
    $display =~ s/\t/\\t/g;
    my $title = "Without final EOL: >>$display<<";
    eval {
        $ypp->parse_string($yaml);
    };
    if ($@) {
        diag "Error: $@";
        ok(0, $title);
    }
    else {
        ok(1, $title);
    }
}


done_testing;
