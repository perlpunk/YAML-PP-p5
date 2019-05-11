#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use B ();
use Data::Dumper;
use Scalar::Util qw/ blessed /;
use YAML::PP;

my $jsonpp = eval { require JSON::PP };


my $schema_file = "$Bin/../examples/yaml-schema.yaml";
my $schema_data = do { YAML::PP->new->load_file($schema_file) };

my $boolean = $jsonpp ? 'JSON::PP' : 'perl';
my $failsafe = YAML::PP->new( boolean => $boolean, schema => [qw/ Failsafe /] );
my $json     = YAML::PP->new( boolean => $boolean, schema => [qw/ JSON /] );
my $core     = YAML::PP->new( boolean => $boolean, schema => [qw/ Core /] );
my $yaml11   = YAML::PP->new( boolean => $boolean, schema => [qw/ YAML1_1 /] );
my %loaders = (
    failsafe => $failsafe,
    json => $json,
    core => $core,
    yaml11 => $yaml11,
);
my $inf = 0 + 'inf';
my $inf_negative = 0 - 'inf';
my $nan = 0 + 'nan';
diag("inf: $inf -inf: $inf_negative nan: $nan");
my $inf_broken = $inf eq '0';
$inf_broken and diag("inf/nan seem broken, skipping those tests");

my %check = (
    null => sub { not defined $_[0] },
    inf => sub {
        my ($float) = @_;
        return $float eq $inf;
    },
    'inf-neg' => sub {
        my ($float) = @_;
        return $float eq $inf_negative;
    },
    nan => sub {
        my ($float) = @_;
        return $float eq $nan;
    },
);
if ($jsonpp) {
    %check = (
        %check,
        true => sub {
            blessed($_[0]) eq 'JSON::PP::Boolean'
            and $_[0]
        },
        false => sub {
            blessed($_[0]) eq 'JSON::PP::Boolean'
            and not $_[0]
        },
    );
}

for my $schema_names (sort keys %$schema_data) {
    my @names = split m/ *, */, $schema_names;
    my $tests = $schema_data->{ $schema_names };
    for my $name (@names) {
        my $yp = $loaders{ $name };
        for my $test (@$tests) {
            my %def;
            @def{ qw/ type yaml data dump /} = @$test;
            next if ($def{type} eq 'bool' and not $jsonpp);
            my $func;
            my $data = $yp->load_string('--- ' . $def{yaml});
            my $data_orig = $data; # avoid stringifying original data

            my $flags = B::svref_2object(\$data)->FLAGS;
            my $is_str = $flags & B::SVp_POK;
            my $is_int = $flags & B::SVp_IOK;
            my $is_float = $flags & B::SVp_NOK;

            my $type = $def{type};
            my $subtype = '';
            if ($type =~ s/-(\w+)//) {
                $subtype = $1;
            }
            my $label = sprintf "(%s) type %s: load(%s)", $name, $def{type}, $def{yaml};
            if ($def{data} =~ m/^([\w-]+)\(\)$/) {
                my $func_name = $1;
                $func = $check{ $func_name };
                my $ok = $func->($data);
                ok($ok, "$label - check $func_name() ok");
            }
            if ($type eq 'str') {
                ok($is_str, "$label is str");
                ok(! $is_int, "$label is not int");
                ok(! $is_float, "$label is not float");

                unless ($func) {
                    cmp_ok($def{data}, 'eq', $data, "$label eq '$def{data}'");
                }
            }
            elsif ($type eq 'int') {
                ok($is_int, "$label is int");
                ok(!$is_str, "$label is not str");

                unless ($func) {
                    cmp_ok($data, 'eq', $def{data}, "$label eq '$def{data}'");
                }
            }
            elsif ($type eq 'float') {
                unless ($inf_broken) {
                    ok($is_float, "$label is float");
                    ok(!$is_str, "$label is not str");
                }

                unless ($func) {
                    cmp_ok($data, 'eq', $def{data}, "$label eq '$def{data}'");
                }
            }
            elsif ($type eq 'bool' or $type eq 'null') {
            }
            else {
                ok(0, "unknown type $type");
            }

            unless ($inf_broken) {
                my $yaml_dump = $yp->dump_string($data_orig);
                $yaml_dump =~ s/^--- //;
                $yaml_dump =~ s/\n\z//;
                cmp_ok($yaml_dump, 'eq', $def{dump}, "$label-dump as expected");
            }

        }
    }
}

subtest int_string => sub {
    my $x = "25.1";
    my $y = $x + 0;
    for my $name (qw/ json core yaml11 /) {
        my $yp = $loaders{ $name };
        my $yaml = $yp->dump_string($x);
        chomp $yaml;
        cmp_ok($yaml, 'eq', '--- 25.1', "$name: IV and PV");
    }
};

subtest float_string => sub {
    my $x = 19;
    {
        no warnings 'numeric';
        $x .= "x";
        my $y = $x + 0;
    };
    for my $name (qw/ json core yaml11 /) {
        my $yp = $loaders{ $name };
        my $yaml = $yp->dump_string($x);
        chomp $yaml;
        cmp_ok($yaml, 'eq', '--- 19x', "$name: NV and PV");
    }
};

done_testing;

