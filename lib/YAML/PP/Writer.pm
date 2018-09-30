# ABSTRACT: Writer class for YAML::PP representing output data
use strict;
use warnings;
package YAML::PP::Writer;

our $VERSION = '0.000'; # VERSION

sub output { return $_[0]->{output} }
sub set_output { $_[0]->{output} = $_[1] }

sub new {
    my ($class, %args) = @_;
    my $output = delete $args{output};
    $output = '' unless defined $output;
    return bless {
        output => $output,
    }, $class;
}

sub write {
    my ($self, $line) = @_;
    $self->{output} .= $line;
}

sub init {
    $_[0]->{output} = '';
}

sub finish {
    my ($self) = @_;
    $self->{output} = undef;
}

package YAML::PP::Writer::File;

use Scalar::Util qw/ openhandle /;

our @ISA = qw/ YAML::PP::Writer /;

use Carp qw/ croak /;

sub open_handle {
    if (openhandle($_[0]->{output})) {
        return $_[0]->{output};
    }
    open my $fh, '>:encoding(UTF-8)', $_[0]->{output}
        or croak "Could not open '$_[0]->{output}' for writing: $!";
    return $fh;
}

sub write {
    my ($self, $line) = @_;
    my $fh = $self->{filehandle} ||= $self->open_handle;
    print $fh $line;
}

sub init {
    my ($self) = @_;
    my $fh = $self->{filehandle} ||= $self->open_handle;
}

sub finish {
    my ($self) = @_;
    close $self->{filehandle};
}

1;
