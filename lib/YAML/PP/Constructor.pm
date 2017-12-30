# ABSTRACT: Construct data structure from Parser Events
use strict;
use warnings;
package YAML::PP::Constructor;

our $VERSION = '0.000'; # VERSION

use YAML::PP;

use constant DEBUG => ($ENV{YAML_PP_LOAD_DEBUG} or $ENV{YAML_PP_LOAD_TRACE}) ? 1 : 0;
use constant TRACE => $ENV{YAML_PP_LOAD_TRACE} ? 1 : 0;


sub new {
    my ($class, %args) = @_;

    my $schema = delete $args{schema};

    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }

    my $self = bless {
        schema => $schema,
    }, $class;
}

sub init {
    my ($self) = @_;
    $self->set_docs([]);
    $self->set_data(undef);
    $self->set_refs([]);
    $self->set_anchors({});
}

sub data { return $_[0]->{data} }
sub docs { return $_[0]->{docs} }
sub refs { return $_[0]->{refs} }
sub anchors { return $_[0]->{anchors} }
sub set_data { $_[0]->{data} = $_[1] }
sub set_docs { $_[0]->{docs} = $_[1] }
sub set_refs { $_[0]->{refs} = $_[1] }
sub set_anchors { $_[0]->{anchors} = $_[1] }
sub schema { return $_[0]->{schema} }

sub begin {
    my ($self, $data, $event) = @_;

    my $refs = $self->refs;

    my $ref = $refs->[-1];
    if (not defined $$ref) {
        $$ref = $data;
    }
    elsif (ref $$ref eq 'ARRAY') {
        push @$$ref, $data;
        push @$refs, \$data;
    }
    elsif (ref $$ref eq 'HASH') {
        # we got a complex key
        push @$refs, \\undef;
        push @$refs, \$data;
    }
    else {
        die "Unexpected";
    }
    if (defined(my $anchor = $event->{anchor})) {
        $self->anchors->{ $anchor } = \$data;
    }
}

sub document_start_event {
    my ($self, $event) = @_;
    $self->set_refs([ \$self->{data} ]);
}

sub document_end_event {
    my ($self, $event) = @_;
    my $refs = $self->refs;
    my $docs = $self->docs;
    push @$docs, $self->data;
    pop @$refs if @$refs;
    $self->set_data(undef);
    $self->set_anchors({});
    $self->set_refs([]);
}

sub mapping_start_event {
    my ($self, $event) = @_;
    my $data = {};
    shift->begin($data, @_);
}

sub mapping_end_event {
    shift->end(@_);
}

sub sequence_start_event {
    my ($self, $event) = @_;
    my $data = [];
    shift->begin($data, @_);
}

sub sequence_end_event {
    shift->end(@_);
}

sub stream_start_event {
    my ($self, $event) = @_;
    my $refs = $self->refs;
    pop @$refs if @$refs;
}

sub stream_end_event {}

sub end {
    my ($self, $event) = @_;
    my $refs = $self->refs;

    my $complex = pop @$refs;
    if (@$refs > 1) {
        my $ref1 = $refs->[-1];
        my $ref2 = $refs->[-2];
        if (ref $$ref1 eq 'SCALAR') {
            pop @$refs;
            my $string = $self->stringify_complex($$complex);
            if (ref $$ref2 eq 'HASH') {
                $$ref2->{ $string } = undef;
                push @$refs, \$$ref2->{ $string };
            }
            else {
                die "Unexpected";
            }
        }
    }
}


sub scalar_event {
    my ($self, $event) = @_;
    DEBUG and warn "CONTENT $event->{value} ($event->{style})\n";
    my $value;
    if ($event->{tag}) {
        $value = $self->schema->load_scalar_tag($event);
    }
    else {
        $value = $self->schema->load_scalar($event->{style}, $event->{value});
    }
    if (defined (my $name = $event->{anchor})) {
        $self->anchors->{ $name } = \$value;
    }
    $self->add_scalar($value);
}

sub alias_event {
    my ($self, $event) = @_;
    my $value;
    my $name = $event->{value};
    if (my $anchor = $self->anchors->{ $name }) {
        $value = $$anchor;
    }
    $self->add_scalar($value);
}

sub add_scalar {
    my ($self, $value) = @_;

    my $refs = $self->refs;

    my $ref = $refs->[-1];
    if (not defined $$ref) {
        $$ref = $value;
        pop @$refs;
    }
    elsif (ref $$ref eq 'HASH') {
        $value = '' unless defined $value;
        $$ref->{ $value } = undef;
        push @$refs, \$$ref->{ $value };
    }
    elsif (ref $$ref eq 'ARRAY') {
        push @{ $$ref }, $value;
    }
}

sub stringify_complex {
    my ($self, $data) = @_;
    require Data::Dumper;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq = 0;
    local $Data::Dumper::Sortkeys = 1;
    my $string = Data::Dumper->Dump([$data], ['data']);
    $string =~ s/^\$data = //;
    return $string;
}

1;
