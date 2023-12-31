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
my $data = YAML::XS::Load($utf8);
Dump $data;
$data = "";
say "==================== YAML::XS perl:";
eval { $data = YAML::XS::Load($dec)} or $data = $@;
Dump $data;

$YAML::Syck::ImplicitUnicode = 1;
say "==================== YAML::Syck utf8:";
$data = YAML::Syck::Load($utf8);
Dump $data;
say "==================== YAML::Syck perl:";
$data = YAML::Syck::Load($dec);
Dump $data;

say "==================== YAML::Tiny utf8:";
$data = "";
eval { $data = YAML::Tiny::Load("- $utf8") } or $data = $@;
Dump $data->[0];
say "==================== YAML::Tiny perl:";
$data = YAML::Tiny::Load("- $dec");
Dump $data->[0];

say "==================== YAML::PP::LibYAML utf8:";
$data = YAML::PP::LibYAML::Load($utf8);
Dump $data;
say "==================== YAML::PP::LibYAML perl:";
$data = YAML::PP::LibYAML::Load($dec);
Dump $data;

say "==================== YAML::PP::Ref utf8:";
$data = YAML::PP::Ref->new->load_string($utf8);
Dump $data;
say "==================== YAML::PP::Ref perl:";
$data = YAML::PP::Ref->new->load_string($dec);
Dump $data;

say "==================== YAML::PP utf8:";
$data = YAML::PP->new->load_string($utf8);
Dump $data;
say "==================== YAML::PP perl:";
$data = YAML::PP->new->load_string($dec);
Dump $data;
