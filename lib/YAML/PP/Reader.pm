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
    $_[0]->{input};
}

1;
