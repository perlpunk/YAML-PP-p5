use strict;
use warnings;
package YAML::PP::Schema::Core;

our $VERSION = '0.000'; # VERSION

use B;

use YAML::PP::Common qw/ YAML_PLAIN_SCALAR_STYLE YAML_QUOTED_SCALAR_STYLE /;

my $RE_INT_CORE = qr{^([+-]?(?:[0-9]+))$};
my $RE_FLOAT_CORE = qr{^([+-]?(?:\.[0-9]+|[0-9]+(?:\.[0-9]*)?)(?:[eE][+-]?[0-9]+)?)$};
my $RE_INT_OCTAL = qr{^0o([0-7]+)$};
my $RE_INT_HEX = qr{^0x([0-9a-fA-F]+)$};

sub _from_oct { oct $_[2]->[0] }
sub _from_hex { hex $_[2]->[0] }

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:null',
        match => [ equals => $_ => undef ],
    ) for (qw/ null NULL Null ~ /, '');
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:bool',
        match => [ equals => $_ => $schema->true ],
    ) for (qw/ true TRUE True /);
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:bool',
        match => [ equals => $_ => $schema->false ],
    ) for (qw/ false FALSE False /);
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:int',
        match => [ regex => $RE_INT_CORE => \&YAML::PP::Schema::JSON::_to_int ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:int',
        match => [ regex => $RE_INT_OCTAL => \&_from_oct ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:int',
        match => [ regex => $RE_INT_HEX => \&_from_hex ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:float',
        match => [ regex => $RE_FLOAT_CORE => \&YAML::PP::Schema::JSON::_to_float ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:float',
        match => [ equals => $_ => 0 + "inf" ],
    ) for (qw/ .inf .Inf .INF /);
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:float',
        match => [ equals => $_ => 0 - "inf" ],
    ) for (qw/ -.inf -.Inf -.INF /);
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:float',
        match => [ equals => $_ => 0 + "nan" ],
    ) for (qw/ .nan .NaN .NAN /);
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:str',
        match => [ all => sub { $_[1]->{value} } ],
    );

    my $int_flags = B::SVp_IOK;
    my $float_flags = B::SVp_NOK;
    $schema->add_representer(
        flags => $int_flags,
        code => sub {
            my ($rep, $node) = @_;
            if (int($node->{value}) ne $node->{value}) {
                return 0;
            }
            $node->{style} = YAML_PLAIN_SCALAR_STYLE;
            $node->{data} = "$node->{value}";
            return 1;
        },
    );
    my %special = ( (0+'nan').'' => '.nan', (0+'inf').'' => '.inf', (0-'inf').'' => '-.inf' );
    $schema->add_representer(
        flags => $float_flags,
        code => sub {
            my ($rep, $node) = @_;
            if (exists $special{ $node->{value} }) {
                $node->{style} = YAML_PLAIN_SCALAR_STYLE;
                $node->{data} = $special{ $node->{value} };
                return 1;
            }
            if (0.0 + $node->{value} ne $node->{value}) {
                return 0;
            }
            if (int($node->{value}) eq $node->{value} and not $node->{value} =~ m/\./) {
                $node->{value} .= '.0';
            }
            $node->{style} = YAML_PLAIN_SCALAR_STYLE;
            $node->{data} = "$node->{value}";
            return 1;
        },
    );
    $schema->add_representer(
        undefined => sub {
            my ($rep, $node) = @_;
            $node->{style} = YAML_PLAIN_SCALAR_STYLE;
            $node->{data} = 'null';
            return 1;
        },
    );
    $schema->add_representer(
        equals => $_,
        code => sub {
            my ($rep, $node) = @_;
            $node->{style} = YAML_QUOTED_SCALAR_STYLE;
            $node->{data} = "$node->{value}";
            return 1;
        },
    ) for ("", qw/
        true TRUE True false FALSE False null NULL Null ~
        .inf .Inf .INF -.inf -.Inf -.INF .nan .NaN .NAN
    /);
    $schema->add_representer(
        regex => qr{$RE_INT_CORE|$RE_FLOAT_CORE|$RE_INT_OCTAL|$RE_INT_HEX},
        code => sub {
            my ($rep, $node) = @_;
            $node->{style} = YAML_QUOTED_SCALAR_STYLE;
            $node->{data} = "$node->{value}";
            return 1;
        },
    );

    if ($schema->bool_class) {
        $schema->add_representer(
            class_equals => $schema->bool_class,
            code => sub {
                my ($rep, $node) = @_;
                my $string = $node->{value} ? 'true' : 'false';
                $node->{style} = YAML_PLAIN_SCALAR_STYLE;
                @{ $node->{items} } = $string;
                $node->{data} = $string;
                return 1;
            },
        );
    }

    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Schema::Core - YAML 1.2 Core Schema

=head1 SYNOPSIS

    my $yp = YAML::PP->new( schema => ['Core'] );

=head1 DESCRIPTION

This schema loads additional values to the JSON schema as special types, for
example C<TRUE> and C<True> additional to C<true>.

L<https://yaml.org/spec/1.2/spec.html#id2804923>

=head1 METHODS

=over

=item register

Called by YAML::PP::Schema

=back

=cut
