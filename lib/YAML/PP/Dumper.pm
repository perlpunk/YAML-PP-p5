use strict;
use warnings;
package YAML::PP::Dumper;

our $VERSION = '0.000'; # VERSION

use YAML::PP;
use YAML::PP::Representer;

sub new {
    my ($class, %args) = @_;

    my $schema = delete $args{schema} || YAML::PP->default_schema(
        boolean => 'perl',
    );

    my $self = bless {
        representer => YAML::PP::Representer->new(
            schema => $schema,
        ),
    }, $class;
    return $self;
}

sub representer { return $_[0]->{representer} }
sub set_representer { $_[0]->{representer} = $_[1] }
sub schema { return $_[0]->{schema} }

sub dump_string {
    my ($self, @docs) = @_;
    $self->representer->dump_string(@docs);
}

sub dump_file {
    my ($self, $file, @docs) = @_;
    $self->representer->dump_file($file, @docs);
}

1;
