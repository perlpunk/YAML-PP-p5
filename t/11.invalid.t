#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Parser;
use YAML::XS ();
use Encode;
use File::Basename qw/ dirname basename /;

$|++;

my $extradir = "$Bin/invalid";
opendir my $dh, $extradir or die $!;
my @dirs = map { "$extradir/$_" } grep { m/^[A-Z0-9]{3,4}\z/ } readdir $dh;
closedir $dh;

@dirs = sort @dirs;

my $skip_info = YAML::XS::LoadFile("t/skip_invalid.yaml");
my $skipped = $skip_info->{skip} || [];

my $anchors = $skip_info->{anchors} || [];

my @todo = ();
push @$skipped,
    @$anchors;

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
my $skip_count = @$skipped;
diag "Skipped $skip_count tests";

sub test {
    my ($title, $name, $yaml, $test_events) = @_;
#    @$test_events = grep { m/DOC|STR/ } @$test_events;
    my @events;
    my $parser = YAML::PP::Parser->new(
        receiver => sub {
            my ($self, $event, $content) = @_;
            push @events, defined $content ? "$event $content" : $event;
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
        if ($@ =~ m/Expected/) {
            $error_type = 'Expected';
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
        $ok = is_deeply(\@events, $test_events, "$name - $title");
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
