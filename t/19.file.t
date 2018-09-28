#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;

my $file = "$Bin/data/simple.yaml";
my $file_out = "$Bin/data/simple-out.yaml";
my $yaml = do { open my $fh, '<', $file or die $!; local $/; <$fh> };

my $data = { a => 1 };

my $data_from_string = YAML::PP->new->load_string($yaml);
my $data_from_file = YAML::PP->new->load_file($file);
open my $fh, '<', $file or die $!;
my $data_from_filehandle = YAML::PP->new->load_file($fh);
close $fh;

is_deeply($data_from_string, $data, "load_string data ok");
is_deeply($data_from_file, $data, "load_file data ok");
is_deeply($data_from_filehandle, $data, "load_file(filehandle) data ok");
$data_from_file = YAML::PP::LoadFile($file);
is_deeply($data_from_file, $data, "LoadFile data ok");

YAML::PP->new->dump_file($file_out, $data);
my $yaml2 = do { open my $fh, '<', $file_out or die $!; local $/; <$fh> };
cmp_ok($yaml2, 'eq', $yaml, "dump_file data correct");

YAML::PP::DumpFile($file_out, $data);
$yaml2 = do { open my $fh, '<', $file_out or die $!; local $/; <$fh> };
cmp_ok($yaml2, 'eq', $yaml, "DumpFile data correct");

done_testing;

END {
    unlink $file_out;
}
