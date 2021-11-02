#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin '$Bin';
use YAML::PP;
use YAML::PP::Common qw/
    PRESERVE_ORDER PRESERVE_SCALAR_STYLE PRESERVE_FLOW_STYLE PRESERVE_ALIAS
    YAML_LITERAL_SCALAR_STYLE YAML_FLOW_MAPPING_STYLE YAML_FLOW_SEQUENCE_STYLE
/;

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
    my $scalar = scalar %$data;
    if ($] >= 5.026) {
        is(scalar %$data, 6, 'scalar');
    }

    my @values = values %$data;
    is("@values", "2 3 4 5 6 99", 'values()');

    is(exists $data->{a}, 1, 'exists(a)');
    is(exists $data->{A}, '', 'exists(A)');

    %$data = ();
    is(scalar keys %$data, 0, 'clear');
    is(scalar %$data, 0, 'clear');
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

subtest 'preserve-flow' => sub {
    my $yp = YAML::PP->new(
        preserve => PRESERVE_FLOW_STYLE,
    );
    my $yaml = <<'EOM';
---
map: {z: 1, a: 2, y: 3, b: 4}
seq: [c, b, {y: z}]
EOM
    my $exp_sorted = <<'EOM';
---
map: {a: 2, b: 4, y: 3, z: 1}
seq: [c, b, {y: z}]
EOM
    my $data = $yp->load_string($yaml);
    my $dump = $yp->dump_string($data);
    is($dump, $exp_sorted, 'load-dump with preserve flow');
    is(exists($data->{seq}->[0]), 1, 'load sequence');
    is(exists($data->{seq}->[3]), !1, 'load sequence');

    $yp = YAML::PP->new(
        preserve => PRESERVE_FLOW_STYLE | PRESERVE_ORDER
    );
    $data = $yp->load_string($yaml);
    $dump = $yp->dump_string($data);
    is($dump, $yaml, 'load-dump with preserve flow && order');

    $yp = YAML::PP->new(
        schema => [qw/ + Perl /],
        preserve => PRESERVE_FLOW_STYLE | PRESERVE_ORDER,
    );
    $yaml = <<'EOM';
--- !perl/hash:Foo
map: {z: 1, a: 2, y: 3, b: 4}
seq: [c, b, {y: z}]
EOM
    $data = $yp->load_string($yaml);
    $dump = $yp->dump_string($data);
    is($dump, $yaml, 'load-dump object with preserved flow && order');
};

subtest 'create-preserve' => sub {
    my $yp = YAML::PP->new(
        preserve => 1,
    );
    my $scalar = $yp->preserved_scalar("\n", style => YAML_LITERAL_SCALAR_STYLE );
    my $data = { literal => $scalar };
    my $dump = $yp->dump_string($data);
    my $yaml = <<'EOM';
---
literal: |+

...
EOM
    is($dump, $yaml, 'dump with preserved scalar');

    my $hash = $yp->preserved_mapping({}, style => YAML_FLOW_MAPPING_STYLE);
    %$hash = (z => 1, a => 2, y => 3, b => 4);
    my $array = $yp->preserved_sequence([23, 24], style => YAML_FLOW_SEQUENCE_STYLE);
    $data = $yp->preserved_mapping({});
    %$data = ( map => $hash, seq => $array );
    $dump = $yp->dump_string($data);
    $yaml = <<'EOM';
---
map: {z: 1, a: 2, y: 3, b: 4}
seq: [23, 24]
EOM
    is($dump, $yaml, 'dump with preserved flow && order');

    my $alias1 = $yp->preserved_mapping({ a => 1 }, alias => 'MAP', style => YAML_FLOW_MAPPING_STYLE);
    my $alias2 = $yp->preserved_sequence([qw/ x y z /], alias => 'SEQ', style => YAML_FLOW_SEQUENCE_STYLE);
    my $alias3 = $yp->preserved_scalar('string', alias => 'SCALAR');
    $data = $yp->preserved_sequence([$alias1, $alias2, $alias3, $alias3, $alias2, $alias1]);
    $dump = $yp->dump_string($data);
    my $expected = <<'EOM';
---
- &MAP {a: 1}
- &SEQ [x, y, z]
- &SCALAR string
- *SCALAR
- *SEQ
- *MAP
EOM
    is $dump, $expected, 'dump with preserved map/seq/scalar and aliases';
};

subtest 'tie-array' => sub {
    my $x = YAML::PP->preserved_sequence([23, 24], style => YAML_FLOW_SEQUENCE_STYLE);
    @$x = (25, 26);
    is("@$x", '25 26', 'STORE');
    unshift @$x, 24;
    is("@$x", '24 25 26', 'UNSHIFT');
    shift @$x;
    is("@$x", '25 26', 'SHIFT');
    splice @$x, 1, 1, 99, 100;
    is("@$x", '25 99 100', 'SPLICE');
    delete $x->[1];
    {
        no warnings 'uninitialized';
        is("@$x", '25  100', 'DELETE');
    }
    $x->[1] = 99;
    $#$x = 1;
    is("@$x", '25 99', 'STORESIZE');
};

subtest 'tie-scalar' => sub {
    my $scalar = YAML::PP->preserved_scalar("abc", style => YAML_LITERAL_SCALAR_STYLE );
    like $scalar, qr{abc}, 'Regex';
    ok($scalar eq 'abc', 'eq');
    ok('abc' eq $scalar, 'eq');
    ok($scalar gt 'abb', 'gt');

    $scalar = YAML::PP->preserved_scalar(23, style => YAML_LITERAL_SCALAR_STYLE );
    ok($scalar > 22, '>');
    ok($scalar <= 23, '<=');
};

subtest 'aliases' => sub {
    my $yaml = <<'EOM';
---
mapping: &mapping
  a: 1
  b: 2
alias: *mapping
seq: &seq
- a
- b
same: *seq
str: &scalar xyz
copy: *scalar
EOM
    my $sorted = <<'EOM';
---
alias: &mapping
  a: 1
  b: 2
copy: &scalar xyz
mapping: *mapping
same: &seq
- a
- b
seq: *seq
str: *scalar
EOM
    my $yp = YAML::PP->new( preserve => PRESERVE_ALIAS );
    my $data = $yp->load_string($yaml);
    my $dump = $yp->dump_string($data);
    is($dump, $sorted, "Preserving alias names, but not order");

    $yp = YAML::PP->new( preserve => PRESERVE_ORDER | PRESERVE_ALIAS );
    $data = $yp->load_string($yaml);
    $dump = $yp->dump_string($data);
    is($dump, $yaml, "Preserving alias names and order");

    $yp = YAML::PP->new( preserve => PRESERVE_ALIAS | PRESERVE_FLOW_STYLE );
    $yaml = <<'EOM';
---
a: &seq [a]
b: *seq
c: &seq [c]
d: *seq
e: &map {e: 1}
f: *map
g: &map {g: 1}
h: *map
i: &scalar X
j: *scalar
k: &scalar Y
l: *scalar
EOM
    $data = $yp->load_string($yaml);
    $dump = $yp->dump_string($data);

    my $swap = $data->{a};
    $data->{a} = $data->{d};
    $data->{d} = $swap;
    $swap = $data->{e};
    $data->{e} = $data->{h};
    $data->{h} = $swap;
    $swap = $data->{i};
    $data->{i} = $data->{l};
    $data->{l} = $swap;

    $dump = $yp->dump_string($data);
    my $expected = <<'EOM';
---
a: &1 [c]
b: &seq [a]
c: *1
d: *seq
e: &2 {g: 1}
f: &map {e: 1}
g: *2
h: *map
i: &3 Y
j: &scalar X
k: *3
l: *scalar
EOM
    is $dump, $expected, 'dump - Repeated anchors are removed';
    my $reload = $yp->load_string($dump);
    is_deeply($reload, $data, 'Reloading after shuffling wiht repeated anchors');
};

subtest 'create-tied-automatically' => sub {
    my $yp = YAML::PP->new( preserve => PRESERVE_ORDER );
    my $outer = $yp->preserved_mapping({});
    %$outer = (z => 1, a => 2, y => 3, b => 4);
    my $array =  $outer->{new} = [];
    my $inner = $outer->{new}->[0] = {};
    $inner->{Z} = 1;
    $inner->{A} = 2;
    $inner->{Y} = 3;
    $inner->{B} = 4;

    push @$array, {};
    my $inner2 = $outer->{new}->[1];
    $inner2->{Z} = 11;
    $inner2->{A} = 22;
    $inner2->{Y} = 33;
    $inner2->{B} = 44;

    splice @$array, 0, 0, {};
    my $inner3 = $outer->{new}->[0];
    $inner3->{Z} = 111;
    $inner3->{A} = 222;
    $inner3->{Y} = 333;
    $inner3->{B} = 444;

    unshift @$array, {};
    my $inner4 = $outer->{new}->[0];
    $inner4->{Z} = 1111;
    $inner4->{A} = 2222;
    $inner4->{Y} = 3333;
    $inner4->{B} = 4444;

    $outer->{new}->[4] = { key => 4 };
    $outer->{new}->[5] = [55];
    $outer->{newer} = { key => 6 };
    $outer->{newest} = [66];

    my $dump = $yp->dump_string($outer);
    my $expected = <<'EOM';
---
z: 1
a: 2
y: 3
b: 4
new:
- Z: 1111
  A: 2222
  Y: 3333
  B: 4444
- Z: 111
  A: 222
  Y: 333
  B: 444
- Z: 1
  A: 2
  Y: 3
  B: 4
- Z: 11
  A: 22
  Y: 33
  B: 44
- key: 4
- - 55
newer:
  key: 6
newest:
- 66
EOM
    is $dump, $expected, 'dump - Newly created hashes keep order automatically';
};

done_testing;
