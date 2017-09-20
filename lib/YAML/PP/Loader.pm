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

    my $bool = delete $args{boolean} // 'perl';
    my $parser = delete $args{parser} || YAML::PP::Parser->new;
    my $constructor = delete $args{constructor} || YAML::PP::Constructor->new(
        boolean => $bool,
    );
    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }
    my $self = bless {
        parser => $parser,
        constructor => $constructor,
    }, $class;
    $parser->set_receiver($constructor);
    return $self;
}

sub parser { return $_[0]->{parser} }
sub constructor { return $_[0]->{constructor} }

sub load_string {
    my ($self, $yaml) = @_;
    $self->parser->lexer->set_reader(YAML::PP::Reader->new);
    $self->load($yaml);
}

sub load_file {
    my ($self, $file) = @_;
    $self->parser->lexer->set_reader(YAML::PP::Reader::File->new);
    $self->load($file);
}

sub load {
    my ($self, $yaml) = @_;
    my $parser = $self->parser;
    my $constructor = $self->constructor;

    $constructor->init;
    $parser->parse($yaml);

    my $docs = $constructor->docs;
    return wantarray ? @$docs : $docs->[0];
}


1;
