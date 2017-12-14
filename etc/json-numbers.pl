#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use JSON ();
use JSON::PP ();
use JSON::XS ();
use Cpanel::JSON::XS ();
require Mojolicious;
use Mojo::JSON ();
use B ();
use Text::Table;

my @classes = qw/ JSON JSON::PP JSON::XS Cpanel::JSON::XS Mojo::JSON /;

my $t = Text::Table->new(
    qw/
        Class
        Version
        3 IV NV PV
        3.140 IV NV PV
        3.00 IV NV PV
        0.3e3 IV NV PV
        encode
    /,
);

my $json = <<'EOM';
[ 3, 3.140, 3.00, 0.3e3 ]
EOM

my @rows;
for my $class (@classes) {
    my $version = $class eq 'Mojo::JSON' ? Mojolicious->VERSION : $class->VERSION;
    my @row = ( $class, $version );
    my $decode = $class->can("decode_json");
    my $encode = $class->can("encode_json");
    my $data = $decode->($json);

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

say "Input: $json";
$t->load(@rows);
say $t;
