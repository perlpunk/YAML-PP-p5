#!/usr/bin/env perl
use strict;
use warnings;

my %tests = (

    hash => [
        <<'EOM',
        {
            U => 2,
            B => 52,
        }
EOM
        <<'EOM',
---
- &1 !perl/hash
  B: 52
  U: 2
- *1
EOM
        { load_only => 1 },
    ],

    hash_blessed => [
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
        [
            qw/ one two three four /
        ]
EOM
        <<'EOM',
---
- &1 !perl/array
  - one
  - two
  - three
  - four
- *1
EOM
        { load_only => 1 },
    ],

    array_blessed => [
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
        my $string = 'unblessed';
        qr{$string}
EOM
        <<"EOM",
---
- &1 !perl/regexp unblessed
- *1
EOM
    ],

    regexp_blessed => [
        <<'EOM',
        my $string = 'blessed';
        bless qr{$string}, "Foo"
EOM
        <<"EOM",
---
- &1 !perl/regexp:Foo blessed
- *1
EOM
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

    coderef => [
        <<'EOM',
        sub {
            my (%args) = @_;
            return $args{x} + $args{y};
        }
EOM
        qr{- &1 !{1,2}perl/code \|-.*return.*args.*x.*\+.*y}s,
        { load_code => 1 },
    ],

    coderef_blessed => [
        <<'EOM',
        bless sub {
            my (%args) = @_;
            return $args{x} - $args{y};
        }, "I::Am::Code"
EOM
        qr{- &1 !{1,2}perl/code:I::Am::Code \|-.*return.*args.*x.*\-.*y}s,
        { load_code => 1 },
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
    refref => [
        <<'EOM',
        my $ref = { a => 'hash' };
        my $refref = \$ref;
        $refref;
EOM
        <<'EOM',
---
- &1 !perl/ref
  =:
    a: hash
- *1
EOM
    ],

    refref_blessed => [
        <<'EOM',
        my $ref = { a => 'hash' };
        my $refref = bless \$ref, 'Foo';
        $refref;
EOM
        <<'EOM',
---
- &1 !perl/ref:Foo
  =:
    a: hash
- *1
EOM
    ],
);

\%tests;
