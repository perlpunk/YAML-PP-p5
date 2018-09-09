# ABSTRACT: Load YAML into data with Parser and Constructor
use strict;
use warnings;
package YAML::PP::Loader;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Parser;
use YAML::PP::Constructor;
use YAML::PP::Reader;

sub new {
    my ($class, %args) = @_;

    my $cyclic_refs = delete $args{cyclic_refs} || 'allow';
    my $schema = delete $args{schema} || YAML::PP->default_schema(
        boolean => 'perl',
    );

    my $parser = delete $args{parser} || YAML::PP::Parser->new;
    my $constructor = delete $args{constructor} || YAML::PP::Constructor->new(
        schema => $schema,
        cyclic_refs => $cyclic_refs,
    );
    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }
    my $self = bless {
        parser => $parser,
        constructor => $constructor,
        schema => $schema,
    }, $class;
    $parser->set_receiver($constructor);
    return $self;
}

sub parser { return $_[0]->{parser} }
sub constructor { return $_[0]->{constructor} }
sub schema { return $_[0]->{schema} }

sub load_string {
    my ($self, $yaml) = @_;
    $self->parser->set_reader(YAML::PP::Reader->new( input => $yaml ));
    $self->load();
}

sub load_file {
    my ($self, $file) = @_;
    $self->parser->set_reader(YAML::PP::Reader::File->new( input => $file ));
    $self->load();
}

sub load {
    my ($self) = @_;
    my $parser = $self->parser;
    my $constructor = $self->constructor;

    $constructor->init;
    $parser->parse();

    my $docs = $constructor->docs;
    return wantarray ? @$docs : $docs->[0];
}


1;
