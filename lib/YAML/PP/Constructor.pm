# ABSTRACT: Construct data structure from Parser Events
use strict;
use warnings;
package YAML::PP::Constructor;

our $VERSION = '0.000'; # VERSION

use constant DEBUG => ($ENV{YAML_PP_LOAD_DEBUG} or $ENV{YAML_PP_LOAD_TRACE}) ? 1 : 0;
use constant TRACE => $ENV{YAML_PP_LOAD_TRACE} ? 1 : 0;

my $RE_INT = '[+-]?[1-9]\d*';
my $RE_OCT = '0o[1-7][0-7]*';
my $RE_HEX = '0x[1-9a-fA-F][0-9a-fA-F]*';
my $RE_FLOAT = '[+-]?(?:\.\d+|\d+\.\d*)(?:[eE][+-]?\d+)?';
my $RE_NUMBER ="'(?:$RE_INT|$RE_OCT|$RE_HEX|$RE_FLOAT)";


sub new {
    my ($class, %args) = @_;

    my $bool = delete $args{boolean} // 'perl';
    my $truefalse;
    if ($bool eq 'JSON::PP') {
        require JSON::PP;
        $truefalse = \&bool_jsonpp;
    }
    elsif ($bool eq 'boolean') {
        require boolean;
        $truefalse = \&bool_booleanpm;
    }
    elsif ($bool eq 'perl') {
        $truefalse = \&bool_perl;
    }
    else {
        die "Invalid value for 'boolean': '$bool'. Allowed: ('perl', 'boolean', 'JSON::PP')";
    }

    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }

    my $self = bless {
        boolean => $bool,
        truefalse => $truefalse,
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
sub boolean { return $_[0]->{boolean} }
sub truefalse { return $_[0]->{truefalse} }

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
    my $value = $self->render_value($event);
    if (defined (my $name = $event->{anchor})) {
        $self->anchors->{ $name } = \$value;
    }
    $self->event(value => $value, event => $event);
    DEBUG and warn YAML::PP::Parser->event_to_test_suite([value => $event]) ."\n";
}

sub alias_event {
    my ($self, $event) = @_;
    my $value;
    my $name = $event->{value};
    if (my $anchor = $self->anchors->{ $name }) {
        $value = $$anchor;
    }
    DEBUG and warn YAML::PP::Parser->event_to_test_suite([alias => $event]) ."\n";
    $self->event(value => $value, event => $event);
}

sub event {
    my ($self, %args) = @_;
    my $value = $args{value};
    my $event = $args{event};

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

sub render_value {
    my ($self, $info) = @_;
    my $value;
    my $content = $info->{value};
    my $style = $info->{style};
    DEBUG and warn "CONTENT $content ($style)\n";
    if ($style eq ':') {
        $value = $self->render_plain_scalar($content);
    }
    else {
        $value = $content;
    }
    TRACE and local $Data::Dumper::Useqq = 1;
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);
    return $value;
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

sub render_plain_scalar {
    my ($self, $content) = @_;
    return unless defined $content;
    my $value;
    if ($content =~ m/^($RE_INT|$RE_FLOAT)$/){
        $value = 0 + $1;
    }
    elsif ($content =~ m/^($RE_HEX)/) {
        $value = hex $content;
    }
    elsif ($content =~ m/^($RE_OCT)/) {
        my $oct = 0 . substr($content, 2);
        $value = oct $oct;
    }
    elsif ($content eq 'true' or $content eq 'false') {
        $value = $self->truefalse->($content);
    }
    else {
        $value = $content;
    }
    return $value;
}

sub bool_jsonpp {
    $_[0] eq 'true' ? JSON::PP::true() : JSON::PP::false()
}

sub bool_booleanpm {
    $_[0] eq 'true' ? boolean::true() : boolean::false()
}

sub bool_perl {
    $_[0] eq 'true' ? 1 : 0
}


1;
