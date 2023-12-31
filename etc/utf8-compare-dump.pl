#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

use Encode;
use Devel::Peek;
use YAML::XS ();
use YAML::Syck ();
use YAML::Tiny ();
use YAML::PP::LibYAML ();
use YAML::PP::Ref ();

my $utf8 = "ä";
my $dec = decode_utf8 $utf8;
say "==================== YAML::XS utf8:";
my $data = YAML::XS::Dump($utf8);
Dump $data;
$data = "";
say "==================== YAML::XS perl:";
eval { $data = YAML::XS::Dump($dec)} or $data = $@;
Dump $data;

$YAML::Syck::ImplicitUnicode = 1;
say "==================== YAML::Syck utf8:";
$data = YAML::Syck::Dump($utf8);
Dump $data;
say "==================== YAML::Syck perl:";
$data = YAML::Syck::Dump($dec);
Dump $data;

say "==================== YAML::Tiny utf8:";
$data = "";
eval { $data = YAML::Tiny::Dump("- $utf8") } or $data = $@;
Dump $data;
say "==================== YAML::Tiny perl:";
$data = YAML::Tiny::Dump("- $dec");
Dump $data;

say "==================== YAML::PP::LibYAML utf8:";
$data = YAML::PP::LibYAML::Dump($utf8);
Dump $data;
say "==================== YAML::PP::LibYAML perl:";
$data = YAML::PP::LibYAML::Dump($dec);
Dump $data;

say "==================== YAML::PP::Ref utf8:";
$data = YAML::PP::Ref->new->dump_string($utf8);
Dump $data;
say "==================== YAML::PP::Ref perl:";
$data = YAML::PP::Ref->new->dump_string($dec);
Dump $data;

say "==================== YAML::PP utf8:";
$data = YAML::PP->new->dump_string($utf8);
Dump $data;
say "==================== YAML::PP perl:";
$data = YAML::PP->new->dump_string($dec);
Dump $data;
