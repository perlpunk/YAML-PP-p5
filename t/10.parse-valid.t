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
    valid => 1,
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
);

@dirs = sort @dirs;

my @skip = qw/
    4ABK 54T7 5C5M 5KJE 6HB6 87E4 8CWC 8UDB 9MMW
    C2DT C4HZ CT4Q D88J DBG4 DFF7 DHP8
    EHF6 FRK4 FUP4
    KZN9 L9U5 LP6E LQZ7 LX3P
    M5DY M7A3 MXS3
    Q88A Q9WF QF4Y
    R4YG SBG9 UDR7 UT92 WZ62 X38W YD5X ZF4X


/;

my $skipped = \@skip;

my @todo = ();

# test all
if ($ENV{TEST_ALL}) {
    @todo = @$skipped;
    @$skipped = ();
}

if (my $dir = $ENV{YAML_TEST_DIR}) {
    @dirs = ($dir);
    @todo = ();
    @$skipped = ();
}
my %skip;
@skip{ @$skipped } = (1) x @$skipped;
my %todo;
@todo{ @todo } = ();

#plan tests => scalar @dirs;

my %results;
my %errors;
@results{qw/ DIFF OK ERROR TODO /} = ([], (0) x 3);
my $skip_count = keys %skip;
for my $item (@dirs) {
    my $dir = dirname $item;
    my $id = basename $item;
    my $skip = delete $skip{ $id };
    my $todo = exists $todo{ $id };
    next if $skip;

    open my $fh, "<", "$dir/$id/in.yaml" or die $!;
    my $yaml = do { local $/; <$fh> };
    close $fh;
    open $fh, "<", "$dir/$id/===" or die $!;
    chomp(my $title = <$fh>);
    close $fh;
#    diag "------------------------------ $id";

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
if (keys %skip) {
    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\%skip], ['skip']);
}
diag "Skipped $skip_count tests";

sub test {
    my ($title, $name, $yaml, $test_events) = @_;
    $yaml = decode_utf8($yaml);
    my $exp_lines = () = $yaml =~ m/[\r\n]/g;
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
        diag "ERROR: $@";
        $results{ERROR}++;
        my $error_type = 'unknown';
        if ($@ =~ m/(Expected .*?) at/) {
            $error_type = "$1";
        }
        elsif ($@ =~ m/(Not Implemented: .*?) at/) {
            $error_type = "$1";
        }
        elsif ($@ =~ m/(Unexpected .*?) at/) {
            $error_type = "$1";
        }
        push @{ $errors{ $error_type } }, $name;
        $error = 1;
    }

    $_ = encode_utf8 $_ for @events;
    if ($error) {
        ok(0, "$name - $title ERROR");
    }
    else {
        $ok = is_deeply(\@events, $test_events, "$name - $title");
    }
    if ($ok) {
        $results{OK}++;
        my $lines = $parser->lexer->line;
        cmp_ok($lines, '==', $exp_lines, "$name - Line count $lines == $exp_lines");
    }
    else {
        push @{ $results{DIFF} }, $name unless $error;
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
my $diff_count = @{ $results{DIFF} };
diag "OK: $results{OK} DIFF: $diff_count ERROR: $results{ERROR} TODO: $results{TODO}";
diag "DIFF: (@{ $results{DIFF} })";
for my $type (sort keys %errors) {
    diag "ERRORS($type): (@{ $errors{ $type } })";
}

done_testing;
