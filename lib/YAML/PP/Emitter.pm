use strict;
use warnings;
package YAML::PP::Emitter;

our $VERSION = '0.000'; # VERSION

use constant DEBUG => $ENV{YAML_PP_EMIT_DEBUG};

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        yaml => undef,
        indent => $args{indent} // 2,
    }, $class;
    return $self;
}

sub yaml { return $_[0]->{yaml} }
sub set_yaml { $_[0]->{yaml} = $_[1] }
sub event_stack { return $_[0]->{event_stack} }
sub set_event_stack { $_[0]->{event_stack} = $_[1] }
sub indent { return $_[0]->{indent} }
sub set_indent { $_[0]->{indent} = $_[1] }
sub current_indent { return $_[0]->{current_indent} }
sub set_current_indent { $_[0]->{current_indent} = $_[1] }
sub first { return $_[0]->{first} }
sub set_first { $_[0]->{first} = $_[1] }

sub init {
    my ($self) = @_;
    $self->set_event_stack(['DOC']);
    $self->set_current_indent(0);
    $self->set_first(1);
    my $yaml = '';
    $self->set_yaml(\$yaml);
}

sub mapping_start_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ mapping_start_event\n";
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x ($current_indent);
    my $props = '';
    my $anchor = $info->{anchor};
    my $tag = $info->{tag};
    if (defined $anchor) {
        $props = " &$anchor";
    }
    if (defined $tag) {
        $tag = $self->emit_tag('map', $tag);
        $props .= " $tag";
    }

    my $first = $self->first;
    my $new_first = 1;
    if ($stack->[-1] eq 'SEQ') {
        if ($props) {
            $$yaml .= "$indent-$props\n";
            $new_first = 0;
        }
        else {
            $$yaml .= "$indent-";
        }
        $self->set_current_indent($current_indent + $self->indent);
    }
    elsif ($stack->[-1] eq 'MAP') {
        if ($first) {
            $$yaml .= " ?$props";
        }
        else {
            $$yaml .= "$indent?$props";
        }
        if ($props) {
            $new_first = 0;
            $$yaml .= "\n";
        }
        $self->set_current_indent($current_indent + $self->indent);
        $stack->[-1] = 'COMPLEX';
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        $$yaml .= "$props\n";
        $self->set_current_indent($current_indent + $self->indent);
        $new_first = 0;
    }
    elsif ($stack->[-1] eq 'DOC') {
        if ($first or $props) {
            $$yaml .= "$props\n";
        }
        else {
        }
    }
    elsif ($stack->[-1] eq 'COMPLEX') {
        $stack->[-1] = 'COMPLEXVALUE';
        if ($first) {
            $$yaml .= " :$props";
        }
        else {
            $$yaml .= "$indent:$props";
        }
        if ($props) {
            $$yaml .= "\n";
            $new_first = 0;
        }
        $self->set_current_indent($current_indent + $self->indent);
    }
    else {
        die 23;
    }
    push @{ $stack }, 'MAP';
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$new_first], ['new_first']);
    $self->set_first($new_first);
}

sub mapping_end_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ mapping_end_event\n";
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x $current_indent;

    pop @{ $stack };
    if ($stack->[-1] eq 'SEQ') {
    }
    elsif ($stack->[-1] eq 'MAP') {
        $stack->[-1] = 'MAPVALUE';
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        $stack->[-1] = 'MAP';
    }
    if ($stack->[-1] ne 'DOC') {
        $self->set_current_indent($current_indent - $self->indent);
    }
    $self->set_first(0);
}

sub sequence_start_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ sequence_start_event\n";
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x $current_indent;
    my $props = '';
    my $anchor = $info->{anchor};
    my $tag = $info->{tag};
    if (defined $anchor) {
        $props = " &$anchor";
    }
    if (defined $tag) {
        $tag = $self->emit_tag('seq', $tag);
        $props .= " $tag";
    }

    my $first = $self->first;
    my $new_first = 1;
    if ($stack->[-1] eq 'SEQ') {
        if (not $first) {
            $$yaml .= $indent;
        }
        if ($props) {
            $$yaml .= "-$props\n";
            $new_first = 0;
        }
        else {
            $$yaml .= "-";
        }
        $self->set_current_indent($current_indent + $self->indent);
    }
    elsif ($stack->[-1] eq 'MAP') {
        if ($props) {
            $$yaml .= "?$props\n";
            $new_first = 0;
        }
        else {
            $$yaml .= "?";
        }
        $self->set_current_indent($current_indent + $self->indent);
        $stack->[-1] = 'COMPLEX';
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        $$yaml .= "$props\n";
        $new_first = 0;
    }
    elsif ($stack->[-1] eq 'COMPLEXVALUE') {
        if ($props) {
            $$yaml .= ":$props\n";
            $new_first = 0;
        }
        else {
            $$yaml .= ":";
        }
        $self->set_current_indent($current_indent + $self->indent);
    }
    elsif ($stack->[-1] eq 'DOC') {
        if ($first or $props) {
            $$yaml .= "$props\n";
        }
        else {
        }
            $new_first = 0;
    }
    else {
        die 23;
    }
    push @{ $stack }, 'SEQ';
    $self->set_first($new_first);
}

sub sequence_end_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ sequence_end_event\n";
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x $current_indent;

    pop @{ $stack };
    if ($stack->[-1] eq 'MAP') {
        $stack->[-1] = 'MAPVALUE';
        $self->set_current_indent($current_indent - $self->indent);
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        $stack->[-1] = 'MAP';
    }
    elsif ($stack->[-1] eq 'COMPLEX') {
        $stack->[-1] = 'COMPLEXVALUE';
        $self->set_current_indent($current_indent - $self->indent);
    }
    elsif ($stack->[-1] eq 'COMPLEXVALUE') {
        $stack->[-1] = 'MAP';
        $self->set_current_indent($current_indent - $self->indent);
    }
    elsif ($stack->[-1] eq 'SEQ') {
        $self->set_current_indent($current_indent - $self->indent);
    }
    $self->set_first(0);
}

sub scalar_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ scalar_event\n";
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x $current_indent;
    my $props = '';
    my $value = $info->{content};
    my $anchor = $info->{anchor};
    my $tag = $info->{tag};
    if (defined $anchor) {
        $props = "&$anchor";
    }
    if (defined $tag) {
        $tag = $self->emit_tag('scalar', $tag);
        if ($props) {
            $props .= " $tag";
        }
        else {
            $props .= "$tag";
        }
    }
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$props], ['props']);
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);

    my $style = $info->{style} // '';
    if (defined $value) {
        if ($style eq ":") {
        }
        elsif ($style eq "'") {
            $value =~ s/'/''/g;
            $value = "'" . $value . "'";
        }
        elsif ($style eq '|') {
            $value =~ s/^(?=.)/$indent  /gm;
            $value = "|\n$value";
        }
        else {
            $value =~ s/\\/\\\\/g;
            $value =~ s/"/\\"/g;
            $value =~ s/\n/\\n/g;
            $value =~ s/\r/\\r/g;
            $value =~ s/\t/\\t/g;
            $value =~ s/[\b]/\\b/g;
            $value = '"' . $value . '"';
        }
    }
    else {
        $value = '';
    }
    my $first = $self->first;

    #warn __PACKAGE__.':'.__LINE__.": (@$stack)\n";
    if ($stack->[-1] eq 'MAP') {
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$first], ['first']);
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$props], ['props']);
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);
        if ($props) {
            $props .= ' ';
        }
        if ($first) {
            if ($stack->[-2] eq 'SEQ') {
                $$yaml .= " $props$value:";
            }
            elsif ($stack->[-2] eq 'MAPVALUE') {
                $$yaml .= "$props$value:";
            }
            elsif ($stack->[-2] eq 'MAP') {
                $$yaml .= " $props$value:";
            }
            elsif ($stack->[-2] eq 'DOC') {
                $$yaml .= "$props$value:";
            }
            elsif ($stack->[-2] eq 'COMPLEX') {
                $$yaml .= " $props$value:";
            }
            elsif ($stack->[-2] eq 'COMPLEXVALUE') {
                $$yaml .= " $props$value:";
            }
            else {
                warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$stack], ['stack']);
                die 23;
            }
        }
        else {
            $$yaml .= "$indent$props$value:";
        }
        $stack->[-1] = 'MAPVALUE';
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        if (not length $value and not $props) {
            $$yaml .= "\n";
        }
        else {
            if ($props) {
                if (length $value) {
                    $props .= ' ';
                }
            }
            $$yaml .= " $props$value";
            if ($style ne '|') {
                $$yaml .= "\n";
            }
        }
        $stack->[-1] = 'MAP';
    }
    elsif ($stack->[-1] eq 'SEQ') {
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$first], ['first']);
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);
        if (not $first) {
            $$yaml .= $indent;
        }
        else {
            $$yaml .= ' ';
        }
        if ($props and length $value) {
            $props .= ' ';
        }
        $$yaml .= "- $props$value\n";
    }
    elsif ($stack->[-1] eq 'DOC') {
        if ($props and length $value) {
            $props .= ' ';
        }
        if ($first) {
            if ($props or length $value) {
                $$yaml .= " $props$value";
            }
        }
        else {
            $$yaml .= "$props$value";
        }
        if ($style ne '|') {
            $$yaml .= "\n";
        }
    }
    $self->set_first(0);
}

sub alias_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ alias_event\n";
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x $current_indent;

    my $alias = '*' . $info->{content};

    if ($stack->[-1] eq 'MAP') {
        $$yaml .= "$indent$alias:";
        $stack->[-1] = 'MAPVALUE';
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        $$yaml .= " $alias\n";
        $stack->[-1] = 'MAP';
    }
    elsif ($stack->[-1] eq 'SEQ') {
        $$yaml .= "$indent- $alias\n";
    }
    elsif ($stack->[-1] eq 'DOC') {
        $$yaml .= "$alias\n";
    }
    $self->set_first(0);
}

sub document_start_event {
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    if ($info->{content}) {
        $$yaml .= "---";
        $self->set_first(1);
    }
    else {
        $self->set_first(0);
    }
}

sub document_end_event {
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    if ($info->{content}) {
        $$yaml .= "...\n";
    }
}

sub stream_start_event {
}

sub stream_end_event {
}

sub emit_tag {
    my ($self, $type, $tag) = @_;
    if ($type eq 'scalar' and $tag =~ m/^<tag:yaml.org,2002:(int|str|null|bool|binary)>/) {
        $tag = "!!$1";
    }
    elsif ($type eq 'map' and $tag =~ m/^<tag:yaml.org,2002:(map|set)>/) {
        $tag = "!!$1";
    }
    elsif ($type eq 'seq' and $tag =~ m/^<tag:yaml.org,2002:(omap|seq)>/) {
        $tag = "!!$1";
    }
    elsif ($tag =~ m/^<(!.*?)>/) {
        $tag = "$1";
    }
    else {
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$tag], ['tag']);
        $tag = "!$tag";
    }
    return $tag;
}

1;
