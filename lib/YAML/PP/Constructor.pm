# ABSTRACT: Construct data structure from Parser Events
use strict;
use warnings;
package YAML::PP::Constructor;

our $VERSION = '0.000'; # VERSION

use YAML::PP;

use constant DEBUG => ($ENV{YAML_PP_LOAD_DEBUG} or $ENV{YAML_PP_LOAD_TRACE}) ? 1 : 0;
use constant TRACE => $ENV{YAML_PP_LOAD_TRACE} ? 1 : 0;

my %cyclic_refs = qw/ allow 1 ignore 1 warn 1 fatal 1 /;

sub new {
    my ($class, %args) = @_;

    my $cyclic_refs = delete $args{cyclic_refs} || 'allow';
    die "Invalid value for cyclic_refs: $cyclic_refs"
        unless $cyclic_refs{ $cyclic_refs };
    my $schema = delete $args{schema};

    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }

    my $self = bless {
        schema => $schema,
        cyclic_refs => $cyclic_refs,
    }, $class;
}

sub init {
    my ($self) = @_;
    $self->set_docs([]);
    $self->set_refs([]);
    $self->set_anchors({});
}

sub docs { return $_[0]->{docs} }
sub refs { return $_[0]->{refs} }
sub anchors { return $_[0]->{anchors} }
sub set_docs { $_[0]->{docs} = $_[1] }
sub set_refs { $_[0]->{refs} = $_[1] }
sub set_anchors { $_[0]->{anchors} = $_[1] }
sub schema { return $_[0]->{schema} }
sub cyclic_refs { return $_[0]->{cyclic_refs} }

sub begin {
    my ($self, $data, $event) = @_;

    my $refs = $self->refs;

    push @$refs, $data;
    if (defined(my $anchor = $event->{anchor})) {
        $self->anchors->{ $anchor } = { data => $data->{data} };
    }
}

sub document_start_event {
    my ($self, $event) = @_;
    my $refs = $self->refs;
    my $ref = [];
    push @$refs, { type => 'document', ref => $ref, data => $ref, event => $event };
}

sub document_end_event {
    my ($self, $event) = @_;
    my $refs = $self->refs;
    my $last = pop @$refs;
    my ($type, $ref) = @{ $last }{qw/ type ref /};
    my $data = $ref->[0];
    $type eq 'document' or die "Expected mapping, but got $type";
    if (@$refs) {
        die "Got unexpected end of document";
    }
    my $docs = $self->docs;
    push @$docs, $data;
    $self->set_anchors({});
    $self->set_refs([]);
}

sub mapping_start_event {
    my ($self, $event) = @_;
    my $data = { type => 'mapping', ref => [], data => {}, event => $event };
    $self->begin($data, $event);
}

sub mapping_end_event {
    my ($self, $event) = @_;
    my $refs = $self->refs;

    my $last = pop @$refs;
    my ($type, $ref, $hash, $start_event) = @{ $last }{qw/ type ref data event /};
    $type eq 'mapping' or die "Expected mapping, but got $type";

    for (my $i = 0; $i < @$ref; $i += 2) {
        my ($key, $value) = @$ref[ $i, $i + 1 ];
        $key //= '';
        if (ref $key) {
            $key = $self->stringify_complex($key);
        }
        $hash->{ $key } = $value;
    }
    push @{ $refs->[-1]->{ref} }, $hash;
    if (defined(my $anchor = $start_event->{anchor})) {
        my $anchors = $self->anchors;
        $anchors->{ $anchor }->{finished} = 1;
    }
    return;
}

sub sequence_start_event {
    my ($self, $event) = @_;
    my $ref = [];
    my $data = { type => 'sequence', ref => $ref, data => $ref, event => $event };
    $self->begin($data, $event);
}

sub sequence_end_event {
    my ($self, $event) = @_;
    my $refs = $self->refs;
    my $last = pop @$refs;
    my ($type, $ref, $start_event) = @{ $last }{qw/ type ref event /};
    $type eq 'sequence' or die "Expected mapping, but got $type";
    push @{ $refs->[-1]->{ref} }, $ref;
    if (defined(my $anchor = $start_event->{anchor})) {
        my $anchors = $self->anchors;
        $anchors->{ $anchor }->{finished} = 1;
    }
    return;
}

sub stream_start_event {
}

sub stream_end_event {}


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
        $self->anchors->{ $name } = { data => $value, finished => 1 };
    }
    $self->add_scalar($value);
}

sub alias_event {
    my ($self, $event) = @_;
    my $value;
    my $name = $event->{value};
    if (my $anchor = $self->anchors->{ $name }) {
        # We know this is a cyclic ref since the node hasn't
        # been constructed completely yet
        unless ($anchor->{finished} ) {
            my $cyclic_refs = $self->cyclic_refs;
            if ($cyclic_refs ne 'allow') {
                if ($cyclic_refs eq 'fatal') {
                    die "Found cyclic ref";
                }
                if ($cyclic_refs eq 'warn') {
                    $anchor = { data => undef };
                    warn "Found cyclic ref";
                }
                elsif ($cyclic_refs eq 'ignore') {
                    $anchor = { data => undef };
                }
            }
        }
        $value = $anchor->{data};
    }
    $self->add_scalar($value);
}

sub add_scalar {
    my ($self, $value) = @_;

    my $last = $self->refs->[-1];

    my ($type, $ref) = @{ $last }{qw/ type ref /};
    push @$ref, $value;
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
