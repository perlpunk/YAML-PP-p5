use strict;
use warnings;
package YAML::PP::Schema::Failsafe;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Common qw/ YAML_QUOTED_SCALAR_STYLE /;

sub register {
    my ($self, %args) = @_;

    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Schema::Failsafe - YAML 1.2 Failsafe Schema

=head1 SYNOPSIS

    my $yp = YAML::PP->new( schema => ['Failsafe'] );

=head1 DESCRIPTION

With this schema, everything will be treated as a string. There are no booleans,
integers, floats or undefined values.

L<https://yaml.org/spec/1.2/spec.html#id2802346>

=head1 METHODS

=over

=item register

Called by YAML::PP::Schema

=back

=cut
