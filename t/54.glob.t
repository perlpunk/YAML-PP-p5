#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use Test::Deep qw/ cmp_deeply /;
use IO::File;
use YAML::PP;
use YAML::PP::Schema::Perl;
use Scalar::Util qw/ blessed reftype /;

our $var = "Hola";
our @var = (3, 14, 15);
our %var = (pi => '3.1415');
my $stdin = \*DATA,
my $fileno = fileno DATA;

my $perl_objects = YAML::PP::Schema::Perl->new(
);
my $perl_no_objects = YAML::PP::Schema::Perl->new(
    classes => [],
);
my $yp = YAML::PP->new(
    schema => ['+', $perl_objects],
);
my $yp_no_objects = YAML::PP->new(
    schema => ['+', $perl_no_objects],
);

my %tests = (
    simple => {
        in => <<'EOM',
--- !perl/glob
ARRAY:
- 3
- 14
- 15
HASH:
  pi: '3.1415'
NAME: var
PACKAGE: main
SCALAR: Hola
EOM
        name => '*main::var',
        value => 'Hola',
        types => {
            SCALAR => 'Hola',
            ARRAY => [ 3, 14, 15 ],
            HASH => { pi => '3.1415' },
        },
    },
    blessed => {
        in => <<'EOM',
--- !perl/glob:Foo
ARRAY:
- 3
- 14
- 15
HASH:
  pi: '3.1415'
NAME: var
PACKAGE: main
SCALAR: Hola
EOM
        name => '*main::var',
        class => 'Foo',
        value => 'Hola',
        types => {
            SCALAR => 'Hola',
            ARRAY => [ 3, 14, 15 ],
            HASH => { pi => '3.1415' },
        },
    },
    io => {
        in => <<"EOM",
--- !perl/glob
IO:
  fileno: $fileno
  stat: {}
NAME: DATA
PACKAGE: main
EOM
        name => '*main::DATA',
        types => {
            IO => $fileno,
        },
    },
    blessed_io => {
        in => <<"EOM",
--- !perl/glob:Foo
IO:
  fileno: $fileno
  stat: {}
NAME: DATA
PACKAGE: main
EOM
        name => '*main::DATA',
        class => 'Foo',
        types => {
            IO => $fileno,
        },
    },
);

subtest valid => sub {
    my @tests = (
        [objects => $yp],
        [no_objects => $yp_no_objects],
    );
    for my $type (@tests) {
        my ($test_type, $yp) = @$type;
        for my $key (sort keys %tests) {
            my $test = $tests{ $key };
            my $name = $test->{name};
            my $label = "$test_type - $key - $name";
            my $class = $test->{class} || '';
            note "============ $key $name";
            my $input = $test->{in};
            my $data = $yp->load_string($input);
            my $glob = *{$data};
            if ($class) {
                my $ref = ref $data;
                if ($test_type eq 'no_objects') {
                    my $reftype = reftype(\$data);
                    is($reftype, 'GLOB', "$label - ($class) reftype is glob");
                    isnt(ref $data, $class, "$label - Class not equals '$class'");
                }
                else {
                    my $reftype = reftype($data);
                    is($reftype, 'GLOB', "$label - ($class) reftype is glob");
                    is(ref $data, $class, "$label - Class equals '$class'");
                }
            }
            else {
                my $reftype = reftype(\$data);
                is($reftype, 'GLOB', "$label - reftype is glob");
            }
            is("$glob", $name, "$label - Glob name");
            my $types = $test->{types};
            for my $type (sort keys %$types) {
                my $exp = $types->{ $type };
                my $value;
                my $glob = *{$data}{ $type };
                if ($type eq 'SCALAR') {
                    $value = $$glob;
                }
                elsif ($type eq 'ARRAY') {
                    $value = [ @$glob ];
                }
                elsif ($type eq 'HASH') {
                    $value = { %$glob };
                }
                elsif ($type eq 'IO') {
                    $value = fileno $glob;
                }
                cmp_deeply($value, $exp, "$label - $type - Data equal");
            }

            my $dump = $yp->dump_string($data);
            if ($key =~ m/io/) {
                $dump =~ s/^    [a-z]+: \S+\n//mg;
                $dump =~ s/^  tell: \S+\n//m;
                $dump =~ s/stat:$/stat: \{\}/m;
            }
            if ($class and $test_type eq 'no_objects') {
                isnt($dump, $input, "$label - Dump not equals input");
            }
            else {
                is($dump, $input, "$label - Dump equals input");
            }
        }
    }
};

subtest ioscalar => sub {
    my $fh = IO::File->new("< $Bin/54.glob.t");
    my $dump = $yp->dump_string($fh);
    my $fn = $fh->fileno;
    like $dump, qr{--- !perl/glob:IO::File}, "IO::Scalar correctly dumped as blessed per/glob";
    like $dump, qr{fileno: $fn\n}, "IO::Scalar fileno correct";
};

my @error = (
    [ <<'EOM', qr{Unexpected keys in perl/glob}],
--- !perl/glob
NAME: var
this: should not be here
EOM
    [ <<'EOM', qr{Missing NAME in perl/glob}],
--- !perl/glob
name: invalid
EOM
);
subtest error => sub {
    for my $item (@error) {
        my ($input, $qr) = @$item;
        my $data = eval {
            $yp->load_string($input);
        };
        my $err = $@;
        like $err, $qr, "Invalid glob - error matches $qr";
    }
};

done_testing;

__DATA__
dummy
