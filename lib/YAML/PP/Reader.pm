# ABSTRACT: Reader class for YAML::PP representing input data
use strict;
use warnings;
package YAML::PP::Reader;

our $VERSION = '0.000'; # VERSION

sub new {
    my ($class, %args) = @_;
    my $input = delete $args{input};
    return bless { input => $input }, $class;
}

sub read {
    $_[0]->{input};
}
1;
