use strict;
use warnings;
package YAML::PP::Emitter;

our $VERSION = '0.000'; # VERSION

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        yaml => undef,
        level => -1,
        indent => $args{indent} // 2,
    }, $class;
    return $self;
}

sub level { return $_[0]->{level} }
sub set_level { $_[0]->{level} = $_[1] }
sub inc_level { $_[0]->{level}++ }
sub dec_level { $_[0]->{level}-- }
sub yaml { return $_[0]->{yaml} }
sub set_yaml { $_[0]->{yaml} = $_[1] }
sub event_stack { return $_[0]->{event_stack} }
sub set_event_stack { $_[0]->{event_stack} = $_[1] }
sub indent { return $_[0]->{indent} }
sub set_indent { $_[0]->{indent} = $_[1] }

sub init {
    my ($self) = @_;
    $self->set_level(0);
    $self->set_event_stack(['DOC']);
    my $yaml = '';
    $self->set_yaml(\$yaml);
}

sub mapping_start_event {
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $level = $self->level;
    my $indent = ' ' x ($level * $self->indent);

    $self->inc_level;
    $$yaml .= "\n";
    if ($stack->[-1] eq 'SEQ') {
        $$yaml .= "$indent-\n";
    }
    elsif ($stack->[-1] eq 'MAP') {
        $$yaml .= "$indent-\n";
    }
    push @{ $stack }, 'MAP';
}

sub mapping_end_event {
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $level = $self->level;
    my $indent = ' ' x ($level * $self->indent);

    $self->dec_level;
    pop @{ $stack };
    if ($stack->[-1] eq 'MAP') {
        $stack->[-1] = 'MAPVALUE';
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        $stack->[-1] = 'MAP';
    }
}

sub sequence_start_event {
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $level = $self->level;
    my $indent = ' ' x ($level * $self->indent);

    if ($stack->[-1] eq 'SEQ') {
        $$yaml .= "$indent-\n";
    }
    if ($stack->[-1] eq 'SEQ' or $stack->[-1] eq 'DOC') {
    }
    else {
        $$yaml .= "\n";
    }
    push @{ $stack }, 'SEQ';
    $self->inc_level;
}

sub sequence_end_event {
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $level = $self->level;
    my $indent = ' ' x ($level * $self->indent);

    $self->dec_level;
    pop @{ $stack };
    if ($stack->[-1] eq 'MAP') {
        $stack->[-1] = 'MAPVALUE';
    }
    elsif ($stack->[-1] eq 'MAPVALUE') {
        $stack->[-1] = 'MAP';
    }
}

sub scalar_event {
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    my $stack = $self->event_stack;
    my $level = $self->level;
    my $indent = ' ' x ($level * $self->indent);

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

sub document_start_event {
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    $$yaml .= "---\n";
}

sub document_end_event {
    my ($self, $info) = @_;
    my $yaml = $self->yaml;
    $$yaml .= "...\n";
}

1;
