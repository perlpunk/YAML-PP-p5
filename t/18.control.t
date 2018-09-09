#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Parser;
use YAML::PP;

my %chars = (
    "\x00" => '\0',
    "\x01" => '\x01',
    "\x02" => '\x02',
    "\x03" => '\x03',
    "\x04" => '\x04',
    "\x05" => '\x05',
    "\x06" => '\x06',
    "\x07" => '\a',
    "\x08" => '\b',
    "\x0b" => '\v',
    "\x0c" => '\f',
    "\x0e" => '\x0e',
    "\x0f" => '\x0f',
    "\x10" => '\x10',
    "\x11" => '\x11',
    "\x12" => '\x12',
    "\x13" => '\x13',
    "\x14" => '\x14',
    "\x15" => '\x15',
    "\x16" => '\x16',
    "\x17" => '\x17',
    "\x18" => '\x18',
    "\x19" => '\x19',
    "\x1a" => '\x1a',
    "\x1b" => '\e',
    "\x1c" => '\x1c',
    "\x1d" => '\x1d',
    "\x1e" => '\x1e',
    "\x1f" => '\x1f',
);

my $ypp = YAML::PP::Parser->new(
    receiver => sub {}
);
for my $char (sort keys %chars) {
    my $yaml = "control: $char";
    local $Data::Dumper::Useqq = 1;
    my $display = Data::Dumper->Dump([\$yaml], ['yaml']);
    chomp $display;
    my $title = "Invalid literal control char: >>$display<<";
    eval {
        $ypp->parse_string($yaml);
    };
    if ($@) {
        #diag "Error: $@";
        ok(1, "Parse: $title");
    }
    else {
        ok(0, "Parse: $title");
    }
    my $dump = YAML::PP->new->dump_string({ control => $char });
    my $escaped = $chars{ $char };
    my $expected = qq{---\ncontrol: "$escaped"\n};
    cmp_ok($dump, 'eq', $expected, "Dump: $title");
}


done_testing;
