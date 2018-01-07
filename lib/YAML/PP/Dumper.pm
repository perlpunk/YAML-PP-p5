use strict;
use warnings;
package YAML::PP::Dumper;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Representer;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        representer => YAML::PP::Representer->new(
        ),
    }, $class;
    return $self;
}

sub representer { return $_[0]->{representer} }
sub set_representer { $_[0]->{representer} = $_[1] }

sub dump_string {
    my ($self, @docs) = @_;
    $self->representer->dump_string(@docs);
}

sub dump_file {
    my ($self, $file, @docs) = @_;
    $self->representer->dump_file($file, @docs);
}

1;
