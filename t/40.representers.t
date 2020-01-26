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
            $node->{ data } = \%{ $node->{ value } };
            return 1;
        }
    );

    my $data = {
        o1 => (bless {}, 'Class1'),
        o2 => (bless {}, 'Class2'),
    };

    my $yaml = $parser->dump_string($data);
    like($yaml, qr/o1: !Class1/, 'o1s\' class has a representer that converts it to a tag');
    like($yaml, qr/o2: \{\}/, 'o2s\' class doesn\'t have a representer. It gets converted to an empty hash');
}

{
    my $parser = YAML::PP->new;
    $parser->schema->add_representer(
        class_matches => 1,
        code => sub {
            my ($representer, $node) = @_;
            if ($node->{ value }->isa('Class1')) {
                $node->{ tag } = '!Class1';
                $node->{ data } = \%{ $node->{ value } };
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
            $node->{ data } = \%{ $node->{ value } };
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

# declare some packages inline for the next test
package BaseClass;

package Class4;
    our @ISA = ('BaseClass');

# return to the tests package
package main;

{
    my $parser = YAML::PP->new;
    $parser->schema->add_representer(
        class_isa => 'Class3',
        code => sub {
            my ($representer, $node) = @_;
            $node->{ tag } = '!Class3';
            $node->{ data } = \%{ $node->{ value } };
            return 1;
        }
    );
    $parser->schema->add_representer(
        class_isa => 'BaseClass',
        code => sub {
            my ($representer, $node) = @_;
            $node->{ tag } = '!BaseClass';
            $node->{ data } = \%{ $node->{ value } };
            return 1;
        }
    );


    my $data = {
        o3 => (bless {}, 'Class3'),
        o4 => (bless {}, 'Class4'),
      };

    my $yaml = $parser->dump_string($data);
    like($yaml, qr/o3: !Class3/, 'Class3 gets caught by its class name');
    like($yaml, qr/o4: !BaseClass/, 'Class4 gets caught because its inherited from BaseClass');
}

done_testing; 
