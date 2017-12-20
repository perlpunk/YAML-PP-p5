#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Parser;
use YAML::PP::Loader;
use YAML::PP::Dumper;

my $file = "$Bin/data/simple.yaml";
my $file_out = "$Bin/data/simple-out.yaml";
my $yaml = do { open my $fh, '<', $file or die $!; local $/; <$fh> };

my $data = { a => 1 };

my $data_from_string = YAML::PP::Loader->new->load_string($yaml);
my $data_from_file = YAML::PP::Loader->new->load_file($file);
is_deeply($data_from_string, $data, "load_string data ok");
is_deeply($data_from_file, $data, "load_file data ok");

YAML::PP::Dumper->new->dump_file($file_out, $data);
my $yaml2 = do { open my $fh, '<', $file_out or die $!; local $/; <$fh> };
cmp_ok($yaml2, 'eq', $yaml, "dump_file data correct");

done_testing;

END {
    unlink $file_out;
}
