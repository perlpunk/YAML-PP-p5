#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use YAML::PP::Test;
use Data::Dumper;
use YAML::PP::Parser;
use YAML::PP::Loader;
use Encode;
use File::Basename qw/ dirname basename /;

$|++;

my $yts = "$Bin/../yaml-test-suite";
my @dirs = YAML::PP::Test->get_tests(
    valid => 0,
    test_suite_dir => "$yts",
    dir => "$Bin/invalid",
);

@dirs = sort @dirs;

my @skip = qw/
    4H7K 6JTT 9MAG
    CML9 C2SP CTN5
    G9HC
    N782

    SY6V

    9C9N

/;

my @todo = ();

# test all
if ($ENV{TEST_ALL}) {
    @todo = @skip;
    @skip = ();
}

if (my $dir = $ENV{YAML_TEST_DIR}) {
    @dirs = ($dir);
    @todo = ();
    @skip = ();
}
my %skip;
@skip{ @skip } = ();
my %todo;
@todo{ @todo } = ();

# in case of error events might not be exactly matching
my %skip_events = (
    Q4CL => 1,
    JY7Z => 1,
    '3HFZ' => 1,
    X4QW => 1,
    SU5Z => 1,
    W9L4 => 1,
    ZL4Z => 1,
    '9KBC' => 1,
);

unless (@dirs) {
    ok(1);
    done_testing;
    exit;
}
#plan tests => scalar @dirs;

my %results;
my %errors;
@results{qw/ OK DIFF ERROR TODO /} = (0) x 4;
for my $item (@dirs) {
    my $dir = dirname $item;
    my $id = basename $item;
    my $skip = exists $skip{ $id };
    my $todo = exists $todo{ $id };
    next if $skip;

    open my $fh, "<", "$dir/$id/in.yaml" or die $!;
    my $yaml = do { local $/; <$fh> };
    close $fh;
    open $fh, "<", "$dir/$id/===" or die $!;
    chomp(my $title = <$fh>);
    close $fh;

    open $fh, "<", "$dir/$id/test.event" or die $!;
    chomp(my @test_events = <$fh>);
    close $fh;

    if ($skip) {
        SKIP: {
            skip "SKIP $id", 1 if $skip;
            test($title, $id, $yaml, \@test_events);
        }
    }
    elsif ($todo) {
        TODO: {
            local $TODO = $todo;
            test($title, $id, $yaml, \@test_events);
        }
    }
    else {
        test($title, $id, $yaml, \@test_events);
    }

}
my $skip_count = @skip;
diag "Skipped $skip_count tests";

sub test {
    my ($title, $name, $yaml, $test_events) = @_;
    $yaml = decode_utf8($yaml);
    my @events;
    my $parser = YAML::PP::Parser->new(
        receiver => sub {
            my ($self, @args) = @_;
            push @events, YAML::PP::Parser->event_to_test_suite(\@args);
        },
    );
    my $ok = 0;
    my $error = 0;
    eval {
        $parser->parse($yaml);
    };
    if ($@) {
        diag "ERROR: $@" if $ENV{YAML_PP_TRACE};
        $results{ERROR}++;
        my $error_type = 'unknown';
        if ($@ =~ m/( Expected .*?)/) {
            $error_type = "$1";
        }
        elsif ($@ =~ m/( Not Implemented: .*?)/) {
            $error_type = "$1";
        }
        push @{ $errors{ $error_type } }, $name;
        $error = 1;
    }

    $_ = encode_utf8 $_ for @events;
    if (not $error) {
        $results{OK}++;
        ok(0, "$name - $title - should be invalid");
    }
    else {
        if ($skip_events{ $name }) {
            $ok = ok(1, "$name - $title");
        }
        else {
            $ok = is_deeply(\@events, $test_events, "$name - $title");
        }
    }
    if ($ok) {
    }
    else {
        $results{DIFF}++ if $error;
        if ($TODO) {
            $results{TODO}++;
        }
        if (not $TODO or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$yaml" unless $TODO;
            diag "EVENTS:\n" . join '', map { "$_\n" } @$test_events;
            diag "GOT EVENTS:\n" . join '', map { "$_\n" } @events;
        }
    }
}
diag "OK: $results{OK} DIFF: $results{DIFF} ERROR: $results{ERROR} TODO: $results{TODO}";
for my $type (sort keys %errors) {
    diag "ERRORS($type): (@{ $errors{ $type } })";
}

done_testing;
