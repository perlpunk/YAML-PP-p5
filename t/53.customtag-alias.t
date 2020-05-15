#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin '$Bin';
use YAML::PP;


subtest 'join-tag' => sub {
    my $yp = YAML::PP->new;
    $yp->schema->add_sequence_resolver(
        tag => '!join',
        on_create => sub { return '' },
        on_data => sub {
            my ($constructor, $data, $list) = @_;
            my $join = shift @$list;
            $$data .= join $join, @$list;
        },
    );
    my $yaml = <<'EOM';
---
name: &name YAML
string: &what !join [ ' ', *name, Ain't, Markup, Language ]
alias: *what
EOM
    my $string = "YAML Ain't Markup Language";
    my $expected = {
        name => 'YAML',
        string => $string,
        alias => $string,
    };
    my ($data) = $yp->load_string($yaml);
    is_deeply($data, $expected, 'Loaded data as expected');
};

subtest 'inherit-tag' => sub {
    my $yp = YAML::PP->new;
    $yp->schema->add_mapping_resolver(
        tag => '!inherit',
#        on_create => sub { return '' },
        on_data => sub {
            my ($constructor, $data, $list) = @_;
            for my $item (@$list) {
                %$$data = (%$$data, %$item);
            }
        },
    );
    my $yaml = <<'EOM';
---
parent: &parent
  a: A
  b: B
child: &child !inherit
  *parent :
      a: new A
      c: C
twin: *child
EOM
    my $string = "YAML Ain't Markup Language";
    my $child = {
        a => 'new A',
        b => 'B',
        c => 'C',
    };
    my $expected = {
        parent => {
            a => 'A',
            b => 'B',
        },
        child => $child,
        twin => $child,
    };
    my ($data) = $yp->load_string($yaml);
    is_deeply($data, $expected, 'Loaded data as expected');
};

done_testing;
