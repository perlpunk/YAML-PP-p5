use strict;
use warnings;
package YAML::PP::Dumper;

our $VERSION = '0.000'; # VERSION

use Scalar::Util qw/ blessed /;
use YAML::PP;
use YAML::PP::Representer;

sub new {
    my ($class, %args) = @_;

    my $schema = delete $args{schema} || YAML::PP->default_schema(
        boolean => 'perl',
    );

    my $emitter = delete $args{emitter} || YAML::PP::Emitter->new;
    unless (blessed($emitter)) {
        $emitter = YAML::PP::Emitter->new(
            %$emitter
        );
    }
    my $self = bless {
        representer => YAML::PP::Representer->new(
            schema => $schema,
            emitter => $emitter,
        ),
    }, $class;
    return $self;
}

sub representer { return $_[0]->{representer} }
sub set_representer { $_[0]->{representer} = $_[1] }
sub schema { return $_[0]->{schema} }

sub dump {
    my ($self, @docs) = @_;
    $self->representer->emitter->init;
    $self->representer->dump(@docs);
    my $output = $self->representer->emitter->writer->output;
    $self->representer->emitter->finish;
    return $output;
}

sub dump_string {
    my ($self, @docs) = @_;
    my $writer = YAML::PP::Writer->new;
    $self->representer->emitter->set_writer($writer);
    my $output = $self->dump(@docs);
    return $output;
}

sub dump_file {
    my ($self, $file, @docs) = @_;
    my $writer = YAML::PP::Writer::File->new(output => $file);
    $self->representer->emitter->set_writer($writer);
    my $output = $self->dump(@docs);
    return $output;
}

1;
