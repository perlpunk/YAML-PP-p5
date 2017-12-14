#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use YAML ();
local $YAML::Numify = 1;
use YAML::PP ();
use YAML::XS ();
use YAML::Syck ();
local $YAML::Syck::ImplicitTyping = 1;
use YAML::Tiny ();
use B ();
use Text::Table;

my @classes = qw/ YAML YAML::PP YAML::XS YAML::Syck YAML::Tiny /;

my $t = Text::Table->new(
    qw/
        Class
        Version
        3 IV NV PV
        3.140 IV NV PV
        3.00 IV NV PV
        0.3e3 IV NV PV
        Dump
    /,
);

my $yaml = <<'EOM';
- 3
- 3.140
- 3.00
- 0.3e3
EOM

my @rows;
for my $class (@classes) {
    my $version = $class->VERSION;
    my @row = ( $class, $version );
    my $decode = $class->can("Load");
    my $encode = $class->can("Dump");
    my $data = $decode->($yaml);

    for my $num (@$data) {
        my $flags = B::svref_2object(\$num)->FLAGS;
        my $int = $flags & B::SVp_IOK ? 1 : 0;
        my $float = $flags & B::SVp_NOK ? 1 : 0;
        my $str = $flags & B::SVp_POK ? 1 : 0;
        push @row, '', $int, $float, $str;
    }
    my $enc = $encode->($data);
    push @row, $enc;
    push @rows, \@row;
}

say "Input:\n$yaml";
$t->load(@rows);
say $t;
