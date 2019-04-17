#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use Test::Deep;
use Scalar::Util ();
use YAML::PP;
use YAML::PP::Perl;
my $tests = require "$Bin/../examples/schema-perl.pm";

my $yp_perl = YAML::PP::Perl->new(
);
my $yp_loadcode = YAML::PP->new(
    schema => [qw/ JSON Perl +loadcode /],
);

my @tests = sort keys %$tests;
@tests = qw/
    array array_blessed
    hash hash_blessed
    scalarref scalarref_blessed
    refref refref_blessed
    coderef coderef_blessed
    regexp regexp_blessed
    circular
/;

{
    my $test_qr = qr{TEST_STRINGYFY_REGEX};
    my $test_qr_string = "$test_qr";
    diag("TEST QR: $test_qr_string");
    my $qr_prefix = $test_qr_string;
    $qr_prefix =~ s/TEST_STRINGYFY_REGEX.*//;
    diag("QR PREFIX: $qr_prefix");
}

for my $name (@tests) {
    my $test = $tests->{ $name };
    my $yp = $yp_perl;
    my ($code, $yaml, $options) = @$test;
    my $data = eval $code;
    my $docs = [ $data, $data ];
    my $out;
    if ($options->{load_code}) {
        $yp = $yp_loadcode;
    }
    if ($options->{load_only}) {
        $out = $yaml;
    }
    else {
        $out = $yp->dump_string($docs);
        if (ref $yaml) {
            cmp_ok($out, '=~', $yaml, "$name: dump_string()");
        }
        else {
            cmp_ok($out, 'eq', $yaml, "$name: dump_string()");
        }
        note($out);
    }

    my $reload_docs = $yp->load_string($out);
    if (Scalar::Util::reftype($data) eq 'CODE') {
        my $sub = $reload_docs->[0];
        if (ref $sub and Scalar::Util::reftype($sub) eq 'CODE') {
            my %args = ( x => 23, y => 42 );
            my $result1 = $data->(%args);
            my $result2 = $sub->(%args);
            cmp_ok($result2, 'eq', $result1, "Coderef returns the same as original");
        }
        else {
            ok(0, "Did not reload as coderef");
        }
    }
    else {
        cmp_deeply($reload_docs, $docs, "$name: Reloaded data equals original");
    }
}

subtest dummy_code => sub {
    my $yaml = <<'EOM';
---
- !perl/code |
  {
    die "oops";
  }
- !perl/code:Foo |
  {
    die "oops";
  }
EOM
    my $data = $yp_perl->load_string($yaml);
    my $code1 = $data->[0];
    my $code2 = $data->[1];
    isa_ok($code2, 'Foo', "Code is blessed 'Foo'");
    is($code1->(), undef, "Dummy code 1 returns undef");
    is($code2->(), undef, "Dummy code 2 returns undef");
};

subtest invalid_code => sub {
    my $yaml = <<'EOM';
---
- !perl/code |
    die "oops";
EOM
    my $data = eval { $yp_loadcode->load_string($yaml) };
    my $error = $@;
    cmp_ok($error, '=~', qr{Malformed code}, "Loading invalid code dies");

    $yaml = <<'EOM';
---
- !perl/code:Foo |
    die "oops";
EOM
    $data = eval { $yp_loadcode->load_string($yaml) };
    $error = $@;
    cmp_ok($error, '=~', qr{Malformed code}, "Loading invalid code dies");

    $yaml = <<'EOM';
---
- !perl/code |
    { =====> invalid <===== }
EOM
    $data = eval { $yp_loadcode->load_string($yaml) };
    $error = $@;
    cmp_ok($error, '=~', qr{eval code}, "Loading invalid code dies");

    $yaml = <<'EOM';
---
- !perl/code:Foo |
    { =====> invalid <===== }
EOM
    $data = eval { $yp_loadcode->load_string($yaml) };
    $error = $@;
    cmp_ok($error, '=~', qr{eval code}, "Loading invalid code dies");
};

subtest regex => sub {
    my $re = qr{foo};
    my $yaml = <<"EOM";
---
- !perl/regexp $re
- !perl/regexp:Foo $re
EOM
    my $data = $yp_perl->load_string($yaml);
    my ($regex1, $regex2) = @$data;
    isa_ok($regex2, 'Foo', "Regex is blessed 'Foo'");
    cmp_ok('foo', '=~', $regex1, "Loaded regex 1 matches");
    cmp_ok('foo', '=~', $regex2, "Loaded regex 2 matches");
};

subtest simple_array => sub {
    my $yaml = <<"EOM";
--- !perl/array [a, b]
EOM
    my $data = $yp_perl->load_string($yaml);
    cmp_deeply($data, [qw/ a b /], "Loaded simple array");
};

subtest invalid_ref => sub {
    my @yaml = (
        ['!perl/ref',        q#--- !perl/ref        {==: Invalid}#],
        ['!perl/ref:Foo',    q#--- !perl/ref:Foo    {==: Invalid}#],
        ['!perl/scalar',     q#--- !perl/scalar     {==: Invalid}#],
        ['!perl/scalar:Foo', q#--- !perl/scalar:Foo {==: Invalid}#],
        ['!perl/ref',        q#--- !perl/ref        {}#],
        ['!perl/ref:Foo',    q#--- !perl/ref:Foo    {}#],
        ['!perl/scalar',     q#--- !perl/scalar     {}#],
        ['!perl/scalar:Foo', q#--- !perl/scalar:Foo {}#],
    );
    for my $test (@yaml) {
        my ($type, $yaml) = @$test;
        my $data = eval { $yp_perl->load_string($yaml) };
        my $error = $@;
        cmp_ok($error, '=~', qr{Unexpected data}, "Invalid $type dies");
    }
};

done_testing;
