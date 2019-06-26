#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;
use YAML::PP::Schema::Include;
use Test::Deep;
use File::Spec;
use Scalar::Util qw/ refaddr /;

my $include_path = "$Bin/data/include";

my $valid_yaml = <<'EOM';
---
- !include include1.yaml
- !include include2.yaml
- item3
EOM

my $invalid_yaml = <<'EOM';
---
- !include ../../../../../../../../../../../etc/passwd
EOM
my $invalid_yaml2 = <<'EOM';
---
- !include /etc/passwd
EOM

my $expected = [
    'include1',
    [
        'include2',
        'include3',
    ],
    'item3',
];

my %objects;
sub YAML::PP::DESTROY {
    my ($self) = @_;
    my $addr = refaddr($self);
    $objects{ $addr }--;
}

my $addr;
subtest schema_include => sub {

    my $include = YAML::PP::Schema::Include->new( paths => $include_path );
    my $yp = YAML::PP->new( schema => ['JSON', $include] );
    $include->yp($yp);
    $addr = refaddr($yp);
    $objects{ $addr }++;

    my ($data) = $yp->load_string($valid_yaml);
    is_deeply($data, $expected, "!include");
};

cmp_ok($objects{ $addr }, 'eq', 0, "YAML::PP object was destroyed correctly");

subtest invalid_schema_include => sub {
    my $include = YAML::PP::Schema::Include->new(
        paths => $include_path,
    );
    my $yp = YAML::PP->new( schema => ['JSON', $include] );
    $include->yp($yp);
    my ($data) = eval {
        $yp->load_string($invalid_yaml)
    };
    my $error = $@;
    cmp_ok($error, '=~', "not found", "Filter out ..");

    ($data) = eval {
        $yp->load_string($invalid_yaml2)
    };
    $error = $@;
    cmp_ok($error, '=~', "Absolute filenames not allowed", "No absolute filenames");
};


subtest schema_include_filename => sub {

    my $include = YAML::PP::Schema::Include->new;
    my $yp = YAML::PP->new( schema => ['JSON', $include] );
    $include->yp($yp);

    my ($data) = $yp->load_file("$include_path/include.yaml");
    is_deeply($data, $expected, "!include");
};

subtest schema_include_circular => sub {

    my $include = YAML::PP::Schema::Include->new;
    my $yp = YAML::PP->new( schema => ['JSON', $include] );
    $include->yp($yp);

    my ($data) = eval {
        $yp->load_file("$include_path/circular1.yaml");
    };
    my $error = $@;
    cmp_ok($@, '=~', "Circular include", "Circular include detected");
};


done_testing;
