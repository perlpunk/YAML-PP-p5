#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;

my $file = "$Bin/data/simple.yaml";
my $file_out = "$Bin/data/simple-out.yaml";
my $invalid_file = "/non/existant/path/for/yaml/pp";
my $yaml = do { open my $fh, '<', $file or die $!; local $/; <$fh> };

my $data = { a => 1 };
my $all_data = [ { a => 1 }, { b => 2 } ];

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

YAML::PP->new->dump_file($file_out, @$all_data);
my $yaml2 = do { open my $fh, '<', $file_out or die $!; local $/; <$fh> };
cmp_ok($yaml2, 'eq', $yaml, "dump_file data correct");

YAML::PP::DumpFile($file_out, @$all_data);
$yaml2 = do { open my $fh, '<', $file_out or die $!; local $/; <$fh> };
cmp_ok($yaml2, 'eq', $yaml, "DumpFile data correct");

open my $fh_out, '>', $file_out or die $!;
YAML::PP::DumpFile($fh_out, @$all_data);
close $fh_out;
$yaml2 = do { open my $fh, '<', $file_out or die $!; local $/; <$fh> };
cmp_ok($yaml2, 'eq', $yaml, "DumpFile(filehandle) data correct");

eval {
    YAML::PP::DumpFile($invalid_file, $data);
};
my $error = $@;
cmp_ok($error, '=~', qr{Could not open});


done_testing;

END {
    unlink $file_out;
}
