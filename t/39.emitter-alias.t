#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 1;

use YAML::PP;
use YAML::PP::Common;
use YAML::PP::Emitter;
use YAML::PP::Writer;

my $writer = YAML::PP::Writer->new;
my $emitter = YAML::PP::Emitter->new();
$emitter->set_writer($writer);
my @events = (
    '+STR',
    '+DOC ---',

    '+SEQ',

    '+MAP &map <tag:yaml.org,2002:map>',
    '=VAL <tag:yaml.org,2002:str> :foo',
    '=VAL :bar',
    '-MAP',

    '+SEQ',
    '=ALI *map',
    '=ALI *map',
    '-SEQ',

    '+MAP',
    '=ALI *map',
    '=VAL :foo',
    '=ALI *map',
    '=VAL :foo',
    '-MAP',

    '+MAP',
    '+SEQ <tag:yaml.org,2002:seq>',
    '-SEQ',
    '=ALI *map',
    '-MAP',

    '+MAP',
    '+MAP <tag:yaml.org,2002:map>',
    '-MAP',
    '=ALI *map',
    '-MAP',

    '-SEQ',

    '-DOC',
    '-STR',
);

for my $str (@events) {
    my $event = YAML::PP::Common::test_suite_to_event($str);
    my $name = $event->{name};
    $emitter->$name($event);
}
my $yaml = $emitter->writer->output;

my $exp = <<'EOM';
---
- &map !!map
  !!str foo: bar
- - *map
  - *map
- *map : foo
  *map : foo
- ? !!seq []
  : *map
- ? !!map {}
  : *map
EOM
cmp_ok($yaml, 'eq', $exp, "alias_event correct");
