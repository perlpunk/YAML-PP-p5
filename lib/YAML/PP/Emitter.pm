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
sub writer { $_[0]->{writer} }
sub set_writer { $_[0]->{writer} = $_[1] }

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
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x ($current_indent);
    my $props = '';
    my $anchor = $info->{anchor};
    my $tag = $info->{tag};
    if (defined $anchor) {
        $anchor = "&$anchor";
    }
    if (defined $tag) {
        $tag = $self->emit_tag('map', $tag);
    }
    $props = join ' ', grep defined, ($anchor, $tag);

    my $first = $self->first;
    my $new_first = 1;
    my $yaml = '';
    if ($stack->[-1] eq 'DOC') {
        if ($first and $props) {
            $yaml .= " $props\n";
        }
        elsif ($first) {
            $yaml .= "\n";
        }
        elsif ($props) {
            $yaml .= "$props\n";
        }
        $new_first = 0;
    }
    else {
        if ($props) {
            $props = " $props";
        }
        $self->set_current_indent($current_indent + $self->indent);
        if ($stack->[-1] eq 'SEQ') {
            $yaml .= "$indent-";
            if ($props) {
                $yaml .= $props;
                $new_first = 0;
            }
        }
        elsif ($stack->[-1] eq 'MAP') {
            if ($first) {
                $yaml .= " ";
            }
            else {
                $yaml .= $indent;
            }
            $yaml .= "?$props";
            if ($props) {
                $new_first = 0;
            }
            $stack->[-1] = 'COMPLEX';
        }
        elsif ($stack->[-1] eq 'MAPVALUE') {
            $yaml .= $props;
            $new_first = 0;
        }
        elsif ($stack->[-1] eq 'COMPLEX') {
            $stack->[-1] = 'COMPLEXVALUE';
            if ($first) {
                $yaml .= " ";
            }
            else {
                $yaml .= "$indent";
            }
            $yaml .= ":$props";
            if ($props) {
                $new_first = 0;
            }
        }
        else {
            die 23;
        }
        if ($new_first == 0) {
            $yaml .= "\n";
        }
    }
    $self->writer->write($yaml);
    push @{ $stack }, 'MAP';
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$new_first], ['new_first']);
    $self->set_first($new_first);
}

sub mapping_end_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ mapping_end_event\n";
    my ($self, $info) = @_;
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
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x $current_indent;
    my $props = '';
    my $anchor = $info->{anchor};
    my $tag = $info->{tag};
    my $yaml = '';
    if (defined $anchor) {
        $props = " &$anchor";
    }
    if (defined $tag) {
        $tag = $self->emit_tag('seq', $tag);
        $props .= " $tag";
    }

    my $first = $self->first;
    my $new_first = 1;
    if ($props) {
        $new_first = 0;
    }
    if ($stack->[-1] eq 'SEQ') {
        if (not $first) {
            $yaml .= $indent;
        }
        $yaml .= "-";
        if ($props) {
            $yaml .= "$props\n";
        }
        $self->set_current_indent($current_indent + $self->indent);
    }
    elsif ($stack->[-1] eq 'MAP') {
        $yaml .= "?";
        if ($props) {
            $yaml .= "$props\n";
        }
        $self->set_current_indent($current_indent + $self->indent);
        $stack->[-1] = 'COMPLEX';
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        $yaml .= "$props\n";
        $new_first = 0;
    }
    elsif ($stack->[-1] eq 'COMPLEXVALUE') {
        $yaml .= ":";
        if ($props) {
            $yaml .= "$props\n";
        }
        $self->set_current_indent($current_indent + $self->indent);
    }
    elsif ($stack->[-1] eq 'DOC') {
        if ($first or $props) {
            $yaml .= "$props\n";
        }
        $new_first = 0;
    }
    else {
        die 23;
    }
    $self->writer->write($yaml);
    push @{ $stack }, 'SEQ';
    $self->set_first($new_first);
}

sub sequence_end_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ sequence_end_event\n";
    my ($self, $info) = @_;
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
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x $current_indent;
    my $props = '';
    my $value = $info->{value};
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
    DEBUG and local $Data::Dumper::Useqq = 1;
    if (defined $value) {
        if ($style eq '') {
            # any
            if (not length $value or $value =~ tr/0-9a-zA-Z.-//c) {
                $style = '"';
            }
            else {
                $style = ':';
            }
        }
        if (($style eq '|' or $style eq '>') and $value eq '') {
            $style = '"';
        }
        if ($style eq ":") {
            $value =~ s/\n/\n\n/g;
        }
        elsif ($style eq "'") {
            $value =~ s/\n/\n\n/g;
            $value =~ s/'/''/g;
            $value = "'" . $value . "'";
        }
        elsif ($style eq '|') {
            DEBUG and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);
            my $indicators = '';
            if ($value !~ m/\n\z/) {
                $indicators .= '-';
                $value .= "\n";
            }
            elsif ($value =~ m/\n\n\z/) {
                $indicators .= '+';
            }
            $value =~ s/^(?=.)/$indent  /gm;
            $value = "|$indicators\n$value";
        }
        elsif ($style eq '>') {
            DEBUG and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);
            my @lines = split /\n/, $value, -1;
            DEBUG and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@lines], ['lines']);
            my $eol = 0;
            my $indicators = '';
            if ($lines[-1] eq '') {
                pop @lines;
                $eol = 1;
            }
            else {
                $indicators .= '-';
            }
            $value = ">$indicators\n";
            for my $i (0 .. $#lines) {
                my $line = $lines[ $i ];
                if (length $line) {
                    $value .= "$indent  $line\n";
                }
                if ($i != $#lines) {
                    $value .= "\n";
                }
            }
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

    DEBUG and warn __PACKAGE__.':'.__LINE__.": (@$stack)\n";
    my $yaml = '';
    if ($stack->[-1] eq 'MAP') {
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$first], ['first']);
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$props], ['props']);
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);
        if ($props) {
            $props .= ' ';
        }
        my $new_event = 'MAPVALUE';
        if ($style eq '|' or $style eq '>') {
            # oops, a complex key
            $yaml .= "?";
            $first = 1;
            $new_event = 'COMPLEXVALUE';
        }
        if ($first) {
            if ($style eq '|' or $style eq '>') {
                $yaml .= " $props$value";
            }
            else {
                $yaml .= " $props$value:";
            }
        }
        else {
            $yaml .= "$indent$props$value:";
        }
        $stack->[-1] = $new_event;
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        if (not length $value and not $props) {
            $yaml .= "\n";
        }
        else {
            if ($props) {
                if (length $value) {
                    $props .= ' ';
                }
            }
            $yaml .= " $props$value";
            if ($style ne '|' and $style ne '>') {
                $yaml .= "\n";
            }
        }
        $stack->[-1] = 'MAP';
    }
    elsif ($stack->[-1] eq 'SEQ') {
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$first], ['first']);
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);
        if (not $first) {
            $yaml .= "$indent";
        }
        else {
            $yaml .= " ";
        }
        if ($props and length $value) {
            $props .= ' ';
        }
        $yaml .= "-";
        if ($props or length $value) {
            $yaml .= " $props$value";
        }
        if ($style ne '|' and $style ne '>') {
            $yaml .= "\n";
        }
    }
    elsif ($stack->[-1] eq 'DOC') {
        if ($props and length $value) {
            $props .= ' ';
        }
        if ($first) {
            if ($props or length $value) {
                $yaml .= " $props$value";
            }
        }
        else {
            $yaml .= "$props$value";
        }
        if ($style ne '|' and $style ne '>') {
            $yaml .= "\n";
        }
    }
    $self->writer->write($yaml);
    $self->set_first(0);
}

sub alias_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ alias_event\n";
    my ($self, $info) = @_;
    my $stack = $self->event_stack;
    my $current_indent = $self->current_indent;
    my $indent = ' ' x $current_indent;

    my $alias = '*' . $info->{value};

    if ($stack->[-1] eq 'MAP') {
        $self->writer->write("$indent$alias :");
        $stack->[-1] = 'MAPVALUE';
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        $self->writer->write(" $alias\n");
        $stack->[-1] = 'MAP';
    }
    elsif ($stack->[-1] eq 'SEQ') {
        $self->writer->write("$indent- $alias\n");
    }
    elsif ($stack->[-1] eq 'DOC') {
        $self->writer->write("$alias\n");
    }
    $self->set_first(0);
}

sub document_start_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ document_start_event\n";
    my ($self, $info) = @_;
    if ($info->{implicit}) {
        $self->set_first(0);
    }
    else {
        $self->writer->write("---");
        $self->set_first(1);
    }
}

sub document_end_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ document_end_event\n";
    my ($self, $info) = @_;
    unless ($info->{implicit}) {
        $self->writer->write("...\n");
    }
}

sub stream_start_event {
}

sub stream_end_event {
}

sub emit_tag {
    my ($self, $type, $tag) = @_;
    if ($type eq 'scalar' and $tag =~ m/^tag:yaml.org,2002:(int|str|null|bool|binary)/) {
        $tag = "!!$1";
    }
    elsif ($type eq 'map' and $tag =~ m/^tag:yaml.org,2002:(map|set)/) {
        $tag = "!!$1";
    }
    elsif ($type eq 'seq' and $tag =~ m/^tag:yaml.org,2002:(omap|seq)/) {
        $tag = "!!$1";
    }
    elsif ($tag =~ m/^(!.*)/) {
        $tag = "$1";
    }
    else {
        $tag = "!<$tag>";
    }
    return $tag;
}

1;
