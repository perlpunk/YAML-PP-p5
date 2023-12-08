# ABSTRACT: Reader class for YAML::PP representing input data
use strict;
use warnings;
package YAML::PP::Reader;
use Encode;

our $VERSION = '0.000'; # VERSION

sub input { return $_[0]->{input} }
sub set_input { $_[0]->{input} = $_[1] }

sub new {
    my ($class, %args) = @_;
    my $input = delete $args{input};
    my $utf8 = delete $args{utf8};
    $utf8 = 0 unless defined $utf8;
    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }
    if ($utf8) {
        $input = decode 'UTF-8', $input, Encode::FB_CROAK;
    }
    return bless {
        input => $input,
    }, $class;
}

sub read {
    my ($self) = @_;
    my $pos = pos $self->{input} || 0;
    my $yaml = substr($self->{input}, $pos);
    $self->{input} = '';
    return $yaml;
}

sub readline {
    my ($self) = @_;
    unless (length $self->{input}) {
        return;
    }
    if ( $self->{input} =~ m/\G([^\r\n]*(?:\n|\r\n|\r|\z))/g ) {
        my $line = $1;
        unless (length $line) {
            $self->{input} = '';
            return;
        }
        return $line;
    }
    return;
}

package YAML::PP::Reader::File;

use Scalar::Util qw/ openhandle /;

our @ISA = qw/ YAML::PP::Reader /;

use Carp qw/ croak /;

sub open_handle {
    if (openhandle( $_[0]->{input} )) {
        return $_[0]->{input};
    }
    open my $fh, '<:encoding(UTF-8)', $_[0]->{input}
        or croak "Could not open '$_[0]->{input}' for reading: $!";
    return $fh;
}

sub read {
    my $fh = $_[0]->{filehandle} ||= $_[0]->open_handle;
    if (wantarray) {
        my @yaml = <$fh>;
        return @yaml;
    }
    else {
        local $/;
        my $yaml = <$fh>;
        return $yaml;
    }
}

sub readline {
    my $fh = $_[0]->{filehandle} ||= $_[0]->open_handle;
    return scalar <$fh>;
}

1;
