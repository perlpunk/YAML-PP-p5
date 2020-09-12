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
failsafe
FUNCTIONS
LoadFile
RAML
Schema
Schemas
loadcode
refref
scalarref
yaml
DumpFile
Nim
libyaml
vimscript
unicode
tml
schemas
Representer
TestML
USD
header
TODO
Ingy
döt
Net
flyx
Krause
Müller
