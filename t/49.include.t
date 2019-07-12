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

subtest schema_include_from_hash => sub {

    my %database = (
        'included1.yaml' => "a: b",
        'recursive1.yaml' => "included2: !include recursive2.yaml",
        'recursive2.yaml' => "included2: !include recursive1.yaml",
    );

    my $include = YAML::PP::Schema::Include->new(
        find_include => sub {
            my ($self, $file) = @_;
            my $yaml = $database{ $file }
                or die "Did not find '$file' in database";
            return ($file, $yaml);
        },
        loader => sub {
            my ($yp, $file, $yaml) = @_;
            my ($data) = eval {
                $yp->load_string($yaml);
            };
            if ($@) {
                die "Error loading YAML from '$file': $@";
            }
            return $data;
        },
    );

    my $yp = YAML::PP->new( schema => ['JSON', $include] );
    $include->yp($yp);

    my $yaml = <<'EOM';
---
included: !include included1.yaml
EOM
    my ($data) = $yp->load_string($yaml);
    my $expected = {
        included => {
            a => 'b',
        },
    };
    is_deeply($data, $expected, "!include YAML from hash");

    $yaml = <<'EOM';
---
included: !include recursive1.yaml
EOM
    eval {
        my ($data) = $yp->load_string($yaml);
    };
    my $error = $@;
    like($error, qr{Circular}, "Circular include from hash");

    $yaml = <<'EOM';
---
included: !include does-not-exist.yaml
EOM
    eval {
        my ($data) = $yp->load_string($yaml);
    };
    $error = $@;
    like($error, qr{Did not find}, "non-existant include");
};

subtest schema_include_args => sub {

    my $include = YAML::PP::Schema::Include->new(
        paths => $include_path,
        find_include => sub {
            my ($self, $file, $search_paths) = @_;
            my $num = 1;
            if ($file =~ m/(.*)\#(\d+)/) {
                $file = $1;
                $num = $2;
            }
            my $args = { document => $num };
            my $fullpath = $self->default_find_include($file, $search_paths);
            return ($fullpath, $args);
        },
        loader => sub {
            my ($yp, $file, $args) = @_;
            my @docs = eval {
                $yp->load_file($file);
            };
            if ($@) {
                die "Error loading YAML from '$file': $@";
            }
            return $docs[ $args->{document} - 1 ];
        },
    );

    my $yp = YAML::PP->new( schema => ['JSON', $include] );
    $include->yp($yp);

    my $yaml = <<'EOM';
---
included: !include multi-doc.yaml#2
EOM

    my ($data) = $yp->load_string($yaml);
    my $expected = {
        included => {
            'doc two' => {
                c => 'd',
            },
        },
    };
    is_deeply($data, $expected, "!include specific YAML document number");
};

done_testing;
