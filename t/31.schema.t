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


my $schema_file = "$Bin/../ext/yaml-test-schema/yaml-schema.yaml";
my $strings_file = "$Bin/../examples/strings.yaml";
my $schema_data = do { YAML::PP->new->load_file($schema_file) };
my $strings_data = do { YAML::PP->new->load_file($strings_file) };

$schema_data->{'#empty'}->{json_empty_null} = ['null', 'null()', "null"];
$schema_data->{'!!str #empty'}->{json_empty_null} = ['str', '', "''"];
%$schema_data = (
    %$schema_data, %$strings_data,
);

my $boolean = $jsonpp ? 'JSON::PP' : 'perl';
my %args = (
    boolean => $boolean,
    header => 0,
);
my $failsafe        = YAML::PP->new( %args, schema => [qw/ Failsafe /] );
my $json            = YAML::PP->new( %args, schema => [qw/ JSON /] );
my $json_empty_null = YAML::PP->new( %args, schema => [qw/ JSON empty=null /] );
my $core            = YAML::PP->new( %args, schema => [qw/ Core /] );
my $yaml11          = YAML::PP->new( %args, schema => [qw/ YAML1_1 /] );


subtest 'invalid-option' => sub {
    eval {
        YAML::PP->new( boolean => $boolean, schema => [qw/ JSON empty=lala /] );
    };
    my $err = $@;
    like($err, qr{Invalid option}, 'Invalid option is fatal');
};

my %loaders = (
    failsafe => $failsafe,
    json => $json,
    core => $core,
    yaml11 => $yaml11,
    json_empty_null => $json_empty_null,
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

my $i = 0;
for my $input (sort keys %$schema_data) {
    my $test_data = $schema_data->{ $input };
#    note("Input: $input");

    for my $schema_names (sort keys %$test_data) {
        note("[$input] Schemas: " . $schema_names);
        my @names = split m/ *, */, $schema_names;
        my $test = $test_data->{ $schema_names };
        for my $name (@names) {
            my $yp = $loaders{ $name };
            my %def;
            @def{ qw/ type data dump /} = @$test;
            next if ($def{type} eq 'bool' and not $jsonpp);
            my $func;
            my $data = $yp->load_string('--- ' . $input);
            my $data_orig = $data; # avoid stringifying original data

            my $flags = B::svref_2object(\$data)->FLAGS;
            my $is_str = $flags & B::SVp_POK;
            my $is_int = $flags & B::SVp_IOK;
            my $is_float = $flags & B::SVp_NOK;

            my $type = $def{type};
            my $label = sprintf "(%s) type %s: load(%s)", $name, $def{type}, $input;
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
                    cmp_ok($data, '==', $def{data}, "$label == '$def{data}'");
                }
            }
            elsif ($type eq 'float' or $type eq 'inf' or $type eq 'nan') {
                unless ($inf_broken) {
                    ok($is_float, "$label is float");
                    ok(!$is_str, "$label is not str");
                }

                unless ($func) {
                    cmp_ok(sprintf("%.2f", $data), '==', $def{data}, "$label == '$def{data}'");
                }
            }
            elsif ($type eq 'bool' or $type eq 'null') {
            }
            else {
                ok(0, "unknown type $type");
            }

            unless ($inf_broken) {
                my $yaml_dump = $yp->dump_string($data_orig);
                $yaml_dump =~ s/\n\z//;
                cmp_ok($yaml_dump, 'eq', $def{dump}, "$label-dump as expected");
            }

        }
    }
#    last if ++$i > 10;
}

subtest int_string => sub {
    my $x = "25.1";
    my $y = $x + 0;
    for my $name (qw/ json core yaml11 /) {
        my $yp = $loaders{ $name };
        my $yaml = $yp->dump_string($x);
        chomp $yaml;
        cmp_ok($yaml, 'eq', '25.1', "$name: IV and PV");
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
        cmp_ok($yaml, 'eq', '19x', "$name: NV and PV");
    }
};

done_testing;

