#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAML::PP;

my $yp = YAML::PP->new(
    max_depth => 5,
);

my @errors = (
    '[[[[[[]]]]]]',
    '[{[{[{}]}]}]',
    '{{{{{{}}}}}}',
    '{[{[{[]}]}]}',
);
for my $yaml (@errors) {
    eval {
        $yp->load_string($yaml);
    };
    like $@, qr{Depth of nesting exceeds maximum 5}, "'$yaml' expected error message";
}

my $yaml = '[[[[[]]]]]';
eval {
    $yp->load_string($yaml);
};
is $@, '', 'no error message';

done_testing;
