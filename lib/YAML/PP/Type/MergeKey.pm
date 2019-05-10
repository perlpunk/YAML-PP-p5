use strict;
use warnings;
package YAML::PP::Type::MergeKey;

our $VERSION = '0.000'; # VERSION

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

1;
