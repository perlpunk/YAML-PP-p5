#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use YAML::PP;
use Data::Dumper;

my $ypp = YAML::PP->new( schema => ['Failsafe'] );
my ($filename) = @ARGV;
my $external_data = {
    env => \%ENV,
    argv => \@ARGV,
    config => { prefix => '/usr/local' },
};

my $schema = $ypp->schema;
$schema->add_resolver(
    tag => "!external",
    match => [ regex => qr{^(.*)$} => sub {
        my ($constructor, $event, $matches) = @_;
        my ($value) = @$matches;
        path($external_data, $value)
    }],
    implicit => 0,
);
$schema->add_resolver(
    tag => "!template",
    match => [ regex => qr{^(.*)$} => sub {
        my ($constructor, $event, $matches) = @_;
        my ($value) = @$matches;
        template($external_data, $value)
    }],
    implicit => 0,
);

my $data = $ypp->load_file($filename);
say $ypp->dump_string($data);

# utility functions

# turn /env/FOO into $data->{env}->{FOO}
sub path {
    my ($data, $path) = @_;
    my @paths = split qr{/}, $path;
    my $replaced = $data;
    for my $p (@paths) {
        next unless length $p;
        if (ref $replaced eq 'ARRAY') {
            if ($p !~ tr/0-9//c and $p < @$replaced) {
                $replaced = $replaced->[ $p ];
            }
            else {
                return;
            }
        }
        elsif (ref $replaced eq 'HASH') {
            $replaced = $replaced->{ $p };
        }
        last unless defined $replaced;
    }
    return $replaced;
}

# replace ${/some/path} in string with path(...)
sub template {
    my ($data, $string) = @_;
    $string =~ s<\$\{([\w/]+)\}>
                <path($data, $1)>eg;
    return $string;
}
