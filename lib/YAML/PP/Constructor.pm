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
    $self->set_stack([]);
    $self->set_anchors({});
}

sub docs { return $_[0]->{docs} }
sub stack { return $_[0]->{stack} }
sub anchors { return $_[0]->{anchors} }
sub set_docs { $_[0]->{docs} = $_[1] }
sub set_stack { $_[0]->{stack} = $_[1] }
sub set_anchors { $_[0]->{anchors} = $_[1] }
sub schema { return $_[0]->{schema} }
sub set_schema { $_[0]->{schema} = $_[1] }
sub cyclic_refs { return $_[0]->{cyclic_refs} }
sub set_cyclic_refs { $_[0]->{cyclic_refs} = $_[1] }

sub document_start_event {
    my ($self, $event) = @_;
    my $stack = $self->stack;
    my $ref = [];
    push @$stack, { type => 'document', ref => $ref, data => $ref, event => $event };
}

sub document_end_event {
    my ($self, $event) = @_;
    my $stack = $self->stack;
    my $last = pop @$stack;
    $last->{type} eq 'document' or die "Expected mapping, but got $last->{type}";
    if (@$stack) {
        die "Got unexpected end of document";
    }
    my $docs = $self->docs;
    push @$docs, $last->{ref}->[0];
    $self->set_anchors({});
    $self->set_stack([]);
}

sub mapping_start_event {
    my ($self, $event) = @_;
    my $ref = { type => 'mapping', ref => [], data => {}, event => $event };
    my $stack = $self->stack;

    push @$stack, $ref;
    if (defined(my $anchor = $event->{anchor})) {
        $self->anchors->{ $anchor } = { data => $ref->{data} };
    }
}

sub mapping_end_event {
    my ($self, $event) = @_;
    my $stack = $self->stack;

    my $last = pop @$stack;
    my ($ref, $data) = @{ $last }{qw/ ref data /};
    $last->{type} eq 'mapping' or die "Expected mapping, but got $last->{type}";

    for (my $i = 0; $i < @$ref; $i += 2) {
        my ($key, $value) = @$ref[ $i, $i + 1 ];
        $key = '' unless defined $key;
        if (ref $key) {
            $key = $self->stringify_complex($key);
        }
        $data->{ $key } = $value;
    }
    push @{ $stack->[-1]->{ref} }, $data;
    if (defined(my $anchor = $last->{event}->{anchor})) {
        $self->anchors->{ $anchor }->{finished} = 1;
    }
    return;
}

sub sequence_start_event {
    my ($self, $event) = @_;
    my $data = [];
    my $ref = { type => 'sequence', ref => $data, data => $data, event => $event };
    my $stack = $self->stack;

    push @$stack, $ref;
    if (defined(my $anchor = $event->{anchor})) {
        $self->anchors->{ $anchor } = { data => $ref->{data} };
    }
}

sub sequence_end_event {
    my ($self, $event) = @_;
    my $stack = $self->stack;
    my $last = pop @$stack;
    $last->{type} eq 'sequence' or die "Expected mapping, but got $last->{type}";

    push @{ $stack->[-1]->{ref} }, $last->{ref};
    if (defined(my $anchor = $last->{event}->{anchor})) {
        $self->anchors->{ $anchor }->{finished} = 1;
    }
    return;
}

sub stream_start_event {}

sub stream_end_event {}

sub scalar_event {
    my ($self, $event) = @_;
    DEBUG and warn "CONTENT $event->{value} ($event->{style})\n";
    my $value = $self->schema->load_scalar($event);
    if (defined (my $name = $event->{anchor})) {
        $self->anchors->{ $name } = { data => $value, finished => 1 };
    }
    my $last = $self->stack->[-1];
    push @{ $last->{ref} }, $value;
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
    my $last = $self->stack->[-1];
    push @{ $last->{ref} }, $value;
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

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Constructor - Constructing data structure from parsing events

=head1 METHODS

=over

=item new

The Constructor constructor

    my $constructor = YAML::PP::Constructor->new(
        schema => $schema,
        cyclic_refs => $cyclic_refs,
    );

=item init

Resets any data being used during construction.

    $constructor->init;

=item document_start_event, document_end_event, mapping_start_event, mapping_end_event, sequence_start_event, sequence_end_event, scalar_event, alias_event, stream_start_event, stream_end_event

These methods are called from YAML::PP::Parser:

    $constructor->document_start_event($event);

=item anchors, set_anchors

Helper for storing anchors during construction

=item docs, set_docs

Helper for storing resulting documents during construction

=item stack, set_stack

Helper for storing data during construction

=item cyclic_refs, set_cyclic_refs

Option for controlling the behaviour when finding circular references

=item schema, set_schema

Holds a L<YAML::PP::Schema> object

=item stringify_complex

When constructing a hash and getting a non-scalar key, this method is
used to stringify the key.

It uses a terse Data::Dumper output. L<YAML::XS>, for example, just uses
the default stringification, .ie. C<ARRAY(0x55617c0c7398)>.

=back

=cut
