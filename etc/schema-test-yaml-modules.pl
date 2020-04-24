#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Data::Dumper;
use FindBin '$Bin';
use lib "$Bin/../lib";
use YAML::PP;
use JSON::PP;
$YAML::XS::Boolean = 'JSON::PP';
use YAML::XS ();
$YAML::Syck::ImplicitTyping = 1;
use YAML::Syck ();
$YAML::Numify = 1;
use YAML ();
use B;
my $int_flags = B::SVp_IOK;
my $float_flags = B::SVp_NOK;

#my $yp = YAML::PP->new( schema => 
my $file = "$Bin/../ext/yaml-test-schema/yaml-schema.yaml";
my $outputfile = "$Bin/../examples/yaml-schema-modules.yaml";

my $data = YAML::PP::LoadFile($file);

my %examples;
my %output;
my %special = (
    (0+'nan').'' => 'nan',
    (0+'inf').'' => 'inf',
    (0-'inf').'' => 'inf'
);

for my $input (sort keys %$data) {
    for my $mod (qw/ YAML YAML::XS YAML::Syck /) {
        my $out = $output{ $input }->{ $mod } ||= {};
        my $output;
        my $load = $mod->can("Load");
        my $dump = $mod->can("Dump");
        my $data = eval { $load->("--- $input") };
        if ($@) {
            $out->{error} = 1;
            $out->{type} = 'error';
        }
        else {
            $out->{type} = get_type($data);
            $output = $dump->($data);
            chomp $output;
            $output =~ s/^--- //;
            $out->{dump} = $output;
        }
    }
}

YAML::PP::DumpFile($outputfile, \%output);

sub get_type {
    my ($value) = @_;
    return 'null' unless defined $value;
    if (ref $value) {
        if (ref $value eq 'JSON::PP::Boolean') {
            return 'bool';
        }
        return 'unknown';
    }
    my $flags = B::svref_2object(\$value)->FLAGS;
    if ($flags & $float_flags) {
        if (exists $special{ $value }) {
            return $special{ $value };
        }
        return 'float';
    }
    if ($flags & $int_flags) {
        return 'int';
    }
    return 'str';
}
