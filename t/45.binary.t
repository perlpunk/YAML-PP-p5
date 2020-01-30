#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

use YAML::PP;
use Encode;
use Data::Dumper;

my $yp_binary = YAML::PP->new( schema => [qw/ JSON Binary /] );
my $yp = YAML::PP->new( schema => [qw/ JSON /] );

my $gif = "GIF89a\f\0\f\0\204\0\0\377\377\367\365\365\356\351\351\345fff"
    . "\0\0\0\347\347\347^^^\363\363\355\216\216\216\340\340\340\237\237\237"
    . "\223\223\223\247\247\247\236\236\236iiiccc\243\243\243\204\204\204\377"
    . "\376\371\377\376\371\377\376\371\377\376\371\377\376\371\377\376\371"
    . "\377\376\371\377\376\371\377\376\371\377\376\371\377\376\371\377\376"
    . "\371\377\376\371\377\376\371!\376\16Made with GIMP\0,\0\0\0\0\f\0\f"
    . "\0\0\5,  \216\2010\236\343\@\24\350i\20\304\321\212\b\34\317\200"
    . "M\$z\357\3770\205p\270\2601f\r\e\316\1\303\1\36\20' \202\n\1\0;";

subtest load_binary => sub {
    my $yaml = <<'EOM';
canonical: !!binary "\
 R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5\
 OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+\
 +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC\
 AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs="
EOM

    my $data = $yp_binary->load_string($yaml);

    cmp_ok($data->{canonical}, 'eq', $gif, "Loaded binary equals gif");

    my $base64 = "R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5"
        . "OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+"
        . "+f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC"
        . "AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=";
    my $load = $yp->load_string($yaml);
    cmp_ok($load->{canonical}, 'eq', $base64, "Load back literally");

};

my $latin1_a_umlaut = encode(latin1 => (decode_utf8 "ä"));
my @tests = (
    [utf8 => "a"],
    [binary => $latin1_a_umlaut],
    [binary =>  "\304\244",],
    [utf8 =>  decode_utf8("\304\244"),],
    [binary => "a umlaut ä",],
    [utf8 => decode_utf8("a umlaut ä"),],
    [binary => "euro €",],
    [utf8 => decode_utf8("euro €"),],
    [binary => "\303\274 \374",],
    [binary => "\xC0\x80"],
    [binary => "\xC0\xAF"],
    [binary => "\xE0\x80\x80"],
    [binary => "\xF0\x80\x80\x80"],
    [binary => "\xE0\x83\xBF"],
    [binary => "\xF0\x80\x83\xBF"],
    [binary => "\xF0\x80\xA3\x80"],
    [binary => [$gif, decode_utf8("ä")],],
    [binary => [$gif, 'foo'],],
);

subtest roundtrip => sub {
    for my $item (@tests) {
        select undef, undef, undef, 0.1;
        my ($type, $data) = @$item;
        local $Data::Dumper::Useqq = 1;
        my $label = Data::Dumper->Dump([$data], ['data']);
        chomp $label;
        note("\n\n\n=============== $type: $label");
        my $dump = $yp->dump_string($data);
        #note("========= YAML:\n$dump");
        my $reload = $yp->load_string($dump);
        if (ref $reload eq 'ARRAY') {
            cmp_ok($reload->[0], 'eq', $data->[0], "Reload binary->[0] ok ($label)");
            cmp_ok($reload->[1], 'eq', $data->[1], "Reload binary->[1] ok ($label)");
        }
        else {
            cmp_ok($reload, 'eq', $data, "Reload binary ok ($label)");
        }
    }
};

subtest roundtrip_binary => sub {
    for my $item (@tests) {
        my ($type, $data) = @$item;
        local $Data::Dumper::Useqq = 1;
        my $label = Data::Dumper->Dump([$data], ['data']);
        note("=============== $type: $label");
        my $dump = $yp_binary->dump_string($data);
        if ($type eq 'binary') {
            like($dump, qr{!!binary}, "Output YAML contains !!binary");
        }
        else {
            unlike($dump, qr{!!binary}, "Output YAML does not contain !!binary");
        }
        my $reload = $yp_binary->load_string($dump);
        if (ref $reload eq 'ARRAY') {
            cmp_ok($reload->[0], 'eq', $data->[0], "Reload binary->[0] ok ($label)");
            cmp_ok($reload->[1], 'eq', $data->[1], "Reload binary->[1] ok ($label)");
        }
        else {
            cmp_ok($reload, 'eq', $data, "Reload binary ok ($label)");
        }
    }
};

done_testing;
