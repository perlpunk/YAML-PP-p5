#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Loader;

my $yppl = YAML::PP::Loader->new;
my $yaml = <<'EOM';
complexmap:
    x: y
    ? a: b
    : c: d
complexseq:
    X: Y
    ?
        - A
        - B
    :
        - C
        - D
EOM
my $nested_yaml = <<'EOM';
complex:
    ?
        ?
            a: b
            c: d
        : innervalue
    : outervalue
EOM
my $exp_complexmap = $yppl->stringify_complex({ a => 'b' });
my $exp_complexseq = $yppl->stringify_complex([qw/ A B /]);
my $inner = $yppl->stringify_complex({ a => 'b', c => 'd' });
my $nested = $yppl->stringify_complex({ $inner => "innervalue" });

{
    my $data = $yppl->Load($yaml);
    my $val1 = delete $data->{complexmap}->{x};
    my $val2 = delete $data->{complexseq}->{X};
    cmp_ok($val1, 'eq', 'y', "Normal key x");
    cmp_ok($val2, 'eq', 'Y', "Normal key X");
    my $complexmap = (keys %{ $data->{complexmap} })[0];
    my $complexseq = (keys %{ $data->{complexseq} })[0];
    cmp_ok($complexmap, 'eq', $exp_complexmap, "Complex map");
    cmp_ok($complexseq, 'eq', $exp_complexseq, "Complex seq");
}

{
    my $nested_data = $yppl->Load($nested_yaml);
    my $data1 = $nested_data->{complex};
    my $key = (keys %$data1)[0];
    cmp_ok($key, 'eq', $nested, "Nested complex maps");
}

done_testing;
