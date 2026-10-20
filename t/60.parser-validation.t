#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAML::PP;

my @valid = (
    ["[? foo\n bar : baz, tail]",
        [{'foo bar' => 'baz'}, 'tail'], 'Multiline explicit flow key'],
    ['[? first: one, ? second: [two, three], ? third: {four: five}]',
        [{first => 'one'}, {second => ['two', 'three']},
            {third => {four => 'five'}}], 'Collection values in explicit pairs'],
    ['[? empty, ? : value, ? , last]',
        [{empty => undef}, {'' => 'value'}, {'' => undef}, 'last'],
        'Empty keys and values in explicit pairs'],
    ['[? &key name: &value thing, ? *key : *value]',
        [{name => 'thing'}, {name => 'thing'}], 'Aliases in explicit pairs'],
    ["[? \"foo\n bar\": \"baz\n qux\"]",
        [{'foo bar' => 'baz qux'}], 'Quoted multiline explicit key and value'],
    ['[? text: !!str ]', [{text => ''}], 'Empty tagged explicit value'],
    ['[? !!str , tail]', [{'' => undef}, 'tail'], 'Empty tagged explicit key'],
    ['[? [a, b]: [c, d]]', undef, 'Collection key in explicit pair'],
    ['::', {':' => undef}, 'Colon-only mapping key'],
    ['::: value', {'::' => 'value'}, 'Multiple-colon mapping key'],
    ["mapping:\n  :: nested", {mapping => {':' => 'nested'}},
        'Nested colon-only mapping key'],
    ["- ::\n- :::", [{':' => undef}, {'::' => undef}],
        'Colon-only keys in sequence entries'],
    ['{:: value}', {':' => 'value'}, 'Colon-only flow mapping key'],
    ["key: |\n  \n   text\n", {key => "\ntext\n"},
        'Leading blank line before more indented content'],
    ["key: |2-\n    \n  text\n", {key => "  \ntext"},
        'Explicit block indentation preserves more indented blank lines'],
);

my $yp = YAML::PP->new;
for my $case (@valid) {
    my ($yaml, $expected, $title) = @$case;
    my $got = eval { $yp->load_string($yaml) };
    is $@, '', "$title parses";
    if (defined $expected) {
        is_deeply $got, $expected, "$title preserves data";
    }
    elsif (ref $got eq 'ARRAY') {
        my ($key) = keys %{ $got->[0] };
        is_deeply $got->[0]{$key}, ['c', 'd'], "$title preserves value";
    }
}

for my $style ('|', '>', '|-', '>+') {
    my $yaml = "key: $style\n \n   \n  text\n";
    eval { $yp->load_string($yaml) };
    like $@, qr/Leading blank line is more indented/,
        "$style rejects excessive leading blank-line indentation";
}

for my $yaml ('[? key: value', '[? key', '[? key: value another: value]') {
    eval { $yp->load_string($yaml) };
    ok $@, 'Invalid explicit pair is rejected';
}

is_deeply $yp->load_string('[? key: value]'), [{key => 'value'}],
    'Loader can be reused after parser errors';

eval { $yp->load_string('["unfinished"') };
ok $@, 'Missing flow terminator after a quoted value is rejected';
is_deeply $yp->load_string('::'), {':' => undef},
    'Quoted-flow lookahead is reset before the next parse';

done_testing;
