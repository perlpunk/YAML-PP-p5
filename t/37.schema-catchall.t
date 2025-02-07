#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use Scalar::Util ();
use YAML::PP;

my $yp = YAML::PP->new();
my $catch = YAML::PP->new(
    schema => [qw/ + Catchall /],
);

my $yaml = <<'EOM';
- !foo null
EOM

pass "dummy";
done_testing;
__END__
my $data = eval { $yp->load_string($yaml) };
my $err = $@;
like $err, qr{Unknown tag '!foo'. Use schema 'Catchall'}, "unknoen tags are fatal by default";

$data = $catch->load_string($yaml);
is $data->[0], 'null', "Catchall loads unknown tag as string";

$yaml = "! 023";

$data = $yp->load_string($yaml);
is $data, '023', "Tag '!' still works without catchall";

$data = $catch->load_string($yaml);
is $data, '023', "Tag '!' still works with catchall";

$yaml = <<'EOM';
!foo
- a
EOM
$data = eval { $yp->load_string($yaml) };
$err = $@;
like $err, qr{Unknown tag '!foo'. Use schema 'Catchall'}, "unknoen tags are fatal by default";

$data = $catch->load_string($yaml);
is $data->[0], 'a', "Catchall loads unknown tag on a sequence";

$yaml = <<'EOM';
!foo
a: b
EOM
$data = eval { $yp->load_string($yaml) };
$err = $@;
like $err, qr{Unknown tag '!foo'. Use schema 'Catchall'}, "unknoen tags are fatal by default";

$data = $catch->load_string($yaml);
is $data->{a}, 'b', "Catchall loads unknown tag on a mapping";

done_testing;
