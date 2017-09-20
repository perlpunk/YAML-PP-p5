# ABSTRACT: Reader class for YAML::PP representing input data
use strict;
use warnings;
package YAML::PP::Reader;

our $VERSION = '0.000'; # VERSION

sub input { return $_[0]->{input} }
sub set_input { $_[0]->{input} = $_[1] }

sub new {
    my ($class, %args) = @_;
    my $input = delete $args{input};
    return bless {
        input => $input,
    }, $class;
}

sub read {
    return $_[0]->{input};
}

sub readline {
    my ($self) = @_;
    unless (length $self->{input}) {
        return;
    }
    $self->{input} =~ s/\A([^\r\n]*(?:[\r\n]|\z))// or die "Unexpected";
    my $line = $1;
    return $line;
}

package YAML::PP::Reader::File;

our @ISA = qw/ YAML::PP::Reader /;

sub open_handle {
    my $fh;
    unless ($fh) {
        open $fh, '<:encoding(UTF-8)', $_[0]->{input};
    }
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
    return $fh->getline;
}

1;
