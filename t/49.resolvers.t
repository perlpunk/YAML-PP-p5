#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use YAML::PP;

my $document = <<EOF;
---
Scalar: !ScalarTag MyValue
Sequence: !SequenceTag [ value1, value2 ]
Mapping: !MappingTag { "Key" : Value }
EOF

{
  note "No resolvers: default behaviour";
  my $parser = YAML::PP->new;

  my $struct = $parser->load_string($document);

  is_deeply($struct->{ Scalar }, 'MyValue');
  is_deeply($struct->{ Sequence }, [ 'value1', 'value2' ]);
  is_deeply($struct->{ Mapping }, { 'Key', 'Value' }); 
}

{
  note "With specific resolvers";
  my $parser = YAML::PP->new;

  $parser->schema->add_resolver(
    tag => "!ScalarTag",
    implicit => 0,
    match => [ regex => qr{^(.*)$} => sub {
      my ($self, $value) = @_;
      return { "ScalarTag" => $value->{ value } }
    } ]
  );
  $parser->schema->add_sequence_resolver(
    tag => "!SequenceTag",
    on_create => sub {
      my ($constructor, $event) = @_;
      return { "SequenceTag" => [] };
    },
    on_data => sub {
      my ($constructor, $ref, $items) = @_;
      push @{ $$ref->{"SequenceTag"} }, @$items;
    }
  );
  $parser->schema->add_mapping_resolver(
    tag => "!MappingTag",
    on_create => sub {
      my ($constructor, $event) = @_;
      return { "MappingTag" => { } };
    },
    on_data => sub {
      my ($constructor, $ref, $items) = @_;
      $$ref->{"MappingTag"} = { @$items };
    }
  );

  my $struct = $parser->load_string($document);

  is_deeply($struct->{ Scalar }, { 'ScalarTag' => 'MyValue' });
  is_deeply($struct->{ Sequence }, { 'SequenceTag' => [ 'value1', 'value2' ] });
  is_deeply($struct->{ Mapping }, { 'MappingTag' => { 'Key', 'Value' } }); 
}

{
  note "With regexp resolvers";
  my $parser = YAML::PP->new;

  $parser->schema->add_resolver(
    tag => qr/^!.*/,
    implicit => 0,
    match => [ regex => qr{^(.*)$} => sub {
      my ($self, $value) = @_;
      return { $value->{ tag } => $value->{ value } }
    } ]
  );
  $parser->schema->add_sequence_resolver(
    tag => qr/^!.*/,
    on_create => sub {
      my ($constructor, $event) = @_;
      return { $event->{ tag } => [] };
    },
    on_data => sub {
      my ($constructor, $ref, $items) = @_;
      my $key = [ keys %{ $$ref } ]->[0];
      push @{ $$ref->{ $key } }, @$items;
    }
  );
  $parser->schema->add_mapping_resolver(
    tag => qr/^!.*/,
    on_create => sub {
      my ($constructor, $event) = @_;
      return { $event->{ tag } => { } };
    },
    on_data => sub {
      my ($constructor, $ref, $items) = @_;
      my $key = [ keys %{ $$ref } ]->[0];
      $$ref->{ $key } = { @$items };
    }
  );

  my $struct = $parser->load_string($document);

  is_deeply($struct->{ Scalar }, { '!ScalarTag' => 'MyValue' });
  is_deeply($struct->{ Sequence }, { '!SequenceTag' => [ 'value1', 'value2' ] });
  is_deeply($struct->{ Mapping }, { '!MappingTag' => { 'Key', 'Value' } }); 
}


done_testing; 
