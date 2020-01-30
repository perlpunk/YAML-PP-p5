#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;
use YAML::PP::Perl;

my $file = "$Bin/data/simple.yaml";
my $copy = "$Bin/data/simple.yaml.copy";
my $yaml = do { open my $fh, '<', $file or die $!; local $/; <$fh> };

my $data = { a => 1 };
my $all_data = [ { a => 1 }, { b => 2 } ];

subtest default => sub {
    my $data_from_string = YAML::PP::Load($yaml);
    my $data_from_file = YAML::PP::LoadFile($file);
    is_deeply($data_from_string, $data, "scalar Load data ok");
    is_deeply($data_from_file, $data, "scalar LoadFile data ok");

    my @all_data_from_string = YAML::PP::Load($yaml);
    my @all_data_from_file = YAML::PP::LoadFile($file);
    is_deeply(\@all_data_from_string, $all_data, "Load data ok");
    is_deeply(\@all_data_from_file, $all_data, "LoadFile data ok");

    my $dump = YAML::PP::Dump(@$all_data);
    cmp_ok($dump, 'eq', $yaml, 'Dump() ok');

    YAML::PP::DumpFile($copy, @$all_data);
    $yaml = do { open my $fh, '<', $copy or die $!; local $/; <$fh> };
    cmp_ok($dump, 'eq', $yaml, 'DumpFile() ok');
};

subtest perl => sub {
    my $data_from_string = YAML::PP::Perl::Load($yaml);
    my $data_from_file = YAML::PP::Perl::LoadFile($file);
    is_deeply($data_from_string, $data, "Load data ok");
    is_deeply($data_from_file, $data, "LoadFile data ok");

    my @all_data_from_string = YAML::PP::Perl::Load($yaml);
    my @all_data_from_file = YAML::PP::Perl::LoadFile($file);
    is_deeply(\@all_data_from_string, $all_data, "Load data ok");
    is_deeply(\@all_data_from_file, $all_data, "LoadFile data ok");

    my $dump = YAML::PP::Perl::Dump(@$all_data);
    cmp_ok($dump, 'eq', $yaml, 'Dump() ok');

    YAML::PP::Perl::DumpFile($copy, @$all_data);
    $yaml = do { open my $fh, '<', $copy or die $!; local $/; <$fh> };
    cmp_ok($dump, 'eq', $yaml, 'DumpFile() ok');
};

done_testing;

END {
    unlink $copy;
}
