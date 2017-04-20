# ABSTRACT: YAML Parser and Loader
use strict;
use warnings;
package YAML::PP;

our $VERSION = '0.000'; # VERSION

sub new {
    my ($class, %args) = @_;
    my $self = bless {
    }, $class;
    return $self;
}

sub loader { return $_[0]->{loader} }

sub Load {
    require YAML::PP::Loader;
    my ($self, $yaml) = @_;
    $self->{loader} = YAML::PP::Loader->new;
    return $self->loader->Load($yaml);
}

1;
