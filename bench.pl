#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Benchmark qw/ timethese cmpthese /;
use Encode;
use YAML ();
use YAML::XS ();
use YAML::PP ();
use YAML::PP::LibYAML::Parser;
use YAML::Tiny ();
use YAML::Syck ();
say "$_: " . $_->VERSION
    for qw/ YAML YAML::PP YAML::XS YAML::PP::LibYAML YAML::Tiny YAML::Syck /;

my ($file, $count) = @ARGV;
open my $fh, "<", $file or die $!;
my $enc_yaml = do { local $/; <$fh> };
close $fh;
my $yaml = decode_utf8 $enc_yaml;


my $parser = YAML::PP::LibYAML::Parser->new;
my $yplibyaml = YAML::PP->new(
    parser => $parser,
    schema => ['JSON'],
);
my $yp = YAML::PP->new( schema => ['JSON'] );
my $results = timethese($count, {
    yaml => sub {
        my $data = YAML::Load($yaml);
    },
    yamltiny => sub {
        my $data = YAML::Tiny::Load($yaml);
    },
    yamlxs => sub {
        my $data = YAML::XS::Load($enc_yaml);
    },
    yamlsyck => sub {
        my $data = YAML::Syck::Load($enc_yaml);
    },
    yamlpp => sub {
        my $data = $yp->load_string($yaml);
    },
    pplibyaml => sub {
        my $data = $yplibyaml->load_string($yaml);
#        say scalar @$data;
    },
});
cmpthese($results);
