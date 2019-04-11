#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Data::Dumper;
use YAML::PP;

my $yaml = <<'EOM';
- &NODEA
  name: A
  link: &NODEB
    name: B
    link: *NODEA
EOM
my $yaml2 = <<'EOM';
- &NODEA
  name: A
  foo: &NODEA # overwrite anchor
    bar: boo
  link: &NODEB
    name: B
    link: *NODEA
EOM

my $fatal     = YAML::PP->new( cyclic_refs => 'fatal' );
my $warn      = YAML::PP->new( cyclic_refs => 'warn' );
my $ignore    = YAML::PP->new( cyclic_refs => 'ignore' );
my $allow     = YAML::PP->new( cyclic_refs => 'allow' );
my $allow2    = YAML::PP->new( );

my $data = eval {
    $fatal->load_string($yaml);
};
my $error = $@;
cmp_ok($error, '=~', qr{found cyclic ref}i, "cyclic_refs=fatal");

warning_like {
    $warn->load_string($yaml);
} qr{found cyclic ref}i, "cyclic_refs=warn";
is($data->[0]->{link}->{link}, undef, "cyclic_refs=warn");

$data = $ignore->load_string($yaml);
is($data->[0]->{link}->{link}, undef, "cyclic_refs=ignore");

$data = $allow->load_string($yaml);
cmp_ok($data->[0]->{link}->{link}->{name}, 'eq', 'A', "cyclic_refs=allow");

$data = $allow2->load_string($yaml);
cmp_ok($data->[0]->{link}->{link}->{name}, 'eq', 'A', "cyclic_refs unset (default=allow)");

$data = eval {
    my $nonsense  = YAML::PP->new( cyclic_refs => 'nonsense');
    $nonsense->load_string($yaml);
};
$error = $@;
cmp_ok($error, '=~', qr{invalid}i, "cyclic_refs=nonsense (invalid parameter)");

$data = $fatal->load_string($yaml2);
cmp_ok($data->[0]->{link}->{link}->{bar}, 'eq', 'boo', "cyclic_refs=fatal, no cyclic ref found");

done_testing;
