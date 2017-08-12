#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use YAML::PP::Test;
use Data::Dumper;
use YAML::PP::Parser;
use YAML::PP::Emitter;
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

# skip tests that parser can't parse
my @skip = qw/
    4ABK 54T7 5C5M 5KJE 5TRB 6HB6 87E4 8UDB 9MMW
    C2DT C4HZ CT4Q D88J DBG4 DFF7 DHP8
    EHF6 FRK4 FUP4
    KZN9 L9U5 LP6E LQZ7
    M5DY M7A3 MXS3 N782
    Q88A Q9WF QF4Y
    R4YG SBG9 UDR7 UT92 WZ62 X38W YD5X ZF4X

    v018
/;

# emitter
push @skip, qw/
/;
# quoting
push @skip, qw/
82AN
9YRD
HS5T
T4YY
/;
# tags
push @skip, qw/
5TYM
6CK3
v014
/;
# block scalar
push @skip, qw/
4QFQ
6VJK
7T8X

P2AD
v016
/;
# test
push @skip, qw/
3MYT
565N
6FWR
6SLA
6WPF
6ZKB
9DXL
9TFX
B3HG
EX5H
EXG3
G4RS
H2RW
JDH8
KSS4
MJS9
NHX8
PRH3
S3PD
v009
v011


K858

/;
# nested seq
push @skip, qw/
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
@skip{ @$skipped } = ();
my %todo;
@todo{ @todo } = ();

#plan tests => scalar @dirs;

my %results;
my %errors;
@results{qw/ DIFF OK ERROR TODO /} = ([], (0) x 3);
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
    #diag "------------------------------ $id";

    my $out_yaml_file = "$dir/$id/emit.yaml";
    unless (-f $out_yaml_file) {
        $out_yaml_file = "$dir/$id/out.yaml";
    }
    unless (-f $out_yaml_file) {
        $out_yaml_file = "$dir/$id/in.yaml";
    }
    open $fh, "<", $out_yaml_file or die $!;
    my $out_yaml = do { local $/; <$fh> };
    close $fh;

    open $fh, "<", "$dir/$id/test.event" or die $!;
    chomp(my @test_events = <$fh>);
    close $fh;

    if ($skip) {
        SKIP: {
            skip "SKIP $id", 1 if $skip;
            test($title, $id, $yaml, $out_yaml);
        }
    }
    elsif ($todo) {
        TODO: {
            local $TODO = $todo;
            test($title, $id, $yaml, $out_yaml);
        }
    }
    else {
        test($title, $id, $yaml, $out_yaml, \@test_events);
    }

}
my $skip_count = @$skipped;
diag "Skipped $skip_count tests";

sub test {
    my ($title, $name, $yaml, $exp_yaml, $test_events) = @_;
#    warn __PACKAGE__.':'.__LINE__.": ================================ $name\n";
#    @$test_events = grep { m/DOC|STR/ } @$test_events;
    my $ok = 0;
    my $error = 0;
    my @events;
    my $emitter = YAML::PP::Emitter->new;
    my $parser = YAML::PP::Parser->new(
        receiver => sub {
            my ($self, @args) = @_;
            push @events, [@args];
        },
    );
    eval {
        $parser->parse($yaml);
    };
    if ($@) {
        diag "ERROR: $@";
        $results{ERROR}++;
        my $error_type = 'unknown';
        #if ($@ =~ m/(Expected .*?) at/) {
        #    $error_type = "$1";
        #}
        #elsif ($@ =~ m/(Not Implemented: .*?) at/) {
        #    $error_type = "$1";
        #}
        #elsif ($@ =~ m/(Unexpected .*?) at/) {
        #    $error_type = "$1";
        #}
        push @{ $errors{ $error_type } }, $name;
        $error = 1;
    }

    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@docs], ['docs']);
    my $out_yaml;
    if ($error) {
        ok(0, "$name - $title Parse ERROR");
    }
    else {
        my $yaml = emit_events($emitter, \@events);
        $out_yaml = $$yaml;
    #    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
        $ok = cmp_ok($out_yaml, 'eq', $exp_yaml, "$name - $title - Emit events");
    }
    if ($ok) {
        $results{OK}++;
    }
    else {
        push @{ $results{DIFF} }, $name unless $error;
        if ($TODO) {
            $results{TODO}++;
        }
        if (not $TODO or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$yaml" unless $TODO;
#            diag "EVENTS:\n" . join '', map { "$_\n" } @$test_events;
#            diag "GOT EVENTS:\n" . join '', map { "$_\n" } @events;
        }
    }
}
my $diff_count = @{ $results{DIFF} };
diag "OK: $results{OK} DIFF: $diff_count ERROR: $results{ERROR} TODO: $results{TODO}";
diag "DIFF: (@{ $results{DIFF} })";
for my $type (sort keys %errors) {
    diag "ERRORS($type): (@{ $errors{ $type } })";
}

sub emit_events {
    my ($emitter, $events) = @_;
    $emitter->init;
    for my $event (@$events) {
        my ($type, $info) = @$event;
#        warn __PACKAGE__.':'.__LINE__.": $emitter->$type()\n";
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$type], ['type']);
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$info], ['info']);
        $emitter->$type($info);
    }
    my $yaml = $emitter->yaml;
    return $yaml;
}

done_testing;
