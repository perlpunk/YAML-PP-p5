#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAML::PP::Highlight;

my $yaml = "foo: bar\n";
my ($error, $tokens) = YAML::PP::Parser->yaml_to_tokens(string => $yaml);

delete @$_{qw/ line column /} for @$tokens;

my @expected_tokens = (
    { name => "PLAIN", value => "foo" },
    { name => "COLON", value => ":" },
    { name => "WS", value => " " },
    { name => "PLAIN", value => "bar" },
    { name => "EOL", value => "\n" },
);

is($error, '', "yaml_to_tokens suceeded");
is_deeply($tokens, \@expected_tokens, "yaml_to_tokens returned correct tokens");

$yaml = "foo: \@bar\n";
($error, $tokens) = YAML::PP::Parser->yaml_to_tokens(string => $yaml);

cmp_ok($error, '=~', qr{Invalid}, "yaml_to_tokens returned an error");

delete @$_{qw/ line column /} for @$tokens;

@expected_tokens = (
    { name => "PLAIN", value => "foo" },
    { name => "COLON", value => ":" },
    { name => "WS", value => " " },
    { name => "ERROR", value => "\@bar\n" },
);
is_deeply($tokens, \@expected_tokens, "yaml_to_tokens returned correct error tokens");

$yaml = <<'EOM';
foo: |
  bar  
quoted: "x"
EOM
($error, $tokens) = YAML::PP::Parser->yaml_to_tokens(string => $yaml);
my @transformed = YAML::PP::Highlight->transform($tokens);
cmp_ok($transformed[6]->{name}, 'eq', 'TRAILING_SPACE', "trailing spaces detected");

my $color = eval "use Term::ANSIColor 4.02; 1";
# older versions of Term::ANSIColor didn't have grey12
if ($color) {
    my $highlighted = YAML::PP::Highlight::Dump({ foo => 'bar' });
    my $exp_highlighted = "\e[1m---\e[0m\n\e[94mfoo\e[0m\e[1;35m:\e[0m bar\n";
    cmp_ok($highlighted, 'eq', $exp_highlighted, "YAML::PP::Highlight::Dump()");
}

if ($color) {
    my $yaml = <<'EOM';
foo: bar	
EOM
    my ($error, $tokens) = YAML::PP::Parser->yaml_to_tokens(string => $yaml);

    my $ansitabs = YAML::PP::Highlight->ansicolored($tokens, expand_tabs => 0);
    my $ansi = YAML::PP::Highlight->ansicolored($tokens);

    local $Data::Dumper::Useqq = 1;
    my $exp1 = "\e[94mfoo\e[0m\e[1;35m:\e[0m bar\e[44m\t\e[0m\n";
    my $exp2 = "\e[94mfoo\e[0m\e[1;35m:\e[0m bar\e[44m        \e[0m\n";
    is $ansitabs, $exp1, 'ansicolored, no expanded tabs' or do {
        diag(Data::Dumper->Dump([$ansitabs], ['ansitabs']));
    };
    is $ansi, $exp2, 'ansicolored, expanded tabs' or do {
        diag(Data::Dumper->Dump([$ansi], ['ansi']));
    };
}

done_testing;
