#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAML::PP::Highlight;

my $yaml = "foo: bar\n";
my ($error, $tokens) = YAML::PP::Highlight->parse_tokens(string => $yaml);

my @tokens = map { +{ value => $_->{value}, name => $_->{name} } } @$tokens;

my @expected_tokens = (
    { name => "PLAIN", value => "foo" },
    { name => "COLON", value => ":" },
    { name => "WS", value => " " },
    { name => "PLAIN", value => "bar" },
    { name => "EOL", value => "\n" },
);

is($error, '', "parse_tokens suceeded");
is_deeply(\@tokens, \@expected_tokens, "parse_tokens returned correct tokens");


$yaml = "foo: \@bar\n";
($error, $tokens) = YAML::PP::Highlight->parse_tokens(string => $yaml);

cmp_ok($error, '=~', qr{Invalid}, "parse_tokens returned an error");

@tokens = map { +{ value => $_->{value}, name => $_->{name} } } @$tokens;

@expected_tokens = (
    { name => "PLAIN", value => "foo" },
    { name => "COLON", value => ":" },
    { name => "WS", value => " " },
    { name => "ERROR", value => "\@bar\n" },
    { name => "ERROR", value => "" },
);
is_deeply(\@tokens, \@expected_tokens, "parse_tokens returned correct error tokens");

my $color = eval "use Term::ANSIColor 4.02; 1";
# older versions of Term::ANSIColor didn't have grey12
if ($color) {
    my $highlighted = YAML::PP::Highlight::Dump("foo: bar\n");
    my $exp_highlighted = "\e[1m---\e[0m \e[1;33m|\e[0m\n\e[37;48;5;235m  \e[0m\e[33mfoo: bar\e[0m\n\n";
    cmp_ok($highlighted, 'eq', $exp_highlighted, "YAML::PP::Highlight::Dump()");
}

done_testing;
