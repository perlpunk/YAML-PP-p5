use strict;
use warnings;
package YAML::PP::Representer;

our $VERSION = '0.000'; # VERSION

use Scalar::Util qw/ reftype blessed/;

use YAML::PP::Emitter;
use YAML::PP::Writer;
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

sub emitter { return $_[0]->{emitter} }
sub set_emitter { $_[0]->{emitter} = $_[1] }
sub writer { $_[0]->{writer} }
sub set_writer { $_[0]->{writer} = $_[1] }
sub schema { return $_[0]->{schema} }

sub dump_string {
    my ($self, @docs) = @_;
    $self->set_writer(YAML::PP::Writer->new);
    $self->dump(@docs);
}

sub dump_file {
    my ($self, $file, @docs) = @_;
    $self->set_writer(YAML::PP::Writer::File->new(output => $file));
    $self->emitter->set_writer($self->writer);
    $self->dump(@docs);
}

sub dump {
    my ($self, @docs) = @_;
    $self->emitter->set_writer($self->writer);
    $self->emitter->init;
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
    my $yaml = $self->writer->output;
    $self->emitter->finish;
    return $yaml;
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

    my $schema = $self->schema;
    my $representers = $schema->representers;
    my $seen = $self->{seen};
    my $anchor;
    if (ref $value) {

        if ($seen->{ $value } > 1) {
            $anchor = $self->{refs}->{ $value };
            unless (defined $anchor) {
                my $num = ++$self->{anchor_num};
                $self->{refs}->{ $value } = $num;
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

    my $done = 0;
    if (not ref $value) {
        if (not defined $value) {
            if (my $undef = $representers->{undef}) {
                $done = $undef->($self, $node);
            }
            else {
                $done = 1;
                $node->{style} = YAML_QUOTED_SCALAR_STYLE;
                $node->{data} = '';
            }
        }
        if (not $done and my $flag_rep = $representers->{flags}) {
            for my $rep (@$flag_rep) {
                my $check_flags = $rep->{flags};
                my $flags = B::svref_2object(\$node->{value})->FLAGS;
                if ($flags & $check_flags) {
                    my $res = $rep->{code}->($self, $node);
                    if ($res) {
                        $done = 1;
                        last;
                    }
                }

            }
        }
        if (not $done and my $equals = $representers->{equals}) {
            if (my $rep = $equals->{ $node->{value} }) {
                my $res = $rep->{code}->($self, $node);
                if ($res) {
                    $done = $res;
                }
            }
        }
        if (not $done and my $regex = $representers->{regex}) {
            for my $rep (@$regex) {
                if ($node->{value} =~ $rep->{regex}) {
                    my $res = $rep->{code}->($self, $node);
                    if ($res) {
                        $done = $res;
                        last;
                    }
                }
            }
        }
        unless (defined $node->{data}) {
            $node->{data} = $node->{value};
        }
        unless (defined $node->{style}) {
            $node->{style} = YAML_ANY_SCALAR_STYLE;
            $node->{style} = "";
        }
        $node->{reftype} = reftype $node->{data};
        $node->{reftype} = '' unless defined $node->{reftype};
    }
    else {
    if (my $classname = blessed($node->{value})) {
        if (my $class_equals = $representers->{class_equals}) {
            if (my $def = $class_equals->{ $classname }) {
                my $code = $def->{code};
                my $type = $code->($self, $node);
                $done = 1 if $type;
            }
        }
        if (not $done and my $class_matches = $representers->{class_matches}) {
            for my $matches (@$class_matches) {
                my ($re, $code) = @$matches;
                if (ref $re and $classname =~ $re or $re) {
                    my $type = $code->($self, $node);
                    $done = 1 if $type;
                    last if $type;
                }
            }
        }
    }
    if (not $done and $node->{reftype} eq 'SCALAR' and my $scalarref = $representers->{scalarref}) {
        my $code = $scalarref->{code};
        my $type = $code->($self, $node);
        $done = 1 if $type;
    }
    unless ($done) {
        $node->{data} = $node->{value};
    }
    $node->{reftype} = reftype $node->{data};
    $node->{reftype} = '' unless defined $node->{reftype};

    if ($node->{reftype} eq 'HASH' and my $tied = tied(%{ $node->{data} })) {
        $tied = ref $tied;
        if (my $tied_equals = $representers->{tied_equals}) {
            if (my $def = $tied_equals->{ $tied }) {
                my $code = $def->{code};
                my $type = $code->($self, $node);
            }
        }
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
        require Data::Dumper;
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$node->{reftype}], ['reftype']);
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$node->{data}], ['data']);
        die "Not implemented";
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

sub check_references {
    my ($self, $doc) = @_;
    if (ref $doc) {
        my $seen = $self->{seen};
        # check which references are used more than once
        if (++$seen->{ $doc } > 1) {
            # seen already
            return;
        }
        if (ref $doc eq 'HASH') {
            $self->check_references($doc->{ $_ }) for keys %$doc;
        }
        elsif (ref $doc eq 'ARRAY') {
            $self->check_references($_) for @$doc;
        }
        elsif (ref $doc) {
            if (ref $doc eq 'JSON::PP::Boolean' or ref $doc eq 'boolean') {
            }
            elsif (reftype($doc) eq 'HASH') {
                $self->check_references($doc->{ $_ }) for keys %$doc;
            }
            elsif (reftype($doc) eq 'ARRAY') {
                $self->check_references($_) for @$doc;
            }
            elsif (reftype($doc) eq 'Regexp') {
            }
            elsif (reftype($doc) eq 'REGEXP') {
            }
            elsif (reftype($doc) eq 'SCALAR') {
            }
            else {
                die "Reference @{[ ref $doc ]} not implemented";
            }
        }
    }
}

1;
