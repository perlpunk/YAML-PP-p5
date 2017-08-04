use strict;
use warnings;
package YAML::PP::Dumper;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Emitter;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        refs => {},
        emitter => YAML::PP::Emitter->new(
            indent => $args{indent} // 2,
        ),
    }, $class;
    return $self;
}

sub emitter { return $_[0]->{emitter} }
sub set_emitter { $_[0]->{emitter} = $_[1] }

sub dump {
    my ($self, @docs) = @_;
    $self->emitter->init;
    for my $i (0 .. $#docs) {
        my $doc = $docs[ $i ];
        my $yaml_doc = $self->dump_document($doc);
        if ($i < $#docs) {
            $self->emitter->document_end_event();
            $self->emitter->document_start_event();
        }
    }
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

    if (ref $node eq 'HASH') {
        $self->emitter->mapping_start_event();
        for my $key (sort keys %$node) {
            $self->dump_node($key);
            $self->dump_node($node->{ $key });
        }
        $self->emitter->mapping_end_event;
    }
    elsif (ref $node eq 'ARRAY') {
        $self->emitter->sequence_start_event;
        for my $elem (@$node) {
            $self->dump_node($elem);
        }
        $self->emitter->sequence_end_event;
    }
    elsif (ref $node) {
        die "Not implemented";
    }
    else {
        $self->emitter->scalar_event({ value => $node });
    }
}


sub check_references {
    my ($self, $doc) = @_;
    if (ref $doc) {
        my $count = $self->{refs}->{ $doc };
        if ($count) {
            # seen already
            return;
        }
        my $num = $self->{anchor_num}++;
        $self->{refs}->{ $doc } = $num;
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
            die "Reference @{[ ref $doc ]} not implemented";
        }
    }
}

1;
