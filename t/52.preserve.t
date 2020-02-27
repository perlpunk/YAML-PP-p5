#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin '$Bin';
use YAML::PP;
use YAML::PP::Common qw/ PRESERVE_ORDER PRESERVE_SCALAR_STYLE /;


subtest 'preserve-scalar-style' => sub {
    my $yp = YAML::PP->new( preserve => PRESERVE_ORDER | PRESERVE_SCALAR_STYLE );
    my $yaml = <<'EOM';
---
p: plain
's': 'single'
"d": "double"
f: >-
  folded
? |-
  l
: |-
  literal
nl: |+

...
---
- 0
- null
- 23
- "42"
- !!int '99'
EOM
    my $exp_styles = <<'EOM';
---
p: plain
's': 'single'
"d": "double"
f: folded
? |-
  l
: |-
  literal
nl: |+

...
EOM
    my $exp_data = <<'EOM';
---
- 0
- null
- 23
- "42"
- 99
EOM
    my @docs = $yp->load_string($yaml);
    my $styles = $docs[0];
    my $data = $docs[1];

    my $dump_styles = $yp->dump_string($styles);
    is($dump_styles, $exp_styles, 'preserve=1 dump styless ok');

    my $newline = delete $styles->{nl};
    my $string = join ' ', values %$styles;
    is($string, 'plain single double folded literal', 'Strings');

    my $dump_data = $yp->dump_string($data);
    is($dump_data, $exp_data, 'preserve=1 dump data ok');

    $styles->{s} .= ' APPEND';
    is($styles->{s}, 'single APPEND', 'append works');
    is($yp->dump_string($styles->{s}), "--- single APPEND\n", 'Style gets lost on append');

    $newline->{value} = "\n\n";
    is($yp->dump_string($newline),qq{--- |+\n\n\n...\n}, 'Style is preserved for direct assignment');
    $newline->{value} = "\0";
    is($yp->dump_string($newline),qq{--- "\\0"\n}, 'Style gets changed if necessary');
};

subtest 'preserve-order' => sub {
    my $yp = YAML::PP->new( preserve => PRESERVE_ORDER );

    my $yaml = <<'EOM';
---
z: 1
a: 2
y: 3
b: 4
x: 5
c: 6
EOM

    my $data = $yp->load_string($yaml);
    my $dump = $yp->dump_string($data);

    is($dump, $yaml, 'preserve=1 Key order preserved');

    my @keys = keys %$data;
    is("@keys", "z a y b x c", 'keys()');

    is($data->{a}, 2, 'hash a');
    my $first = each %$data;
    is($first, 'z', 'First key');
    my $next = each %$data;
    is($next, 'a', 'Next key');

    is(delete $data->{z}, 1, 'delete(z)');
    @keys = keys %$data;
    is("@keys", "a y b x c", 'keys()');

    $data->{z} = 99;
    @keys = keys %$data;
    is("@keys", "a y b x c z", 'keys()');

    my @values = values %$data;
    is("@values", "2 3 4 5 6 99", 'values()');

    is(exists $data->{a}, 1, 'exists(a)');
    is(exists $data->{A}, '', 'exists(A)');

    %$data = ();
    is(scalar keys %$data, 0, 'clear');
};

subtest 'object-order' => sub {
    my $yp = YAML::PP->new(
        schema => [qw/ + Perl /],
        preserve => PRESERVE_ORDER,
    );
    my $yaml = <<'EOM';
---
- !perl/hash:Foo
  z: 1
  a: 2
  y: 3
  b: 4
  x: 5
  c: 6
EOM
    my $data = $yp->load_string($yaml);
    my $dump = $yp->dump_string($data);
    is($dump, $yaml, 'load-dump object with preserved hash key order');
};

done_testing;
