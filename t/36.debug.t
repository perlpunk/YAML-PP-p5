#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

#$ENV{YAML_PP_TRACE} = 1;
BEGIN {
    $ENV{YAML_PP_DEBUG} = 1;
}
use YAML::PP::Parser;
my $yaml = "foo: bar";
my $parser = YAML::PP::Parser->new( receiver => sub {} );
no warnings 'redefine';
my $output = '';
*YAML::PP::Parser::_colorize_warn = sub {
    my ($self, $colors, $text) = @_;
    $output .= "$text\n";
};
*YAML::PP::Parser::highlight_yaml = sub {
};

$parser->parse_string($yaml);

cmp_ok($output, '=~', qr{lex_next_tokens}, "Debug output");

done_testing;
