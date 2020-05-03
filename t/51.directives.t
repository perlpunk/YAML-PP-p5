#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin '$Bin';
use YAML::PP;

subtest 'emit-yaml-directive' => sub {
    my $yp = YAML::PP->new(
        version_directive => 1,
        header => 0, # this should be overruled by version_directive
    );
    my $yp_footer = YAML::PP->new(
        version_directive => 1,
        footer => 1,
        yaml_version => '1.1',
    );

    my @docs = (
        { a => 1 },
        [ b => 2 ],
        'c3',
    );

    my $yaml = $yp->dump_string(@docs);
    my $yaml_footer = $yp_footer->dump_string(@docs);

    my $exp = <<'EOM';
%YAML 1.2
---
a: 1
...
%YAML 1.2
---
- b
- 2
...
%YAML 1.2
--- c3
EOM
    my $exp_footer = <<'EOM';
%YAML 1.1
---
a: 1
...
%YAML 1.1
---
- b
- 2
...
%YAML 1.1
--- c3
...
EOM

    is($yaml, $exp, 'Emit version directive');
    is($yaml_footer, $exp_footer, 'Emit version directive (footer=1)');

};

subtest 'yaml-version' => sub {
    my $yaml = <<'EOM';
%YAML 1.2
---
a: 1
---
b: 2
...
%YAML 1.1
---
c: 3
---
b: 4
EOM
    my @events;
    my $receiver = sub {
        my ($p, $name, $event) = @_;
        if ($event->{name} eq 'document_start_event') {
            push @events, $event;
        }
    };
    my $parser = YAML::PP::Parser->new(
        receiver => $receiver,
    );
    my $parser_1_1 = YAML::PP::Parser->new(
        receiver => $receiver,
        default_yaml_version => '1.1',
    );
    $parser->parse_string($yaml);
    is($events[0]->{version_directive}->{major}, '1', 'YAML 1.2 detected');
    is($events[0]->{version_directive}->{minor}, '2', 'YAML 1.2 detected');
    ok(! exists $events[1]->{version_directive}, 'No version directive');
    is($events[2]->{version_directive}->{major}, '1', 'YAML 1.1 detected');
    is($events[2]->{version_directive}->{minor}, '1', 'YAML 1.1 detected');
    @events = ();

    $receiver = sub {
        my ($p, $name, $event) = @_;
        if ($event->{name} eq 'scalar_event') {
            push @events, $event;
        }
    };
    my $parser_1_2 = YAML::PP::Parser->new(
        receiver => $receiver,
    );
    $parser_1_1 = YAML::PP::Parser->new(
        receiver => $receiver,
        default_yaml_version => '1.1',
    );
    $yaml = <<'EOM';
%TAG !a! !long-
---
- !a!foo value
---
- !a!bar value
EOM
    eval {
        $parser_1_2->parse_string($yaml);
    };
    my $err = $@;
    like($err, qr{undefined tag handle}, 'No global tags in YAML 1.2');
    @events = ();

    $parser_1_1->parse_string($yaml);
    is($events[0]->{tag}, '!long-foo', 'First tag ok');
    is($events[1]->{tag}, '!long-bar', 'Second tag ok');

};

subtest 'version-schema' => sub {
    my $yaml = <<'EOM';
what: [ yes, true ]
...
%YAML 1.1
---
bool: yes
...
%YAML 1.2
---
bool: true
string: yes
EOM
    my $out_12_11 = <<'EOM';
%YAML 1.2
---
what:
- yes
- 1
...
%YAML 1.2
---
bool: 1
...
%YAML 1.2
---
bool: 1
string: yes
EOM
    my $out_11_12 = <<'EOM';
%YAML 1.1
---
what:
- 1
- 1
...
%YAML 1.1
---
bool: 1
...
%YAML 1.1
---
bool: 1
string: 'yes'
EOM

    my $out_12 = <<'EOM';
%YAML 1.2
---
what:
- yes
- 1
...
%YAML 1.2
---
bool: yes
...
%YAML 1.2
---
bool: 1
string: yes
EOM
    my $out_11 = <<'EOM';
%YAML 1.1
---
what:
- 1
- 1
...
%YAML 1.1
---
bool: 1
...
%YAML 1.1
---
bool: 1
string: 1
EOM

    my %args= (
        schema => [qw/ + /],
        boolean => 'perl',
        version_directive => 1,
    );

    my $yp = YAML::PP->new(
        %args,
        yaml_version => ['1.2', '1.1'],
    );
    my @docs = $yp->load_string($yaml);
    is($docs[0]->{what}->[0], 'yes', '[1.2,1.1] Doc 1 default string');
    is($docs[0]->{what}->[1], 1,     '[1.2,1.1] Doc 1 YAML 1.2 bool');
    is($docs[1]->{bool},      1,     '[1.2,1.1] Doc 2 YAML 1.1 bool');
    is($docs[2]->{bool},      1,     '[1.2,1.1] Doc 2 YAML 1.2 bool');
    is($docs[2]->{string},    'yes', '[1.2,1.1] Doc 3 YAML 1.2 string');

    my $out = $yp->dump_string(@docs);
    is($out, $out_12_11, '[1.2,1.1] Dump ok');


    $yp = YAML::PP->new(
        %args,
        yaml_version => ['1.1', '1.2'],
    );
    @docs = $yp->load_string($yaml);
    is($docs[0]->{what}->[0], 1,     '[1.1,1.2] Doc 1 default bool');
    is($docs[0]->{what}->[1], 1,     '[1.1,1.2] Doc 1 YAML 1.1 bool');
    is($docs[1]->{bool},      1,     '[1.1,1.2] Doc 2 YAML 1.1 bool');
    is($docs[2]->{bool},      1,     '[1.1,1.2] Doc 2 YAML 1.2 bool');
    is($docs[2]->{string},    'yes', '[1.1,1.2] Doc 3 YAML 1.2 string');

    $out = $yp->dump_string(@docs);
    is($out, $out_11_12, '[1.1,1.2] Dump ok');


    $yp = YAML::PP->new(
        %args,
        yaml_version => ['1.2'],
    );
    @docs = $yp->load_string($yaml);
    is($docs[0]->{what}->[0], 'yes', '[1.2] Doc 1 default string');
    is($docs[0]->{what}->[1], 1,     '[1.2] Doc 1 YAML 1.1 bool');
    is($docs[1]->{bool},      'yes', '[1.2] Doc 2 YAML 1.1 string');
    is($docs[2]->{bool},      1,     '[1.2] Doc 2 YAML 1.2 bool');
    is($docs[2]->{string},    'yes', '[1.2] Doc 3 YAML 1.2 string');

    $out = $yp->dump_string(@docs);
    is($out, $out_12, '[1.2] Dump ok');


    $yp = YAML::PP->new(
        %args,
        yaml_version => ['1.1'],
    );
    @docs = $yp->load_string($yaml);
    is($docs[0]->{what}->[0], 1,     '[1.1] Doc 1 default bool');
    is($docs[0]->{what}->[1], 1,     '[1.1] Doc 1 YAML 1.1 bool');
    is($docs[1]->{bool},      1,     '[1.1] Doc 2 YAML 1.1 bool');
    is($docs[2]->{bool},      1,     '[1.1] Doc 2 YAML 1.2 bool');
    is($docs[2]->{string},    1,     '[1.1] Doc 3 YAML 1.2 bool');

    $out = $yp->dump_string(@docs);
    is($out, $out_11, '[1.1] Dump ok');


};


subtest 'yaml-and-tag' => sub {
    my $yaml = <<'EOM';
%YAML 1.2
%TAG !x! tag:foo-
---
- !x!x
EOM
    my @events;
    my $receiver = sub {
        my ($p, $name, $event) = @_;
        if ($event->{name} eq 'scalar_event') {
            push @events, $event;
        }
    };
    my $parser = YAML::PP::Parser->new(
        receiver => $receiver,
    );
    $parser->parse_string($yaml);
    is($events[0]->{tag}, 'tag:foo-x', '%YAML and %TAG directive');
};

done_testing;
