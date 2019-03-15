use strict;
use warnings;
package YAML::PP::Schema;
use B;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Common qw/ YAML_PLAIN_SCALAR_STYLE /;


sub new {
    my ($class, %args) = @_;

    my $bool = delete $args{boolean};
    $bool = 'perl' unless defined $bool;
    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }
    my $true;
    my $false;
    my $bool_class = '';
    if ($bool eq 'JSON::PP') {
        require JSON::PP;
        $true = \&bool_jsonpp_true;
        $false = \&bool_jsonpp_false;
        $bool_class = 'JSON::PP::Boolean';
    }
    elsif ($bool eq 'boolean') {
        require boolean;
        $true = \&bool_booleanpm_true;
        $false = \&bool_booleanpm_false;
        $bool_class = 'boolean';
    }
    elsif ($bool eq 'perl') {
        $true = \&bool_perl_true;
        $false = \&bool_perl_false;
    }
    else {
        die "Invalid value for 'boolean': '$bool'. Allowed: ('perl', 'boolean', 'JSON::PP')";
    }

    my $self = bless {
        resolvers => {},
        representers => {},
        true => $true,
        false => $false,
        bool_class => $bool_class,
    }, $class;
    return $self;
}

sub resolvers { return $_[0]->{resolvers} }
sub representers { return $_[0]->{representers} }
sub true { return $_[0]->{true} }
sub false { return $_[0]->{false} }
sub bool_class { return $_[0]->{bool_class} }

sub load_subschemas {
    my ($self, @schemas) = @_;
    for my $s (@schemas) {
        my $class = "YAML::PP::Schema::" . $s;
        my $tags = $class->register(
            schema => $self,
        );
    }
}

sub add_resolver {
    my ($self, %args) = @_;
    my $tag = $args{tag};
    my $rule = $args{match};
    my $resolvers = $self->resolvers;
    my ($type, $match, $value) = @$rule;
    my $implicit = $args{implicit};
    $implicit = 1 unless defined $implicit;
    my @resolvers;
    if ($tag) {
        my $res = $resolvers->{tag}->{ $tag } ||= {};
        push @resolvers, $res;
    }
    if ($implicit) {
        push @resolvers, $resolvers->{value} ||= {};
    }
    for my $res (@resolvers) {
        if ($type eq 'equals') {
            unless (exists $res->{equals}->{ $match }) {
                $res->{equals}->{ $match } = $value;
            }
            next;
        }
        if ($type eq 'regex') {
            push @{ $res->{regex} }, [ $match => $value ];
        }
    }
}

sub add_representer {
    my ($self, %args) = @_;

    my $representers = $self->representers;
    if (my $flags = $args{flags}) {
        my $rep = $representers->{flags} ||= [];
        push @$rep, \%args;
        return;
    }
    if (my $regex = $args{regex}) {
        my $rep = $representers->{regex} ||= [];
        push @$rep, \%args;
        return;
    }
    if (my $regex = $args{class_matches}) {
        my $rep = $representers->{class_matches} ||= [];
        push @$rep, [ $args{class_matches}, $args{code} ];
        return;
    }
    if (my $class_equals = $args{class_equals}) {
        my $rep = $representers->{class_equals} ||= {};
        $rep->{ $class_equals } = {
            code => $args{code},
        };
        return;
    }
    if (my $class_isa = $args{class_isa}) {
        my $rep = $representers->{class_isa} ||= [];
        push @$rep, [ $args{class_isa}, $args{code} ];
        return;
    }
    if (my $tied_equals = $args{tied_equals}) {
        my $rep = $representers->{tied_equals} ||= {};
        $rep->{ $tied_equals } = {
            code => $args{code},
        };
        return;
    }
    if (defined(my $equals = $args{equals})) {
        my $rep = $representers->{equals} ||= {};
        $rep->{ $equals } = {
            code => $args{code},
        };
        return;
    }
    if (defined(my $scalarref = $args{scalarref})) {
        $representers->{scalarref} = {
            code => $args{code},
        };
        return;
    }
    if (defined(my $refref = $args{refref})) {
        $representers->{refref} = {
            code => $args{code},
        };
        return;
    }
    if (defined(my $coderef = $args{coderef})) {
        $representers->{coderef} = {
            code => $args{code},
        };
        return;
    }
    if (my $undef = $args{undefined}) {
        $representers->{undef} = $undef;
        return;
    }
}

sub load_scalar_tag {
    my ($self, $event) = @_;
    my $tag = $event->{tag};
    my $value = $event->{value};
    $value = '' unless defined $value;
    my $resolvers = $self->resolvers;
    my $res = $resolvers->{tag}->{ $tag };

    if (my $equals = $res->{equals}) {
        if (exists $equals->{ $value }) {
            my $res = $equals->{ $value };
            if (ref $res eq 'CODE') {
                return $res->();
            }
            return $res;
        }
    }
    if (my $regex = $res->{regex}) {
        for my $item (@$regex) {
            my ($re, $sub) = @$item;
            my @matches = $value =~ $re;
            if (@matches) {
                return $sub->(@matches);
            }
        }
        die "Tag $tag ($value)";
    }
#    die "Tag $tag ($value)";
    return $value;
}

sub load_scalar {
    my ($self, $style, $value) = @_;
    if ($style ne YAML_PLAIN_SCALAR_STYLE) {
        return $value;
    }
    my $resolvers = $self->resolvers;
    my $res = $resolvers->{value};
    $value = '' unless defined $value;

    if (my $equals = $res->{equals}) {
        if (exists $equals->{ $value }) {
            my $res = $equals->{ $value };
            if (ref $res eq 'CODE') {
                return $res->();
            }
            return $res;
        }
    }
    if (my $regex = $res->{regex}) {
        for my $item (@$regex) {
            my ($re, $sub) = @$item;
            my @matches = $value =~ $re;
            if (@matches) {
                return $sub->(@matches);
            }
        }
    }
    return $value;
}

sub bool_jsonpp_true { JSON::PP::true() }

sub bool_booleanpm_true { boolean::true() }

sub bool_perl_true { 1 }

sub bool_jsonpp_false { JSON::PP::false() }

sub bool_booleanpm_false { boolean::false() }

sub bool_perl_false { !1 }


package YAML::PP::Schema::Failsafe;

use base 'YAML::PP::Schema';

use YAML::PP::Common qw/ YAML_QUOTED_SCALAR_STYLE /;

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_resolver(
        match => [ equals => '' => '' ],
    );

    $schema->add_representer(
        undefined => sub {
            my ($rep, $node) = @_;
            $node->{data} = '';
            $node->{style} = YAML_QUOTED_SCALAR_STYLE;
            return 1;
        },
    );
    return;
}

package YAML::PP::Schema::JSON;
use base 'YAML::PP::Schema';

use YAML::PP::Common qw/ YAML_PLAIN_SCALAR_STYLE YAML_QUOTED_SCALAR_STYLE /;

my $RE_INT = qr{^(-?(?:0|[1-9][0-9]*))$};
my $RE_FLOAT = qr{^(-?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)$};

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub _to_int { 0 + $_[0] }

# DaTa++ && shmem++
sub _to_float { unpack F => pack F => $_[0] }

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
        match => [ regex => qr{^(.*)$} => sub { $_[0] } ],
        implicit => 0,
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

package YAML::PP::Schema::Core;
use base 'YAML::PP::Schema';

use YAML::PP::Common qw/ YAML_PLAIN_SCALAR_STYLE YAML_QUOTED_SCALAR_STYLE /;

my $RE_INT_CORE = qr{^([+-]?(?:[0-9]+))$};
my $RE_FLOAT_CORE = qr{^([+-]?(?:\.[0-9]+|[0-9]+(?:\.[0-9]*)?)(?:[eE][+-]?[0-9]+)?)$};
my $RE_INT_OCTAL = qr{^0o([0-7]+)$};
my $RE_INT_HEX = qr{^0x([0-9a-fA-F]+)$};


sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub _from_oct { oct $_[0] }
sub _from_hex { hex $_[0] }

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
        match => [ regex => qr{^(.*)$} => sub { $_[0] } ],
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
    ) for ("", qw/ true TRUE True false FALSE False null NULL Null ~ /);
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

YAML::PP::Schema - Schema for YAML::PP


