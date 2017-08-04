use strict;
use warnings;
package YAML::PP::Dumper;

sub new {
    my ($class) = @_;
    my $self = bless {
        refs => {},
        level => 0,
    }, $class;
    return $self;
}

sub dump {
    my ($self, @docs) = @_;
    my $yaml = '';
    for my $i (0 .. $#docs) {
        my $doc = $docs[ $i ];
        my $yaml_doc = $self->dump_document($doc);
        $yaml .= $yaml_doc;
        $yaml .= "...\n---\n" if $i < $#docs;
    }
    return $yaml;
}

sub dump_document {
    my ($self, $doc) = @_;
    $self->{refs} = {};
    $self->{anchor_num} = 0;
    $self->{level} = -1;
    $self->{event_stack} = ['DOC'];
    $self->check_references($doc);
    my $yaml = '';
    $self->{yaml} = \$yaml;
    $self->dump_node($doc);
    return $yaml;
}

sub dump_node {
    my ($self, $node) = @_;
    if (ref $node eq 'HASH') {
        $self->event('mapping_start');
        for my $key (sort keys %$node) {
            $self->dump_node($key);
            $self->dump_node($node->{ $key });
        }
        $self->event('mapping_end');
    }
    elsif (ref $node eq 'ARRAY') {
        $self->event('sequence_start');
        for my $elem (@$node) {
            $self->dump_node($elem);
        }
        $self->event('sequence_end');
    }
    elsif (ref $node) {
        die "Not implemented";
    }
    else {
        $self->event('scalar', { value => $node });
    }
}

sub event {
    my ($self, $type, $info) = @_;
    my $yaml = $self->{yaml};

    my $level = $self->{level};
    $level = 0 if $level < 0;
    my $indent = ' ' x ($level * 2);
    my $stack = $self->{event_stack};
    if ($type eq 'mapping_start') {
        $self->{level}++;
        $$yaml .= "\n";
        if ($stack->[-1] eq 'SEQ') {
            $$yaml .= "$indent-\n";
        }
        elsif ($stack->[-1] eq 'MAP') {
            $$yaml .= "$indent-\n";
        }
        push @{ $stack }, 'MAP';
    }
    elsif ($type eq 'mapping_end') {
        $self->{level}--;
        pop @{ $stack };
        if ($stack->[-1] eq 'MAP') {
            $stack->[-1] = 'MAPVALUE';
        }
        elsif ($stack->[-1] eq 'MAPVALUE') {
            $stack->[-1] = 'MAP';
        }
        elsif ($stack->[-1] eq 'SEQ') {
        }
    }
    elsif ($type eq 'sequence_start') {
        if ($stack->[-1] eq 'SEQ') {
            $$yaml .= "$indent-\n";
        }
        if ($stack->[-1] eq 'SEQ' or $stack->[-1] eq 'DOC') {
        }
        else {
            $$yaml .= "\n";
        }
        push @{ $stack }, 'SEQ';
        $self->{level}++;
    }
    elsif ($type eq 'sequence_end') {
        $self->{level}--;
        pop @{ $stack };
        if ($stack->[-1] eq 'MAP') {
            $stack->[-1] = 'MAPVALUE';
        }
        elsif ($stack->[-1] eq 'MAPVALUE') {
            $stack->[-1] = 'MAP';
        }
        elsif ($stack->[-1] eq 'SEQ') {
        }
    }
    elsif ($type eq 'scalar') {

        my $value = $info->{value};
        if (defined $value) {
            $value =~ s/\\/\\\\/g;
            $value =~ s/"/\\"/g;
            $value =~ s/\n/\\n/g;
            $value =~ s/\r/\\r/g;
            $value =~ s/\t/\\t/g;
            $value =~ s/[\b]/\\b/g;
            $value = '"' . $value . '"';
        }
        else {
            $value = '';
        }

        if ($stack->[-1] eq 'MAP') {
            $$yaml .= "$indent$value: ";
            $stack->[-1] = 'MAPVALUE';
        }
        elsif ($stack->[-1] eq 'MAPVALUE') {
            $$yaml .= "$value\n";
            $stack->[-1] = 'MAP';
        }
        elsif ($stack->[-1] eq 'SEQ') {
            $$yaml .= "$indent- $value\n";
        }
        elsif ($stack->[-1] eq 'DOC') {
            $$yaml .= "$value\n";
        }

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
