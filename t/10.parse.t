#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Parser;
use YAML::XS ();

$|++;

my $datadir = "$Bin/../yaml-test-suite";
opendir my $dh, $datadir or die $!;
my @dirs = grep { m/^[A-Z0-9]{4}\z/ } readdir $dh;
closedir $dh;

@dirs = sort @dirs;

my $skip_info = YAML::XS::LoadFile("t/skip.yaml");
my $check = $skip_info->{check};

my $skipped = $skip_info->{skip};

my $multiline = $skip_info->{multiline} || [];
my $quoted = $skip_info->{quoted} || [];
my $flow = $skip_info->{flow} || [];
my $seq = $skip_info->{seq} || [];
my $sets = $skip_info->{sets} || [];
my $tags = $skip_info->{tags} || [];
my $misc = $skip_info->{misc} || [];
my $anchors = $skip_info->{anchors} || [];
my $keymap = $skip_info->{keymap} || [];

my @todo = ();
push @$skipped,
    @$check,
    @$anchors,
    @$keymap,
    @$tags,
    @$misc,
    @$sets,
    @$seq,
    @$flow,
    @$quoted,
    @$multiline;

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

for my $dir (@dirs) {
    my $skip = exists $skip{ $dir };
    my $todo = exists $todo{ $dir };
    next if $skip;

    open my $fh, "<", "$datadir/$dir/in.yaml" or die $!;
    my $yaml = do { local $/; <$fh> };
    close $fh;
    open $fh, "<", "$datadir/$dir/===" or die $!;
    chomp(my $title = <$fh>);
    close $fh;
#    diag "------------------------------ $dir";

    open $fh, "<", "$datadir/$dir/test.event" or die $!;
    chomp(my @test_events = <$fh>);
    close $fh;

    if ($skip) {
        SKIP: {
            skip "SKIP $dir", 1 if $skip;
            test($title, $dir, $yaml, \@test_events);
        }
    }
    elsif ($todo) {
        TODO: {
            local $TODO = $todo;
            test($title, $dir, $yaml, \@test_events);
        }
    }
    else {
        test($title, $dir, $yaml, \@test_events);
    }

}
my $skip_count = @$skipped;
diag "Skipped $skip_count tests";

sub test {
    my ($title, $name, $yaml, $test_events) = @_;
#    @$test_events = grep { m/DOC|STR/ } @$test_events;
    my @events;
    my $parser = YAML::PP::Parser->new(
        cb => sub {
            my ($self, $event, $content) = @_;
            push @events, defined $content ? "$event $content" : $event;
        },
    );
    eval {
        $parser->parse($yaml);
    };
    if ($@) {
        diag "ERROR: $@";
    }
    my @squashed;
    for (my $i = 0; $i < @events; $i++) {
        my $event = $events[ $i ];
        if ($event =~ m/^=VAL /) {
            next;
        }

        push @squashed, $event;
    }

#    @events = @squashed;
    my $ok = is_deeply(\@events, $test_events, "$name - $title");
    if (not $ok and not $TODO or $ENV{YAML_PP_TRACE}) {
        diag "YAML:\n$yaml" unless $TODO;
        diag "EVENTS:\n" . join '', map { "$_\n" } @$test_events;
        diag "GOT EVENTS:\n" . join '', map { "$_\n" } @events;
    }
}

done_testing;
