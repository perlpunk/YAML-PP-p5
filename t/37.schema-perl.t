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

my $perl_no_objects = YAML::PP::Schema::Perl->new(
    classes => [],
);
my $perl_no_objects_loadcode = YAML::PP::Schema::Perl->new(
    classes => [],
    loadcode => 1,
);

my $yp_perl = YAML::PP::Perl->new(
    schema => [qw/ JSON Perl tags=!perl /],
);
my $yp_perl_no_objects = YAML::PP::Perl->new(
    schema => [qw/ JSON /, $perl_no_objects],
);
my $yp_loadcode = YAML::PP->new(
    schema => [qw/ JSON Perl +loadcode /],
);
my $yp_loadcode_no_objects = YAML::PP->new(
    schema => [qw/ JSON /, $perl_no_objects_loadcode],
);
my $yp_perl_two = YAML::PP::Perl->new(
    schema => [qw/ JSON Perl tags=!!perl /],
);
my $yp_loadcode_two = YAML::PP->new(
    schema => [qw/ JSON Perl tags=!!perl +loadcode /],
);
my $yp_loadcode_one_two = YAML::PP->new(
    schema => [qw/ JSON Perl tags=!perl+!!perl +loadcode /],
);
my $yp_loadcode_two_one = YAML::PP->new(
    schema => [qw/ JSON Perl tags=!!perl+!perl +loadcode /],
);
my $yp_perl_one_two = YAML::PP::Perl->new(
    schema => [qw/ JSON Perl tags=!perl+!!perl /],
);
my $yp_perl_two_one = YAML::PP::Perl->new(
    schema => [qw/ JSON Perl tags=!!perl+!perl /],
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

my %loaders_perl = (
    one => $yp_perl,
    one_no_objects => $yp_perl_no_objects,
    two => $yp_perl_two,
    onetwo => $yp_perl_one_two,
    twoone => $yp_perl_two_one,
);
my %loaders_perl_code = (
    one => $yp_loadcode,
    one_no_objects => $yp_loadcode_no_objects,
    two => $yp_loadcode_two,
    onetwo => $yp_loadcode_one_two,
    twoone => $yp_loadcode_two_one,
);
my @tagtypes = qw/ one two onetwo twoone /;
for my $type (@tagtypes) {
    for my $name (@tests) {
        test_perl($type, $name);
    }
}

sub test_perl {
    my ($type, $name) = @_;
    my $test = $tests->{ $name };
    my $yp = $yp_perl;
    $yp = $loaders_perl{ $type };
    my ($code, $yaml, $options) = @$test;
    if ($type eq 'two' or $type eq 'twoone') {
        unless (ref $yaml) {
            $yaml =~ s/\!perl/!!perl/g;
        }
    }
    my $data = eval $code;
    my $docs = [ $data, $data ];
    my $out;
    if ($options->{load_code}) {
        $yp = $loaders_perl_code{ $type };
    }
    if ($options->{load_only}) {
        $out = $yaml;
    }
    else {
        $out = $yp->dump_string($docs);
        if (ref $yaml) {
            cmp_ok($out, '=~', $yaml, "tagtype=$type $name: dump_string()");
        }
        else {
            cmp_ok($out, 'eq', $yaml, "tagtype=$type $name: dump_string()");
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
            cmp_ok($result2, 'eq', $result1, "tagtype=$type Coderef returns the same as original");
        }
        else {
            ok(0, "tagtype=$type Did not reload as coderef");
        }
    }
    else {
        cmp_deeply($reload_docs, $docs, "tagtype=$type $name: Reloaded data equals original");
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

subtest array => sub {
    my $object = bless [qw/ a b /], "Foo";
    my $yaml_one_two = $yp_perl_one_two->dump_string($object);
    my $yaml_one_two_expected = <<'EOM';
--- !perl/array:Foo
- a
- b
EOM
    my $yaml_two_one_expected = <<'EOM';
--- !!perl/array:Foo
- a
- b
EOM
    my $yaml_two_one = $yp_perl_two_one->dump_string($object);
    cmp_ok($yaml_one_two, 'eq', $yaml_one_two_expected, "Perl =!+!! dump");
    cmp_ok($yaml_two_one, 'eq', $yaml_two_one_expected, "Perl =!!+! dump");
    my $reload1 = $yp_perl_two_one->load_string($yaml_one_two);
    my $reload2 = $yp_perl_two_one->load_string($yaml_two_one);
    my $reload3 = $yp_perl_one_two->load_string($yaml_one_two);
    my $reload4 = $yp_perl_one_two->load_string($yaml_two_one);
    cmp_deeply($reload1, $object, "Reload 1");
    cmp_deeply($reload2, $object, "Reload 2");
    cmp_deeply($reload3, $object, "Reload 3");
    cmp_deeply($reload4, $object, "Reload 4");
};

subtest no_objects => sub {
    my $yaml = <<'EOM';
---
- !perl/array:Foo [a]
- !perl/hash:Foo { a: 1 }
- !perl/code:Foo "sub { return 23 }"
- !perl/ref:Foo { = : { a: 1 } }
- !perl/scalar:Foo { = : foo }
- !perl/regexp:Foo foo
EOM

    my $perl = YAML::PP::Schema::Perl->new(
        classes => [],
    );
    my $yp = YAML::PP::Perl->new(
        schema => [qw/ JSON /, $perl],
    );
    my $data = $yp->load_string($yaml);
    for my $i (0 .. $#$data) {
        my $item = $data->[ $i ];
        my $blessed = Scalar::Util::blessed($item) || '';
        if ($blessed eq 'Regexp') {
            ok(1, "Data $i not blessed");
        }
        else {
            cmp_ok($blessed, 'eq', '', "Data $i not blessed");
        }
    }
};

subtest some_objects => sub {
    my $yaml = <<'EOM';
---
- !perl/array:Foo [a]
- !perl/hash:Foo { a: 1 }
- !perl/code:Foo "sub { return 23 }"
- !perl/ref:Foo { = : { a: 1 } }
- !perl/scalar:Foo { = : foo }
- !perl/regexp:Foo foo

- !perl/array:Bar [a]
- !perl/hash:Bar { a: 1 }
- !perl/code:Bar "sub { return 23 }"
- !perl/ref:Bar { = : { a: 1 } }
- !perl/scalar:Bar { = : foo }
- !perl/regexp:Bar foo
EOM

    my $perl = YAML::PP::Schema::Perl->new(
        classes => ['Bar'],
    );
    my $yp = YAML::PP::Perl->new(
        schema => [qw/ JSON /, $perl],
    );
    my $data = $yp->load_string($yaml);

    for my $i (0 .. $#$data) {
        my $item = $data->[ $i ];
        my $blessed = Scalar::Util::blessed($item) || '';
        if ($blessed eq 'Regexp') {
            ok(1, "Data $i not blessed");
        }
        elsif ($i > 5) {
            cmp_ok($blessed, 'eq', 'Bar', "Data $i blessed");
        }
        else {
            cmp_ok($blessed, 'eq', '', "Data $i not blessed");
        }
    }
};

done_testing;
