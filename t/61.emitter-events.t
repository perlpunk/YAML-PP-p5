#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use YAML::PP;
use YAML::PP::Common;
use YAML::PP::Emitter;
use YAML::PP::Parser;
use YAML::PP::Writer;

my $suite = "$Bin/../test-suite/yaml-test-suite-data";

sub read_events {
    my ($file) = @_;
    open my $fh, '<:encoding(UTF-8)', $file or die $!;
    chomp(my @events = <$fh>);
    return \@events;
}

for my $file (sort glob("$suite/*/test.event"),
    glob("$suite/*/*/test.event"), glob("$Bin/valid/*/test.event")) {
    my $events = read_events($file);
    my @roundtrip = map {
        my $event = YAML::PP::Common::test_suite_to_event($_);
        YAML::PP::Common::event_to_test_suite($event, {flow => 1});
    } @$events;
    (my $title = $file) =~ s{.*?/([^/]+/test.event)$}{$1};
    is_deeply \@roundtrip, $events, "$title: event fixture round trip";
}

for my $case (
    ['CFD4', "$suite/CFD4"],
    ['9MMW', "$suite/9MMW"],
    ['v014', "$Bin/valid/v014"],
    ['v022', "$Bin/valid/v022"],
) {
    my ($id, $dir) = @$case;
    my $expected = read_events("$dir/test.event");
    my $writer = YAML::PP::Writer->new;
    my $emitter = YAML::PP::Emitter->new(writer => $writer);
    for my $line (@$expected) {
        my $event = YAML::PP::Common::test_suite_to_event($line);
        my $name = $event->{name};
        $emitter->$name($event);
    }
    my @got;
    my $parser = YAML::PP::Parser->new(receiver => sub {
        my ($parser, $name, $info) = @_;
        push @got, YAML::PP::Common::event_to_test_suite($info, {flow => 1});
    });
    eval { $parser->parse_string($writer->output) };
    is $@, '', "$id: emitted stream parses";
    is_deeply \@got, $expected, "$id: values, styles, tags and anchors survive";

    if ($id eq 'CFD4' or $id eq 'v022') {
        my $yp = YAML::PP->new;
        my $before = $yp->load_file("$dir/in.yaml");
        my $after = eval { $yp->load_string($writer->output) };
        is $@, '', "$id: emitted data loads";
        is_deeply $after, $before, "$id: loaded values and types survive";
    }
}

done_testing;
