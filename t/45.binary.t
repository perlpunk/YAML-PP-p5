#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

use YAML::PP;

my $yp = YAML::PP->new( schema => [qw/ JSON Binary /] );

my $yaml = <<'EOM';
canonical: !!binary "\
 R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5\
 OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+\
 +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC\
 AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs="
EOM

my $data = $yp->load_string($yaml);

my $gif = "GIF89a\f\0\f\0\204\0\0\377\377\367\365\365\356\351\351\345fff"
    . "\0\0\0\347\347\347^^^\363\363\355\216\216\216\340\340\340\237\237\237"
    . "\223\223\223\247\247\247\236\236\236iiiccc\243\243\243\204\204\204\377"
    . "\376\371\377\376\371\377\376\371\377\376\371\377\376\371\377\376\371"
    . "\377\376\371\377\376\371\377\376\371\377\376\371\377\376\371\377\376"
    . "\371\377\376\371\377\376\371!\376\16Made with GIMP\0,\0\0\0\0\f\0\f"
    . "\0\0\5,  \216\2010\236\343\@\24\350i\20\304\321\212\b\34\317\200"
    . "M\$z\357\3770\205p\270\2601f\r\e\316\1\303\1\36\20' \202\n\1\0;";

cmp_ok($data->{canonical}, 'eq', $gif, "Loaded binary equals gif");

done_testing;
