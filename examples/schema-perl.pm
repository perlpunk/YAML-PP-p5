#!/usr/bin/env perl
use strict;
use warnings;

### TEST DATA ###

my %tests = (

    hash => [
        <<'EOM',
        bless {
            U => 2,
            B => 52,
        }, 'A::Very::Exclusive::Class'
EOM
        <<'EOM',
---
- &1 !perl/hash:A::Very::Exclusive::Class
  B: 52
  U: 2
- *1
EOM
    ],

    array => [
        <<'EOM',
        bless [
            qw/ one two three four /
        ], "Just::An::Arrayref"
EOM
        <<'EOM',
---
- &1 !perl/array:Just::An::Arrayref
  - one
  - two
  - three
  - four
- *1
EOM
    ],

    regexp => [
        <<'EOM',
        qr{unblessed}
EOM
        qr{- &1 !perl/regexp .*unblessed.*- \*1}s,
    ],

    regexp_blessed => [
        <<'EOM',
        bless qr{blessed}, "Foo"
EOM
        qr{- &1 !perl/regexp:Foo .*blessed.*- \*1}s,
    ],

    circular => [
        <<'EOM',
        my $circle = bless [ 1, 2 ], 'Circle';
        push @$circle, $circle;
        $circle;
EOM
        <<'EOM',
---
- &1 !perl/array:Circle
  - 1
  - 2
  - *1
- *1
EOM
    ],

    code => [
        <<'EOM',
        sub {
            my ($self, %args) = @_;
            return $args{x} + $args{y};
        }
EOM
        qr{- &1 !perl/code \|-.*return.*args.*x.*\+.*y}s,
    ],

    code_blessed => [
        <<'EOM',
        bless sub {
            my ($self, %args) = @_;
            return $args{x} - $args{y};
        }, "I::Am::Code"
EOM
        qr{- &1 !perl/code:I::Am::Code \|-.*return.*args.*x.*\-.*y}s,
    ],

    scalarref => [
        <<'EOM',
        my $scalar = "some string";
        my $scalarref = \$scalar;
        $scalarref;
EOM
        <<'EOM',
---
- &1 !perl/scalar
  =: some string
- *1
EOM
    ],

    scalarref_blessed => [
        <<'EOM',
        my $scalar = "some other string";
        my $scalarref = bless \$scalar, 'Foo';
        $scalarref;
EOM
        <<'EOM',
---
- &1 !perl/scalar:Foo
  =: some other string
- *1
EOM
    ],
);

### TEST DATA END ###

\%tests;
