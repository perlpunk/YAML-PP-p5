#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use YAML::PP;
use Data::Dumper;

my $in = <<'EOM';
---
a:
 b:
  c: d
list:
- 1
- 2
EOM
my $out_expected = <<'EOM';
---
a:
  b:
    c: d
list:
- 1
- 2
EOM

my $writer = MyWriter->new(\my $output);
my $yp = YAML::PP->new(
    writer => $writer,
);

my $data = $yp->load_string($in);
$yp->dump($data);
cmp_ok($output, 'eq', $out_expected, "Dumping with indent");

done_testing;


package MyWriter;

sub new {
    my ($class, $ref) = @_;
    die "No scalar reference given" unless $ref;
    $$ref = '' unless defined $$ref;
    bless { output => $ref }, $class;
}

sub write {
    my ($self, $line) = @_;
    ${ $self->{output} } .= $line;
}

sub init {
    ${ $_[0]->{output} } = '';
}

sub finish {
    my ($self) = @_;
}

sub output {
    my ($self) = @_;
    return "dummy";
    return ${ $self->{output} };
}
