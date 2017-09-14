#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Parser;

my @chars = (
    "\x00",
    "\x01",
    "\x02",
    "\x03",
    "\x04",
    "\x05",
    "\x06",
    "\x07",
    "\x08",
    "\x0b",
    "\x0c",
    "\x0e",
    "\x0f",
    "\x10",
    "\x11",
    "\x12",
    "\x13",
    "\x14",
    "\x15",
    "\x16",
    "\x17",
    "\x18",
    "\x19",
    "\x1a",
    "\x1b",
    "\x1c",
    "\x1d",
    "\x1e",
    "\x1f",
);

my $ypp = YAML::PP::Parser->new(
    receiver => sub {}
);
if (my $num = $ENV{TEST_NUM}) {
    @chars = $chars[$num-1];
}
for my $char (@chars) {
    my $yaml = "control: $char";
    local $Data::Dumper::Useqq = 1;
    my $display = Data::Dumper->Dump([\$yaml], ['yaml']);
    chomp $display;
    my $title = "Invalid literal control char: >>$display<<";
    eval {
        $ypp->parse($yaml);
    };
    if ($@) {
        #diag "Error: $@";
        ok(1, $title);
    }
    else {
        ok(0, $title);
    }
}


done_testing;
