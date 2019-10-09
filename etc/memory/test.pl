#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use FindBin '$Bin';
use lib "$Bin/../../lib";

use YAML::PP;
use JSON::PP;

my ($file, $limit) = @ARGV;

$limit ||= 1024;

my $yp = YAML::PP->new(
    limit => {
        alias_depth => $limit,
    },
);
my $j = JSON::PP->new;

my $start = size();
say "Memory at start: $start";

my $data = $yp->load_file($file);
my $mem_load = size();
my $growth = $mem_load - $start;
say "After load: $mem_load (+$growth)";

my $json = $j->encode($data);
my $mem_json = size();
$growth = $mem_json - $mem_load;
say "After json encode: $mem_json (+$growth)";
say sprintf "length JSON: %s bytes", length $json;

sub size {
    my $s = qx{ps --no-headers -o vsize:3 --pid $$};
    chomp $s;
    return $s;
}
