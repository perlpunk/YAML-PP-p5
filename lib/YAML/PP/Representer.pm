use strict;
use warnings;
package YAML::PP::Representer;

our $VERSION = '0.000'; # VERSION

use Scalar::Util qw/ reftype blessed refaddr /;

use YAML::PP::Emitter;
use YAML::PP::Common qw/
    YAML_PLAIN_SCALAR_STYLE YAML_SINGLE_QUOTED_SCALAR_STYLE
    YAML_DOUBLE_QUOTED_SCALAR_STYLE YAML_QUOTED_SCALAR_STYLE
    YAML_ANY_SCALAR_STYLE
    YAML_LITERAL_SCALAR_STYLE YAML_FOLDED_SCALAR_STYLE
    YAML_FLOW_SEQUENCE_STYLE YAML_FLOW_MAPPING_STYLE
    YAML_BLOCK_MAPPING_STYLE YAML_BLOCK_SEQUENCE_STYLE
/;
use B;

sub new {
    my ($class, %args) = @_;
    my $emitter = delete $args{emitter} || YAML::PP::Emitter->new;
    my $self = bless {
        schema => $args{schema},
        refs => {},
        seen => {},
        emitter => $emitter,
    }, $class;
    return $self;
}

sub init {
    my ($self) = @_;
    $self->{refs} = {};
    $self->{seen} = {};
}

sub emitter { return $_[0]->{emitter} }
sub set_emitter { $_[0]->{emitter} = $_[1] }
sub schema { return $_[0]->{schema} }

sub dump {
    my ($self, @docs) = @_;
    $self->init;
    $self->emitter->stream_start_event({});
    if (@docs) {
        $self->emitter->document_start_event({ implicit => 0 });
        for my $i (0 .. $#docs) {
            my $doc = $docs[ $i ];
            $self->dump_document($doc);
            if ($i < $#docs) {
                $self->emitter->document_end_event({ implicit => 1 });
                $self->emitter->document_start_event({ implicit => 0 });
            }
        }
        $self->emitter->document_end_event({ implicit => 1 });
    }
    $self->emitter->stream_end_event({});
    return 1;
}

sub dump_document {
    my ($self, $doc) = @_;
    $self->{refs} = {};
    $self->{anchor_num} = 0;
    $self->check_references($doc);
    $self->dump_node($doc);
}

sub dump_node {
    my ($self, $value) = @_;

    my $seen = $self->{seen};
    my $anchor;
    my $ref = ref $value;
    if (ref $value) {

        my $refaddr = refaddr $value;
        if ($seen->{ $refaddr } and $seen->{ $refaddr } > 1) {
            $anchor = $self->{refs}->{ $refaddr };
            unless (defined $anchor) {
                my $num = ++$self->{anchor_num};
                $self->{refs}->{ $refaddr } = $num;
                $anchor = $num;
            }
            else {
                $self->emitter->alias_event({ value => $anchor });
                return;
            }

        }
    }

    my $node = {
        value => $value,
        reftype => reftype($value),
        items => undef,
        tag => undef,
        data => undef,
        style => undef,
    };

    if (ref $value) {
        $self->represent_noderef($node);
    }
    else {
        $self->represent_node($node);
    }
    $node->{reftype} = reftype $node->{data};
    $node->{reftype} = '' unless defined $node->{reftype};

    if ($node->{reftype} eq 'HASH' and my $tied = tied(%{ $node->{data} })) {
        my $representers = $self->schema->representers;
        $tied = ref $tied;
        if (my $def = $representers->{tied_equals}->{ $tied }) {
            my $code = $def->{code};
            my $done = $code->($self, $node);
        }
    }

    if ($node->{reftype} eq 'HASH') {
        unless (defined $node->{items}) {
            # by default we sort hash keys
            for my $key (sort keys %{ $node->{data} }) {
                push @{ $node->{items} }, $key, $node->{data}->{ $key };
            }
        }
        my $style = YAML_BLOCK_MAPPING_STYLE;
        $self->emitter->mapping_start_event({
            anchor => $anchor,
            style => $style,
            tag => $node->{tag},
        });
        $self->dump_node($_) for @{ $node->{items} };
        $self->emitter->mapping_end_event;
    }
    elsif ($node->{reftype} eq 'ARRAY') {
        unless (defined $node->{items}) {
            @{ $node->{items} } = @{ $node->{data} };
        }
        my $style = YAML_BLOCK_SEQUENCE_STYLE;
        $self->emitter->sequence_start_event({
            anchor => $anchor,
            style => $style,
            tag => $node->{tag},
        });
        $self->dump_node($_) for @{ $node->{items} };
        $self->emitter->sequence_end_event;
    }
    elsif ($node->{reftype}) {
        die "Reftype $node->{reftype} not implemented";
    }
    else {
        unless (defined $node->{items}) {
            $node->{items} = [$node->{data}];
        }
        $self->emitter->scalar_event({
            value => $node->{items}->[0],
            style => $node->{style},
            anchor => $anchor,
            tag => $node->{tag},
        });
    }
}

sub represent_node {
    my ($self, $node) = @_;
    my $representers = $self->schema->representers;

    if (not defined $node->{value}) {
        if (my $undef = $representers->{undef}) {
            return 1 if $undef->($self, $node);
        }
        else {
            $node->{style} = YAML_QUOTED_SCALAR_STYLE;
            $node->{data} = '';
            return 1;
        }
    }
    for my $rep (@{ $representers->{flags} }) {
        my $check_flags = $rep->{flags};
        my $flags = B::svref_2object(\$node->{value})->FLAGS;
        if ($flags & $check_flags) {
            return 1 if $rep->{code}->($self, $node);
        }

    }
    if (my $rep = $representers->{equals}->{ $node->{value} }) {
        return 1 if $rep->{code}->($self, $node);
    }
    for my $rep (@{ $representers->{regex} }) {
        if ($node->{value} =~ $rep->{regex}) {
            return 1 if $rep->{code}->($self, $node);
        }
    }
    unless (defined $node->{data}) {
        $node->{data} = $node->{value};
    }
    unless (defined $node->{style}) {
        $node->{style} = YAML_ANY_SCALAR_STYLE;
        $node->{style} = "";
    }
}

sub represent_noderef {
    my ($self, $node) = @_;
    my $representers = $self->schema->representers;

    if (my $classname = blessed($node->{value})) {
        if (my $def = $representers->{class_equals}->{ $classname }) {
            my $code = $def->{code};
            return 1 if $code->($self, $node);
        }
        for my $matches (@{ $representers->{class_matches} }) {
            my ($re, $code) = @$matches;
            if (ref $re and $classname =~ $re or $re) {
                return 1 if $code->($self, $node);
            }
        }
        for my $isa (@{ $representers->{class_isa} }) {
            my ($class_name, $code) = @$isa;
            if ($node->{ value }->isa($class_name)) {
                return 1 if $code->($self, $node);
            }
        }
    }
    if ($node->{reftype} eq 'SCALAR' and my $scalarref = $representers->{scalarref}) {
        my $code = $scalarref->{code};
        return 1 if $code->($self, $node);
    }
    if ($node->{reftype} eq 'REF' and my $refref = $representers->{refref}) {
        my $code = $refref->{code};
        return 1 if $code->($self, $node);
    }
    if ($node->{reftype} eq 'CODE' and my $coderef = $representers->{coderef}) {
        my $code = $coderef->{code};
        return 1 if $code->($self, $node);
    }
    $node->{data} = $node->{value};

}

my %_reftypes = (
    HASH => 1,
    ARRAY => 1,
    Regexp => 1,
    REGEXP => 1,
    CODE => 1,
    SCALAR => 1,
    REF => 1,
);

sub check_references {
    my ($self, $doc) = @_;
    my $reftype = reftype $doc or return;
    my $seen = $self->{seen};
    # check which references are used more than once
    if (++$seen->{ refaddr $doc } > 1) {
        # seen already
        return;
    }
    unless ($_reftypes{ $reftype }) {
        die sprintf "Reference %s not implemented",
            $reftype;
    }
    if ($reftype eq 'HASH') {
        $self->check_references($doc->{ $_ }) for keys %$doc;
    }
    elsif ($reftype eq 'ARRAY') {
        $self->check_references($_) for @$doc;
    }
    elsif ($reftype eq 'REF') {
        $self->check_references($$doc);
    }
}

1;
