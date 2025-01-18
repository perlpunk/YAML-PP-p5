use strict;
use warnings;
package YAML::PP::Schema::Catchall;

our $VERSION = '0.000'; # VERSION

use Carp qw/ croak /;

use YAML::PP::Common qw/ YAML_PLAIN_SCALAR_STYLE YAML_SINGLE_QUOTED_SCALAR_STYLE /;

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};
    my $options = $args{options};
    my $empty_null = 0;
    for my $opt (@$options) {
        if ($opt eq 'empty=str') {
        }
        elsif ($opt eq 'empty=null') {
            $empty_null = 1;
        }
        else {
            croak "Invalid option for JSON Schema: '$opt'";
        }
    }

    $schema->add_resolver(
        tag => qr{^(?:!|tag:)},
        match => [ all => sub {
            my ($constructor, $event) = @_;
            my $value = $event->{value};
            return $value;
        }],
        implicit => 0,
    );
    $schema->add_sequence_resolver(
        tag => qr{^(?:!|tag:)},
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            push @$$ref, @$list;
        },
    );
    $schema->add_mapping_resolver(
        tag => qr{^(?:!|tag:)},
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

YAML::PP::Schema::JSON - YAML 1.2 JSON Schema

=head1 SYNOPSIS

    my $yp = YAML::PP->new( schema => ['JSON'] );
    my $yp = YAML::PP->new( schema => [qw/ JSON empty=str /] );
    my $yp = YAML::PP->new( schema => [qw/ JSON empty=null /] );

=head1 DESCRIPTION

=cut
