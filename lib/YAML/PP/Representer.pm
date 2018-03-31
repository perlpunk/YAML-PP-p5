use strict;
use warnings;
package YAML::PP::Representer;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Emitter;
use YAML::PP::Writer;
use B;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        schema => $args{schema},
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
    if (@docs) {
        $self->emitter->document_start_event({ implicit => 0 });
        for my $i (0 .. $#docs) {
            my $doc = $docs[ $i ];
            my $yaml_doc = $self->dump_document($doc);
            if ($i < $#docs) {
                $self->emitter->document_end_event({ implicit => 1 });
                $self->emitter->document_start_event({ implicit => 0 });
            }
        }
        $self->emitter->document_end_event({ implicit => 1 });
    }
    my $yaml = $self->writer->output;
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
    my ($self, $node) = @_;

    my $schema = $self->schema;
    my $representers = $schema->representers;
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
        my $style = 'block';
        $self->emitter->mapping_start_event({ anchor => $anchor, style => $style });
        for my $key (sort keys %$node) {
            $self->dump_node($key);
            $self->dump_node($node->{ $key });
        }
        $self->emitter->mapping_end_event;
    }
    elsif (ref $node eq 'ARRAY') {
        my $style = 'block';
        $self->emitter->sequence_start_event({ anchor => $anchor, style => $style });
        for my $elem (@$node) {
            $self->dump_node($elem);
        }
        $self->emitter->sequence_end_event;
    }
    elsif (ref $node) {
        # TODO check configuration for boolean type
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
        my $result;
        if (not defined $node) {
            if (my $undef = $representers->{undef}) {
                $result = $undef->($self, $node);
            }
            else {
                $result = { plain => "" };
            }
        }
        if (not $result and my $flag_rep = $representers->{flags}) {
            for my $rep (@$flag_rep) {
                my $check_flags = $rep->{flags};
                my $flags = B::svref_2object(\$node)->FLAGS;
                if ($flags & $check_flags) {
                    my $res = $rep->{code}->($self, $node);
                    if (not $res->{skip}) {
                        $result = $res;
                        last;
                    }
                }

            }
        }
        if (not $result and my $equals = $representers->{equals}) {
            if (my $rep = $equals->{ $node }) {
                my $res = $rep->{code}->($self, $node);
                if (not $res->{skip}) {
                    $result = $res;
                }
            }
        }
        if (not $result and my $regex = $representers->{regex}) {
            for my $rep (@$regex) {
                if ($node =~ $rep->{regex}) {
                    my $res = $rep->{code}->($self, $node);
                    if (not $res->{skip}) {
                        $result = $res;
                        last;
                    }
                }
            }
        }
        $result ||= { any => $node };
        if (exists $result->{plain}) {
            $self->emitter->scalar_event({ value => $result->{plain}, style => ":" });
        }
        elsif (exists $result->{quoted}) {
            $self->emitter->scalar_event({ value => $result->{quoted}, style => "'" });
        }
        elsif (exists $result->{any}) {
            $self->emitter->scalar_event({ value => $result->{any}, style => "" });
        }
        else {
            die "Unexpected";
        }
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
