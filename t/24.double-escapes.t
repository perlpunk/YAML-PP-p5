#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Parser;
use YAML::PP::Loader;

my @yaml = (
    [ q{\\\\}, q{\\} ],
    [ q{\"}, q{"} ],
    [ q{\a}, qq{\a} ],
    [ q{\b}, qq{\b} ],
    [ q{\e}, qq{\e} ],
    [ q{\f}, qq{\f} ],
    [ q{\n}, qq{\n} ],
    [ q{\r}, qq{\r} ],
    [ q{\t}, qq{\t} ],
    [ q{\v}, qq{\x0b}],
    [ q{\0}, qq{\0} ],
    [ q{\ }, q{ } ],
    [ q{\_}, qq{\xa0} ],
    [ q{\N}, qq{\x85}],
    [ q{\L}, qq{\x{2028}}],
    [ q{\P}, qq{\x{2029}}],
    [ q{\x41}, q{A} ],
    [ q{\u0041}, q{A} ],
    [ q{\U00000041}, q{A} ],
);

for my $test (@yaml) {

    my ($yaml, $output) = @$test;

    $yaml = qq{"$yaml"};
    my $got = eval { YAML::PP::Loader->new->load_string($yaml) };
    if ($@) {
        diag "YAML:" . Data::Dumper->Dump([\$yaml], ['yaml']);
        diag "YAML: >>$yaml<< ";
        diag "Error: $@";
        ok(0, "Escape: $yaml");
    }
    else {
        local $Data::Dumper::Useqq = 1;
        my $ok = cmp_ok($got, 'eq', $output, "Escape: $yaml");
        unless ($ok) {
            warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$got], ['got']);
        }
    }
}
#is_deeply($data_from_file, $data, "load_file data ok");


done_testing;
