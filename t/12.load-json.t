#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use Data::Dumper;
use YAML::PP::Test;
use YAML::PP::Loader;
use Encode;
use File::Basename qw/ dirname basename /;
my $json_xs = eval "use JSON::PP; 1";

my $yts = "$Bin/../yaml-test-suite";
my @dirs = YAML::PP::Test->get_tests(
    valid => 1,
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
    json => 1,
);


$|++;

my @skip = qw/
    4ABK
    87E4
    8CWC
    8UDB
    C2DT
    CN3R
    CT4Q
    DFF7
    FRK4
    L9U5
    LQZ7
    QF4Y

    FH7J
    LE5A
    S4JQ
    Q5MG

/;
my %skip;
@skip{ @skip }= ();
@dirs = grep { not exists $skip{ basename $_ } } @dirs;

unless (@dirs) {
    ok(1);
    done_testing;
    exit;
}

@dirs = sort @dirs;

if (my $dir = $ENV{YAML_TEST_DIR}) {
    @dirs = ($dir);
}

SKIP: {
    skip "JSON::PP not installed", scalar(@dirs) unless $json_xs;
    my $coder = JSON::PP->new->ascii->pretty->allow_nonref->canonical;

for my $item (@dirs) {
    my $dir = dirname $item;
    my $id = basename $item;

    open my $fh, "<", "$dir/$id/in.yaml" or die $!;
    my $yaml = do { local $/; <$fh> };
    close $fh;
    $yaml = decode_utf8 $yaml;
    open $fh, "<", "$dir/$id/===" or die $!;
    chomp(my $title = <$fh>);
    close $fh;

    open $fh, "<", "$dir/$id/in.json" or die $!;
    my $exp_json = do { local $/; <$fh> };
    close $fh;
    $exp_json = decode_utf8 $exp_json;

#    diag "------------------------------ $id";
    my $ypp = YAML::PP::Loader->new(boolean => 'JSON::PP');
    my $data = eval { $ypp->load_string($yaml) };
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$data], ['data']);
    if ($@) {
        warn __PACKAGE__.':'.__LINE__.": ERROR: $@\n";
        ok(0, "$id");
        next;
    }
    my $exp_data = $coder->decode($exp_json);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$data], ['data']);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$exp_data], ['exp_data']);
    $exp_json = $coder->encode($exp_data);

    my $json = $coder->encode($data);

    cmp_ok($json, 'eq', $exp_json, "$id");
}
}

done_testing;
