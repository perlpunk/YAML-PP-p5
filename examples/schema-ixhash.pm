#!/usr/bin/env perl
use strict;
use warnings;

### TEST DATA ###

my %tests = (

### - Ordered Hashref (Tie::IxHash)
    order => [
        <<'EOM',
        tie(my %order, 'Tie::IxHash');
        %order = (
            U => 2,
            B => 52,
            c => 64,
            19 => 84,
            Disco => 2000,
            Year => 2525,
            days_on_earth => 20_000,
        );
        \%order;
EOM
        <<'EOM',
---
- &1
  U: 2
  B: 52
  c: 64
  19: 84
  Disco: 2000
  Year: 2525
  days_on_earth: 20000
- *1
EOM
    ],

### - Blessed Ordered Hashref
    order_blessed => [
        <<'EOM',
        tie(my %order, 'Tie::IxHash');
        %order = (
            U => 2,
            B => 52,
            c => 64,
            19 => 84,
            Disco => 2000,
            Year => 2525,
            days_on_earth => 20_000,
        );
        bless \%order, 'Order';
EOM
        <<'EOM',
---
- &1 !perl/hash:Order
  U: 2
  B: 52
  c: 64
  19: 84
  Disco: 2000
  Year: 2525
  days_on_earth: 20000
- *1
EOM
    ],

);

### TEST DATA END ###

\%tests;
