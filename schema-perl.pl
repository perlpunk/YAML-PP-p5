#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use YAML::PP;
use YAML::PP::Schema::Perl;
use YAML::PP::Schema::Tie::IxHash;
use Tie::IxHash;

use JSON::PP;

my $true = JSON::PP::true;

my $hash = bless {
    a => 380,
    b => 52,
}, 'A::Very::Exclusive::Class';
my $array = bless [
    qw/ one two three four /
], "Just::An::Arrayref";

my $circle = bless [ 1, 2 ], 'Circle';
push @$circle, $circle;

my $re = qr{unblessed};
# !!perl/regexp (?^u:foo)
my $bre = bless qr{blessed}, "Foo";
# !!perl/regexp:Foo (?^u:bar)

my $scalar = "some string";
my $scalar2 = "some other string";
my $scalarref = \$scalar;
my $scalarref2 = bless \$scalar2, 'Foo';

# !!perl/ref
# =: foo

tie(my %order, 'Tie::IxHash');
tie(my %blessed_order, 'Tie::IxHash');
%order = (
    u => 2,
    b => 52,
    c => 64,
    19 => 84,
    disco => 2000,
    year => 2525,
    days_on_earth => 20_000,
);
%blessed_order = %order;
my $blessed_order = bless \%blessed_order, 'Order';

my $yp = YAML::PP->new(
    schema => ['JSON', 'Tie::IxHash', 'Perl'],
    boolean => 'JSON::PP',
);
my $yaml = $yp->dump_string({
    hash => $hash,
    hash2 => $hash,
    hash3 => $hash,
    array => $array,
    circle => $circle,
    order => \%order,
    order_blessed => $blessed_order,
    true => $true,
    re1 => $re,
    re2 => $bre,
    scalarref1 => $scalarref,
    scalarref2 => $scalarref2,
});
say $yaml;
