use strict;
use warnings;
package YAML::PP::Dumper;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Emitter;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        refs => {},
        seen => {},
        emitter => YAML::PP::Emitter->new(
            indent => $args{indent} // 2,
        ),
    }, $class;
    return $self;
}

sub emitter { return $_[0]->{emitter} }
sub set_emitter { $_[0]->{emitter} = $_[1] }

sub dump_string {
    my ($self, @docs) = @_;
    $self->emitter->init;
    $self->emitter->document_start_event({ implicit => 1 });
    for my $i (0 .. $#docs) {
        my $doc = $docs[ $i ];
        my $yaml_doc = $self->dump_document($doc);
        if ($i < $#docs) {
            $self->emitter->document_end_event({ implicit => 1 });
            $self->emitter->document_start_event({ implicit => 0 });
        }
    }
    $self->emitter->document_end_event({ implicit => 1 });
    my $yaml = $self->emitter->yaml;
    return $$yaml;
}

sub dump_document {
    my ($self, $doc) = @_;
    $self->{refs} = {};
    $self->{anchor_num} = 0;
    $self->check_references($doc);
    $self->dump_node($doc);
}

sub dump_node {
    my ($self, $node) = @_;

    my $seen = $self->{seen};
    my $anchor;
    if (ref $node) {

        if ($seen->{ $node } > 1) {
            $anchor = $self->{refs}->{ $node };
            unless (defined $anchor) {
                my $num = ++$self->{anchor_num};
                $self->{refs}->{ $node } = $num;
                $anchor = $num;
            }
            else {
                $self->emitter->alias_event({ value => $anchor });
                return;
            }

        }
    }
    if (ref $node eq 'HASH') {
        $self->emitter->mapping_start_event({ anchor => $anchor });
        for my $key (sort keys %$node) {
            $self->dump_node($key);
            $self->dump_node($node->{ $key });
        }
        $self->emitter->mapping_end_event;
    }
    elsif (ref $node eq 'ARRAY') {
        $self->emitter->sequence_start_event({ anchor => $anchor });
        for my $elem (@$node) {
            $self->dump_node($elem);
        }
        $self->emitter->sequence_end_event;
    }
    elsif (ref $node) {
        if (ref $node eq 'JSON::PP::Boolean' or ref $node eq 'boolean') {
            $self->emitter->scalar_event({
                value => $node ? 'true' : 'false',
                style => ':',
                anchor => $anchor,
            });
        }
        else {
            die "Not implemented";
        }
    }
    else {
        $self->emitter->scalar_event({ value => $node });
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
            for my $key (keys %$doc) {
                $self->check_references($doc->{ $key });
            }
        }
        elsif (ref $doc eq 'ARRAY') {
            for my $elem (@$doc) {
                $self->check_references($elem);
            }
        }
        elsif (ref $doc) {
            if (ref $doc eq 'JSON::PP::Boolean' or ref $doc eq 'boolean') {
            }
            else {
                die "Reference @{[ ref $doc ]} not implemented";
            }
        }
    }
}

1;
