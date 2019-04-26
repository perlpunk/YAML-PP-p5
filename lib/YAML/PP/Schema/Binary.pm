use strict;
use warnings;
package YAML::PP::Schema::Binary;

our $VERSION = '0.000'; # VERSION

use MIME::Base64 qw/ decode_base64 /;

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:binary',
        match => [ all => sub {
            my ($constructor, $event) = @_;
            my $base64 = $event->{value};
            my $binary = decode_base64($base64);
            return $binary;
        }],
        implicit => 0,
    );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Schema::Binary - Schema for loading binary data

=head1 SYNOPSIS

    use YAML::PP;
    my $yp = YAML::PP->new( schema => [qw/ JSON Binary /] );
    # or

    my $binary = $yp->load_string(<<'EOM');
    # The binary value a tiny arrow encoded as a gif image.
    --- !!binary "\
      R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5\
      OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+\
      +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC\
      AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs="
    EOM

=head1 DESCRIPTION

By prepending a base64 encoded binary string with the C<!!binary> tag, it can
be automatically decoded when loading.

=head1 METHODS

=over

=item register

Called by L<YAML::PP::Schema>

=back

=cut
