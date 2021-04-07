#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use YAML::PP;
use Test::Deep;

my $allow = YAML::PP->new(
    duplicate_keys => 1,
);
my $forbid = YAML::PP->new(
    duplicate_keys => 0,
);
my $default = YAML::PP->new;


my $yaml = <<'EOM';
a: 1
b: 2
a: 3
EOM

my $data = $allow->load_string($yaml);
my $expected = {
    a => 3,
    b => 2,
};
is_deeply($data, $expected, "Allowed duplicate keys");


$data = eval { $forbid->load_string($yaml) };
my $err = $@;
like $err, qr{Duplicate key 'a'}, "Forbidden duplicate keys";

$data = eval { $default->load_string($yaml) };
$err = $@;
like $err, qr{Duplicate key 'a'}, "Forbidden duplicate keys by default";


done_testing;
