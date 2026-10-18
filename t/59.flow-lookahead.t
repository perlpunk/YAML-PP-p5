#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAML::PP::Parser;

{
    package Local::FlowParser;
    our @ISA = ('YAML::PP::Parser');

    sub emit_event {
        my ($self, @args) = @_;
        $self->{emissions}++;
        $self->SUPER::emit_event(@args);
        my $queued = @{ $self->{flow_events} };
        $self->{max_queued} = $queued
            if $queued > ($self->{max_queued} || 0);
    }
}

my @events;
my $parser = Local::FlowParser->new(receiver => sub {
    my ($parser, $event) = @_;
    push @events, $event;
});

# Check buffering bounds directly, without depending on wall clock timings.
for my $size (256, 1024, 4096) {
    for my $kind (qw(deep multiline wide)) {
        my $yaml = $kind eq 'deep' ? '[' x $size . '0' . ']' x $size
            : $kind eq 'multiline'
                ? "[\n" x $size . "0\n" . "]\n" x $size
            : '[' . join(',', ('[a]: b') x $size) . ']';
        @events = ();
        $parser->{emissions} = $parser->{max_queued} = 0;
        $parser->parse_string($yaml);
        my @expected = ('stream_start_event', 'document_start_event');
        if ($kind eq 'wide') {
            push @expected, 'sequence_start_event';
            push @expected, (
                'mapping_start_event', 'sequence_start_event',
                'scalar_event', 'sequence_end_event', 'scalar_event',
                'mapping_end_event',
            ) x $size;
            push @expected, 'sequence_end_event';
        }
        else {
            push @expected, ('sequence_start_event') x $size;
            push @expected, 'scalar_event';
            push @expected, ('sequence_end_event') x $size;
        }
        push @expected, 'document_end_event', 'stream_end_event';
        is_deeply \@events, \@expected, "$kind $size: event order";
        is $parser->{emissions}, scalar @events,
            "$kind $size: each event is produced once";
        cmp_ok $parser->{max_queued}, '<=', 4096,
            "$kind $size: bounded lookahead queue";
    }
}

@events = ();
$parser->parse_string('[' x 200 . '0' . ']: v' x 200);
is_deeply \@events, [
    'stream_start_event', 'document_start_event',
    ('mapping_start_event', 'sequence_start_event') x 200,
    'scalar_event',
    ('sequence_end_event', 'scalar_event', 'mapping_end_event') x 200,
    'document_end_event', 'stream_end_event',
], 'Nested collection keys preserve event order';

for my $case (
    ['[' . 'a' x 1022 . ']: value', '', '1024 character key'],
    ['[' . 'a' x 1023 . ']: value', 'too long', '1025 character key'],
    ["[a,\n b]: value", 'one line', 'Multiline collection key'],
    ["[\"a\n b\"]: value", 'one line', 'Multiline quoted key item'],
) {
    my ($yaml, $error, $title) = @$case;
    eval { $parser->parse_string($yaml) };
    if ($error) {
        like $@, qr/\Q$error\E/, $title;
    }
    else {
        is $@, '', $title;
    }
}

for my $yaml ('[[a], b]', '[' x 2048 . 'a' . ']' x 2048) {
    my $calls = 0;
    $parser->set_receiver(sub {
        $calls++;
        die "Receiver failure\n" if $calls == 4;
    });
    eval { $parser->parse_string($yaml) };
    like $@, qr/Receiver failure/, 'Receiver error is propagated';
    is $calls, 4, 'No further events after receiver failure';
}

@events = ();
$parser->set_receiver(sub {
    my ($parser, $event) = @_;
    push @events, $event;
});
$parser->parse_string('[a]: b');
is_deeply \@events, [
    'stream_start_event', 'document_start_event', 'mapping_start_event',
    'sequence_start_event', 'scalar_event', 'sequence_end_event',
    'scalar_event', 'mapping_end_event', 'document_end_event',
    'stream_end_event',
], 'Parser can be reused after errors';

done_testing;
