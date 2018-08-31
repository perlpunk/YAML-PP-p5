#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Loader;

eval {
    my $yppl = YAML::PP::Loader->new( boolean => 'bla' );
};
my $error = $@;
cmp_ok($error, '=~', 'Unexpected arguments', "Unexpected arguments");

done_testing;
