#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Loader;
use Encode;
use File::Basename qw/ dirname basename /;
my $json_xs = eval "use JSON::XS; 1";

$|++;

my @skip = qw/
    4ABK
    54T7
    5C5M
    5KJE
    6HB6
    87E4
    8UDB
    C2DT
    CT4Q
    DBG4
    D88J
    DFF7
    DHP8
    EHF6
    FRK4
    FUP4
    L9U5
    LP6E
    LQZ7
    MXS3
    N782
    Q88A
    QF4Y
    U3C3
    UDR7
    YD5X
    ZF4X

    5WE3
    7W2P
    8KHE
    JTV5
    NHX8
    S3PD
    W42U

    R4YG
/;
my %skip;
@skip{ @skip }= ();
my @dirs;
my $datadir = "$Bin/../yaml-test-suite";
if (-d "$datadir") {
    opendir my $dh, $datadir or die $!;
    @dirs = map {
        "$datadir/$_"
    } grep {
        not exists $skip{ $_ }
    } grep {
        -f "$datadir/$_/in.json"
    } grep {
        m/^[A-Z0-9]{4}\z/
    } readdir $dh;
    closedir $dh;
}
else {
    diag "Skipping tests, no yaml-test-suite directory";
    ok(1);
}

@dirs = sort @dirs;

if (my $dir = $ENV{YAML_TEST_DIR}) {
    @dirs = ($dir);
}

SKIP: {
    skip "JSON::XS not nstalled", scalar(@dirs) unless $json_xs;
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref->canonical;

for my $item (@dirs) {
    my $dir = dirname $item;
    my $id = basename $item;

    open my $fh, "<", "$dir/$id/in.yaml" or die $!;
    my $yaml = do { local $/; <$fh> };
    close $fh;
    open $fh, "<", "$dir/$id/===" or die $!;
    chomp(my $title = <$fh>);
    close $fh;

    open $fh, "<", "$dir/$id/in.json" or die $!;
    my $exp_json = do { local $/; <$fh> };
    close $fh;

#    diag "------------------------------ $id";
    my $ypp = YAML::PP::Loader->new(boolean => 'JSON::PP');
    my $data = eval { $ypp->load($yaml) };
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
