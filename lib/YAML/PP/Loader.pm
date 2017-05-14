# ABSTRACT: Load YAML into data with YAML::PP
use strict;
use warnings;
package YAML::PP::Loader;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Parser;

use constant DEBUG => ($ENV{YAML_PP_LOAD_DEBUG} or $ENV{YAML_PP_LOAD_TRACE}) ? 1 : 0;
use constant TRACE => $ENV{YAML_PP_LOAD_TRACE} ? 1 : 0;

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

    my $parser = $args{parser} || YAML::PP::Parser->new;
    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }
    my $self = bless {
        boolean => $bool,
        truefalse => $truefalse,
        parser => $parser,
    }, $class;
    $parser->set_receiver($self);
    return $self;
}

sub parser { return $_[0]->{parser} }
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

sub load {
    my ($self, $yaml) = @_;
    $self->set_docs([]);
    my $parser = $self->parser;
    $self->set_data(undef);
    $self->set_refs([]);
    $self->set_anchors({});
    $parser->parse($yaml);
    $self->set_data(undef);
    $self->set_refs([]);
    $self->set_anchors({});
    my $docs = $self->docs;
    return wantarray ? @$docs : $docs->[0];
}


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

sub begin_doc {
    my ($self, $event) = @_;
    $self->set_data(undef);
    $self->set_refs([ \$self->{data} ]);
    $self->set_anchors({});
}

sub end_doc {
    my ($self, $event) = @_;
    my $refs = $self->refs;
    my $docs = $self->docs;
    push @$docs, $self->data;
    pop @$refs if @$refs;
}

sub begin_map {
    my ($self, $event) = @_;
    my $data = {};
    shift->begin($data, @_);
}

sub end_map {
    shift->end(@_);
}

sub begin_seq {
    my ($self, $event) = @_;
    my $data = [];
    shift->begin($data, @_);
}

sub end_seq {
    shift->end(@_);
}

sub begin_str {
    my ($self, $event) = @_;
    my $refs = $self->refs;
    pop @$refs if @$refs;
}

sub end_str {}

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


sub value {
    my ($self, $event) = @_;
    my $value = $self->render_value($event);
    $self->event(value => $value, event => $event);
    DEBUG and warn YAML::PP::Parser->event_to_test_suite([value => $event]) ."\n";
}

sub alias {
    my ($self, $event) = @_;
    my $value;
    my $name = $event->{content};
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
        $$ref->{ $value } = undef;
        push @$refs, \$$ref->{ $value };
    }
    elsif (ref $$ref eq 'ARRAY') {
        push @{ $$ref }, $value;
    }
}

my %control = ( '\\' => '\\', n => "\n", t => "\t", r => "\r", b => "\b" );
sub render_value {
    my ($self, $info) = @_;
    my $value;
    my $content = $info->{content};
    my $style = $info->{style};
    DEBUG and warn "CONTENT $content ($style)\n";
    if ($style eq ':') {
        $value = $self->render_plain_scalar($content);
    }
    else {
        $value = $content;
        $value =~ s/\\([\\ntrb])/$control{ $1 }/eg;
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
    if ($content =~ m/^($YAML::PP::Parser::RE_INT|$YAML::PP::Parser::RE_FLOAT)$/){
        $value = 0 + $1;
    }
    elsif ($content =~ m/^($YAML::PP::Parser::RE_HEX)/) {
        $value = hex $content;
    }
    elsif ($content =~ m/^($YAML::PP::Parser::RE_OCT)/) {
        my $oct = 0 . substr($content, 2);
        $value = oct $oct;
    }
    elsif ($content eq 'true' or $content eq 'false') {
        $value = $self->truefalse->($content);
    }
    else {
        $value = $content;
        $value =~ s/\\n/\n/g;
        $value =~ s/\\t/\t/g;
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
