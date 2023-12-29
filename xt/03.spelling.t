#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Test::Spelling;
use Pod::Wordlist;

add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib ) );

__DATA__
ansi
dumpcode
DumpFile
failsafe
FUNCTIONS
header
loadcode
libsyck
libyaml
linter
LoadFile
Nim
PyYAML
RAML
refref
Representer
roundtrip
scalarref
schemas
Schema
Schemas
superset
tml
TODO
unicode
USD
vimscript
yaml
yamllint
Ingy
döt
Net
flyx
Krause
Müller
