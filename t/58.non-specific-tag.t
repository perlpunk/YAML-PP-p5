#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin '$Bin';
use YAML::PP;
use YAML::PP::Common qw/ :STYLES /;

subtest 'scalars' => sub {
    my $yp = YAML::PP->new;
    $yp->schema->add_resolver(
        tag => "!",
        match => [ all => => sub {
            my ($constructor, $event) = @_;
            my $value = $event->{value};
            if ($event->{style} != YAML_PLAIN_SCALAR_STYLE) {
                return qq{!,"$value"};
            }
            return qq{!,$value};
        }],
        implicit => 0,
    );
    $yp->schema->add_resolver(
        tag => '!roman',
        match => [ regex => qr{XII} => => sub {
            my ($constructor, $event) = @_;
            return "!roman,12";
        }],
        implicit => 1,
    );
    my $yaml = <<'EOM';
---
- XII            # non-specific tag '?'
- "XII"          # implicit non-specific tag '!'
- ! XII          # exmplicit non-specific tag '!'
- ! "XII"        # exmplicit non-specific tag '!'
EOM
    my $expected = [
        '!roman,12',
        '!,"XII"',
        '!,XII',
        '!,"XII"',
    ];
    my ($data) = $yp->load_string($yaml);
    is_deeply($data, $expected, 'Loaded data as expected')
        or diag explain $data;
};

subtest 'collections' => sub {
    my $yp = YAML::PP->new;
    $yp->schema->add_sequence_resolver(
        tag => '?',
        on_create => sub { return '' },
        on_data => sub {
            my ($constructor, $data, $list) = @_;
            my $join = shift @$list;
            $$data .= join $join, @$list;
        },
    );
    $yp->schema->add_mapping_resolver(
        tag => '?',
        on_create => sub { return { specific => 'no' } },
        on_data => sub {
            my ($constructor, $data, $list) = @_;
            %$$data = (%$$data, @$list);
        },
    );
    my $yaml = <<'EOM';
---
string: [ ' ', 'YAML', Ain't, Markup, Language ]
EOM
    my $string = "YAML Ain't Markup Language";
    my $expected = {
        specific => 'no',
        string => $string,
    };
    my ($data) = $yp->load_string($yaml);
    is_deeply($data, $expected, 'Loaded data as expected')
        or diag explain $data;
};

done_testing;
