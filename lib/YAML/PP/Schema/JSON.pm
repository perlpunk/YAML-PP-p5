use strict;
use warnings;
package YAML::PP::Schema::JSON;

our $VERSION = '0.000'; # VERSION

use B;

use YAML::PP::Common qw/ YAML_PLAIN_SCALAR_STYLE YAML_QUOTED_SCALAR_STYLE /;

my $RE_INT = qr{^(-?(?:0|[1-9][0-9]*))$};
my $RE_FLOAT = qr{^(-?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)$};

sub _to_int { 0 + $_[2]->[0] }

# DaTa++ && shmem++
sub _to_float { unpack F => pack F => $_[2]->[0] }

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:null',
        match => [ equals => null => undef ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:null',
        match => [ equals => '' => undef ],
        implicit => 0,
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:bool',
        match => [ equals => true => $schema->true ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:bool',
        match => [ equals => false => $schema->false ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:int',
        match => [ regex => $RE_INT => \&_to_int ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:float',
        match => [ regex => $RE_FLOAT => \&_to_float ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:str',
        match => [ all => sub { $_[1]->{value} } ],
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
        reftype => "*",
        code => sub {
            die "Dumping references not supported yet";
        },
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
            # TODO is inf/nan supported in YAML JSON Schema?
            if (exists $special{ $node->{value} }) {
                $node->{style} = YAML_PLAIN_SCALAR_STYLE;
                $node->{data} = "$node->{value}";
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
        equals => $_,
        code => sub {
            my ($rep, $node) = @_;
            $node->{style} = YAML_QUOTED_SCALAR_STYLE;
            $node->{data} = "$node->{value}";
            return 1;
        },
    ) for ("", qw/ true false null /);
    $schema->add_representer(
        regex => qr{$RE_INT|$RE_FLOAT},
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
