#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use YAML::PP;

{
  my $parser = YAML::PP->new;
  $parser->schema->add_representer(
    class_equals => 'Class1',
    code => sub {
      my ($representer, $node) = @_;
      $node->{ tag } = '!Class1',
      return 1;
    }
  );

  my $data = {
    o1 => (bless {}, 'Class1'),
    o2 => (bless {}, 'Class2'),
  };

  my $yaml = $parser->dump_string($data);
  like($yaml, qr/o1: !Class1/, 'o1s\' class has a representer that converts it to a tag');
  like($yaml, qr/o2:\n  \{\}/, 'o2s\' class doesn\'t have a representer. It gets converted to an empty hash');
}

{
  my $parser = YAML::PP->new;
  $parser->schema->add_representer(
    class_matches => 1,
    code => sub {
      my ($representer, $node) = @_;
      if ($node->{ value }->isa('Class1')) {
        $node->{ tag } = '!Class1';
        return 1;
      }
      return 0;
    }
  );
  $parser->schema->add_representer(
    class_matches => 1,
    code => sub {
      my ($representer, $node) = @_;
      $node->{ tag } = '!Class2';
      return 1;
    }
  );


  my $data = {
    o1 => (bless {}, 'Class1'),
    o2 => (bless {}, 'Class2'),
  };

  my $yaml = $parser->dump_string($data);
  # o1 serializes to Class1 because the first catchall says it's done
  like($yaml, qr/o1: !Class1/, 'o1s\' gets caught only by the first class_matches, since it sets work as done');
  like($yaml, qr/o2: !Class2/, 'o2s\' gets caught by the second class_matches');
}

done_testing; 
