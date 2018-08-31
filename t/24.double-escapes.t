#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP;

my @yaml = (
    [ q{\\\\}, q{\\},  q{\\}   ],
    [ q{\"}, q{"},     q{'"'}  ],
    [ q{\a}, qq{\a},   q{"\a"} ],
    [ q{\b}, qq{\b},   q{"\b"} ],
    [ q{\e}, qq{\e},   q{"\e"} ],
    [ q{\f}, qq{\f},   q{"\f"} ],
    [ q{\n}, qq{\n},   q{"\n"} ],
    [ q{\r}, qq{\r},   q{"\r"} ],
    [ q{\t}, qq{\t},   q{"\t"} ],
    [ q{\v}, qq{\x0b}, q{"\v"} ],
    [ q{\0}, qq{\0},   q{"\0"} ],
    [ q{\ }, q{ },     q{' '}  ],
    [ q{\_}, qq{\xa0}, q{"\_"} ],
    [ q{\N}, qq{\x85}, q{"\N"} ],
    [ q{\L}, qq{\x{2028}}, q{"\L"}],
    [ q{\P}, qq{\x{2029}}, q{"\P"}],
    [ q{\x41}, q{A}, q{A} ],
    [ q{\u0041}, q{A}, q{A} ],
    [ q{\U00000041}, q{A}, q{A} ],
);

for my $test (@yaml) {

    my ($yaml, $output, $dump) = @$test;

    unless (defined $dump) {
        $dump = $yaml;
    }
    $dump = "--- $dump\n";
    $yaml = qq{"$yaml"};
    my $got = eval { YAML::PP->new->load_string($yaml) };
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
            next;
        }
    }
    my $got_dump = YAML::PP->new->dump_string($got);
    my $ok = cmp_ok($got_dump, 'eq', $dump, "Dump: $yaml");
}


done_testing;
