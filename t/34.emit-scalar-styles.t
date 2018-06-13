#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Data::Dumper;
use YAML::PP::Parser;
use YAML::PP::Emitter;
use YAML::PP::Writer;
use YAML::PP;

my @input = (
    "",
    " ",
    "\n",
    "a",
    "a\n",
    " a",
    "a ",
    " a ",
    "\na\n",
    "\n a\n",
    "\na \n",
    "\n a \n",
);

my $emitter = YAML::PP::Emitter->new();
#my @styles = qw/ : " ' | > /;
my @styles = qw/ : " ' | /;

my $yp = YAML::PP->new( schema => ['Failsafe'] );
for my $style (@styles) {
    subtest "style $style" => sub {
        for my $input (@input) {
            my $writer = YAML::PP::Writer->new;
            $emitter->init;
            $emitter->set_writer($writer);
            local $Data::Dumper::Useqq = 1;
            my $label = Data::Dumper->Dump([$input], ['input']);
            $emitter->stream_start_event;
            $emitter->document_start_event({ implicit => 1 });
            $emitter->sequence_start_event;
            $emitter->scalar_event({ value => $input, style => $style });
            $emitter->sequence_end_event;
            $emitter->document_end_event({ implicit => 1 });
            $emitter->stream_end_event;
            my $yaml = $emitter->writer->output;
            my $data = $yp->load_string($yaml);
            cmp_ok($data->[0], 'eq', $input, "style $style - $label") or do {
                diag ">>$yaml<<\n";
                diag(Data::Dumper->Dump([$data], ['data']));
                diag(Data::Dumper->Dump([$yaml], ['yaml']));
            };
        }
    };
}

done_testing;
