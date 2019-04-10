use strict;
use warnings;
package YAML::PP::Schema::YAML1_1;

use base 'YAML::PP::Schema';

use YAML::PP::Common qw/ YAML_PLAIN_SCALAR_STYLE YAML_QUOTED_SCALAR_STYLE /;

#https://yaml.org/type/bool.html
# y|Y|yes|Yes|YES|n|N|no|No|NO
# |true|True|TRUE|false|False|FALSE
# |on|On|ON|off|Off|OFF

# https://yaml.org/type/float.html
#  [-+]?([0-9][0-9_]*)?\.[0-9.]*([eE][-+][0-9]+)? (base 10)
# |[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]* (base 60)
# |[-+]?\.(inf|Inf|INF) # (infinity)
# |\.(nan|NaN|NAN) # (not a number)

# https://yaml.org/type/int.html
#  [-+]?0b[0-1_]+ # (base 2)
# |[-+]?0[0-7_]+ # (base 8)
# |[-+]?(0|[1-9][0-9_]*) # (base 10)
# |[-+]?0x[0-9a-fA-F_]+ # (base 16)
# |[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+ # (base 60)

# https://yaml.org/type/null.html
#  ~ # (canonical)
# |null|Null|NULL # (English)
# | # (Empty)

my $RE_INT_1_1 = qr{^([+-]?(?:[0-9_]+))$};
#my $RE_FLOAT_1_1 = qr{^([+-]?([0-9][0-9_]*)?\.[0-9.]*([eE][+-][0-9]+)?)$};
# https://yaml.org/type/float.html has a bug. The regex says \.[0-9.], but
# probably means \.[0-9_]
my $RE_FLOAT_1_1 = qr{^([+-]?(?:[0-9][0-9_]*)?\.[0-9_]*(?:[eE][+-][0-9]+)?)$};
my $RE_SEXAGESIMAL = qr{^([+-]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*)$};
my $RE_SEXAGESIMAL_INT = qr{^([-+]?[1-9][0-9_]*(:[0-5]?[0-9])+)$};
my $RE_INT_OCTAL_1_1 = qr{^([+-]?)0([0-7_]+)$};
my $RE_INT_HEX_1_1 = qr{^([+-]?)(0x[0-9a-fA-F_]+)$};
my $RE_INT_BIN_1_1 = qr{^([-+]?)(0b[0-1_]+)$};

sub _from_oct {
    my ($constructor, $event, $matches) = @_;
    my ($sign, $oct) = @$matches;
    $oct =~ tr/_//d;
    my $result = oct $oct;
    $result = -$result if $sign eq '-';
    return $result;
}
sub _from_hex {
    my ($constructor, $event, $matches) = @_;
    my ($sign, $hex) = @$matches;
    my $result = hex $hex;
    $result = -$result if $sign eq '-';
    return $result;
}
sub _sexa_to_float {
    my ($constructor, $event, $matches) = @_;
    my ($float) = @$matches;
    my $result = 0;
    my $i = 0;
    my $sign = 1;
    $float =~ s/^-// and $sign = -1;
    for my $part (reverse split m/:/, $float) {
        $result += $part * ( 60 ** $i );
        $i++;
    }
    $result = unpack F => pack F => $result;
    return $result * $sign;
}
sub _to_float {
    my ($constructor, $event, $matches) = @_;
    my ($float) = @$matches;
    $float =~ tr/_//d;
    $float = unpack F => pack F => $float;
    return $float;
}
sub _to_int {
    my ($constructor, $event, $matches) = @_;
    my ($int) = @$matches;
    $int =~ tr/_//d;
    0 + $int;
}

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
    ) for (qw/ true TRUE True y Y yes Yes YES on On ON /);
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:bool',
        match => [ equals => $_ => $schema->false ],
    ) for (qw/ false FALSE False n N no No NO off Off OFF /);
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:int',
        match => [ regex => $RE_INT_OCTAL_1_1 => \&_from_oct ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:int',
        match => [ regex => $RE_INT_1_1 => \&_to_int ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:int',
        match => [ regex => $RE_INT_HEX_1_1 => \&_from_hex ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:float',
        match => [ regex => $RE_FLOAT_1_1 => \&_to_float ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:int',
        match => [ regex => $RE_INT_BIN_1_1 => \&_from_oct ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:int',
        match => [ regex => $RE_SEXAGESIMAL_INT => \&_sexa_to_float ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:float',
        match => [ regex => $RE_SEXAGESIMAL => \&_sexa_to_float ],
    );
    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:float',
        match => [ equals => $_ => 0 + "inf" ],
    ) for (qw/ .inf .Inf .INF +.inf +.Inf +.INF /);
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
        implicit => 0,
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
        true TRUE True y Y yes Yes YES on On ON
        false FALSE False n N n no No NO off Off OFF
        null NULL Null ~
        .inf .Inf .INF -.inf -.Inf -.INF +.inf +.Inf +.INF .nan .NaN .NAN
    /);
    $schema->add_representer(
        regex => qr{$RE_INT_1_1|$RE_FLOAT_1_1|$RE_INT_OCTAL_1_1|$RE_INT_HEX_1_1|$RE_INT_BIN_1_1|$RE_SEXAGESIMAL_INT|$RE_SEXAGESIMAL},
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

YAML::PP::Schema::YAML1_1 - YAML 1.1 Schema for YAML::PP

=head1 SYNOPSIS

    use YAML::PP;
    use YAML::PP::Schema::YAML1_1;

    my $yp = YAML::PP->new( schema => ['YAML1_1'] );
    my $yaml = <<'EOM';
    ---
    booltrue: [ true, True, TRUE, y, Y, yes, Yes, YES, on, On, ON ]
    EOM
    my $data = $yp->load_string($yaml);

=head1 DESCRIPTION

This schema allows you to load the common YAML Types from YAML 1.1.

=head1 SEE ALSO

=over

=item L<https://yaml.org/type/null.html>

=item L<https://yaml.org/type/float.html>

=item L<https://yaml.org/type/int.html>

=item L<https://yaml.org/type/bool.html>

=back
