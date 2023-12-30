#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use YAML::PP;
use Encode;


my $utf8 = <<'EOM';
[bär]
EOM

my $perl = decode_utf8 $utf8;

my $bear_utf8 = "bär";
my $bear_perl = decode_utf8 $bear_utf8;

subtest 'YAML::PP' => sub {
    my $p_utf8 = YAML::PP->new(
        header => 0,
        utf8 => 1,
    );
    my $p_perl = YAML::PP->new(
        header => 0,
        utf8 => 0,
    );
    my $p_default = YAML::PP->new(header => 0);


    subtest 'load unicode' => sub {
        my $data = $p_utf8->load_string($utf8);
        is $data->[0], $bear_perl, 'load utf8';

        eval {
            $data = $p_utf8->load_string($perl);
        };
        my $err = $@;
        like $err, qr{does not map to Unicode}, 'load decoded with utf8 loader fails';

        $data = $p_perl->load_string($perl);
        is $data->[0], $bear_perl, 'load decoded with perl loader';

        $data = $p_perl->load_string($utf8);
        is $data->[0], $bear_utf8, 'load utf8 with perl loader';

        $data = $p_default->load_string($perl);
        is $data->[0], $bear_perl, 'load decoded with default loader';

        $data = $p_default->load_string($utf8);
        is $data->[0], $bear_utf8, 'load utf8 with default loader';
    };

    subtest 'dump unicode' => sub {
        my $yaml = $p_utf8->dump_string([$bear_perl]);
        $yaml =~ s/^- //; chomp $yaml;
        is $yaml, $bear_utf8, 'dump perl data with utf8 dumper -> utf8';

        $yaml = $p_utf8->dump_string([$bear_utf8]);
        $yaml =~ s/^- //; chomp $yaml;
        is $yaml, encode_utf8($bear_utf8), 'dump utf8 data with utf8 dumper -> rubbish';

        $yaml = $p_perl->dump_string([$bear_perl]);
        $yaml =~ s/^- //; chomp $yaml;
        is $yaml, $bear_perl, 'dump perl data with perl dumper -> perl';

        $yaml = $p_perl->dump_string([$bear_utf8]);
        $yaml =~ s/^- //; chomp $yaml;
        $yaml, $bear_utf8, 'dump utf8 data with perl dumper -> utf8';
    };
};

my $pplib = eval "use YAML::PP::LibYAML; 1";

subtest 'YAML::PP::LibYAML' => sub {
    plan(skip_all => 'YAML::PP::LibYAML not installed') unless $pplib;
    diag "YAML::PP::LibYAML " . YAML::PP::LibYAML->VERSION;
    my $p_utf8 = YAML::PP::LibYAML->new(
        header => 0,
        utf8 => 1,
    );
    my $p_perl = YAML::PP::LibYAML->new(
        header => 0,
        utf8 => 0,
    );
    my $p_default = YAML::PP::LibYAML->new(header => 0);
    subtest 'load unicode' => sub {
        my $data = $p_utf8->load_string($utf8);
        is $data->[0], $bear_perl, 'load utf8';

        $data = $p_utf8->load_string($perl);
        is $data->[0], $bear_perl, 'load decoded with utf8 loader passes (libyaml XS binding can work with both)';

        $data = $p_perl->load_string($perl);
        is $data->[0], $bear_perl, 'load decoded with perl loader';

        $data = $p_perl->load_string($utf8);
        is $data->[0], $bear_perl, 'load utf8 with perl loader';

        $data = $p_default->load_string($perl);
        is $data->[0], $bear_perl, 'load decoded with default loader';

        $data = $p_default->load_string($utf8);
        is $data->[0], $bear_perl, 'load utf8 with default loader';
    };

    my $bear_perl = decode_utf8 $bear_utf8;
    subtest 'dump unicode' => sub {
        diag "############################";
        my $yaml = $p_utf8->dump_string([$bear_perl]);
        $yaml =~ s/^- //; chomp $yaml;
        is $yaml, $bear_utf8, 'dump perl data with utf8 dumper -> utf8';

        $yaml = $p_utf8->dump_string([$bear_utf8]);
        $yaml =~ s/^- //; chomp $yaml;
        is $yaml, encode_utf8($bear_utf8), 'dump utf8 data with utf8 dumper -> rubbish';

        $yaml = $p_perl->dump_string([$bear_perl]);
        $yaml =~ s/^- //; chomp $yaml;
        is $yaml, $bear_perl, 'dump perl data with perl dumper -> perl';

        $yaml = $p_perl->dump_string([$bear_utf8]);
        $yaml =~ s/^- //; chomp $yaml;
        $yaml, $bear_utf8, 'dump utf8 data with perl dumper -> utf8';
    };
};


done_testing;
