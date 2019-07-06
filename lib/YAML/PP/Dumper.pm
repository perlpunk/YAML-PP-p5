use strict;
use warnings;
package YAML::PP::Dumper;

our $VERSION = '0.000'; # VERSION

use Scalar::Util qw/ blessed refaddr reftype /;
use YAML::PP;
use YAML::PP::Emitter;
use YAML::PP::Representer;
use YAML::PP::Writer;
use YAML::PP::Writer::File;
use YAML::PP::Common qw/
    YAML_PLAIN_SCALAR_STYLE YAML_SINGLE_QUOTED_SCALAR_STYLE
    YAML_DOUBLE_QUOTED_SCALAR_STYLE
    YAML_ANY_SCALAR_STYLE
    YAML_LITERAL_SCALAR_STYLE YAML_FOLDED_SCALAR_STYLE
    YAML_FLOW_SEQUENCE_STYLE YAML_FLOW_MAPPING_STYLE
    YAML_BLOCK_MAPPING_STYLE YAML_BLOCK_SEQUENCE_STYLE
/;

sub new {
    my ($class, %args) = @_;

    my $header = delete $args{header};
    $header = 1 unless defined $header;
    my $footer = delete $args{footer};
    $footer = 0 unless defined $footer;

    my $schema = delete $args{schema} || YAML::PP->default_schema(
        boolean => 'perl',
    );

    my $emitter = delete $args{emitter} || YAML::PP::Emitter->new;
    unless (blessed($emitter)) {
        $emitter = YAML::PP::Emitter->new(
            %$emitter
        );
    }
    my $self = bless {
        representer => YAML::PP::Representer->new(
            schema => $schema,
        ),
        emitter => $emitter,
        seen => {},
        anchors => {},
        anchor_num => 0,
        header => $header,
        footer => $footer,
    }, $class;
    return $self;
}

sub clone {
    my ($self) = @_;
    my $clone = {
        representer => $self->representer->clone,
        emitter => $self->emitter->clone,
        seen => {},
        anchors => {},
        anchor_num => 0,
        header => $self->header,
        footer => $self->footer,
    };
    return bless $clone, ref $self;
}

sub init {
    my ($self) = @_;
    $self->{seen} = {};
    $self->{anchors} = {};
    $self->{anchor_num} = 0;
}

sub emitter { return $_[0]->{emitter} }
sub representer { return $_[0]->{representer} }
sub set_representer { $_[0]->{representer} = $_[1] }
sub header { return $_[0]->{header} }
sub footer { return $_[0]->{footer} }

sub dump {
    my ($self, @docs) = @_;
    $self->emitter->init;

    $self->emitter->stream_start_event({});

    for my $i (0 .. $#docs) {
        my $header_implicit = ($i == 0 and not $self->header);
        $self->emitter->document_start_event({ implicit => $header_implicit });
        $self->init;
        $self->check_references($docs[ $i ]);
        $self->dump_node($docs[ $i ]);
        my $footer_implicit = (not $self->footer);
        $self->emitter->document_end_event({ implicit => $footer_implicit });
    }

    $self->emitter->stream_end_event({});

    my $output = $self->emitter->writer->output;
    $self->emitter->finish;
    return $output;
}

sub dump_node {
    my ($self, $value) = @_;
    my $node = {
        value => $value,
    };
    if (ref $value) {

        my $seen = $self->{seen};
        my $refaddr = refaddr $value;
        if ($seen->{ $refaddr } and $seen->{ $refaddr } > 1) {
            my $anchor = $self->{anchors}->{ $refaddr };
            unless (defined $anchor) {
                my $num = ++$self->{anchor_num};
                $self->{anchors}->{ $refaddr } = $num;
                $node->{anchor} = $num;
            }
            else {
                $node->{value} = $anchor;
                $self->emit_node([ alias => $node ]);
                return;
            }

        }
    }
    $node = $self->representer->represent_node($node);
    $self->emit_node($node);
}

sub emit_node {
    my ($self, $item) = @_;
    my ($type, $node) = @$item;
    if ($type eq 'alias') {
        $self->emitter->alias_event({ value => $node->{value} });
        return;
    }
    if ($type eq 'mapping') {
        my $style = YAML_BLOCK_MAPPING_STYLE;
        $self->emitter->mapping_start_event({
            anchor => $node->{anchor},
            style => $style,
            tag => $node->{tag},
        });
        for (@{ $node->{items} }) {
            $self->dump_node($_);
        }
        $self->emitter->mapping_end_event;
        return;
    }
    if ($type eq 'sequence') {
        my $style = YAML_BLOCK_SEQUENCE_STYLE;
        $self->emitter->sequence_start_event({
            anchor => $node->{anchor},
            style => $style,
            tag => $node->{tag},
        });
        for (@{ $node->{items} }) {
            $self->dump_node($_);
        }
        $self->emitter->sequence_end_event;
        return;
    }
    $self->emitter->scalar_event({
        value => $node->{items}->[0],
        style => $node->{style},
        anchor => $node->{anchor},
        tag => $node->{tag},
    });
}


sub dump_string {
    my ($self, @docs) = @_;
    my $writer = YAML::PP::Writer->new;
    $self->emitter->set_writer($writer);
    my $output = $self->dump(@docs);
    return $output;
}

sub dump_file {
    my ($self, $file, @docs) = @_;
    my $writer = YAML::PP::Writer::File->new(output => $file);
    $self->emitter->set_writer($writer);
    my $output = $self->dump(@docs);
    return $output;
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
