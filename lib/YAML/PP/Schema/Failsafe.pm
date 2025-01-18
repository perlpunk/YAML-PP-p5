use strict;
use warnings;
package YAML::PP::Schema::Failsafe;

our $VERSION = '0.000'; # VERSION

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:str',
        match => [ all => sub { $_[1]->{value} } ],
    );
    $schema->add_sequence_resolver(
        tag => 'tag:yaml.org,2002:seq',
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            push @$$ref, @$list;
        },
    );
    $schema->add_mapping_resolver(
        tag => 'tag:yaml.org,2002:map',
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            for (my $i = 0; $i < @$list; $i += 2) {
                $$ref->{ $list->[ $i ] } = $list->[ $i + 1 ];
            }
        },
    );

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

Here you can see all Schemas and examples implemented by YAML::PP:
L<https://perlpunk.github.io/YAML-PP-p5/schemas.html>

Official Schema: L<https://yaml.org/spec/1.2/spec.html#id2802346>

=head1 METHODS

=over

=item register

Called by YAML::PP::Schema

=back

=cut
