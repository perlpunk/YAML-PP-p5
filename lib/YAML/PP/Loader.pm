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
    my $self = bless {
        boolean => $bool,
        truefalse => $truefalse,
    }, $class;
    return $self;
}

sub data { return $_[0]->{data} }
sub refs { return $_[0]->{refs} }
sub anchors { return $_[0]->{anchors} }
sub set_data { $_[0]->{data} = $_[1] }
sub set_refs { $_[0]->{refs} = $_[1] }
sub set_anchors { $_[0]->{anchors} = $_[1] }
sub boolean { return $_[0]->{boolean} }
sub truefalse { return $_[0]->{truefalse} }

sub Load {
    my ($self, $yaml) = @_;
    my @documents;
    my $parser = YAML::PP::Parser->new(
        receiver => sub { $self->event(@_, \@documents) },
    );
    $self->set_data(undef);
    $self->set_refs([]);
    $self->set_anchors({});
    $parser->parse($yaml);
    $self->set_data(undef);
    $self->set_refs([]);
    $self->set_anchors({});
    return wantarray ? @documents : $documents[0];
}

sub event {
    my ($self, $parser, $event, $docs) = @_;
    my ($name, $info) = @$event;
    DEBUG and warn "event($name)\n";

    my $refs = $self->refs;
    if ($name eq 'BEGIN') {

        my $type = $info->{type};
        if ($type eq 'DOC') {
            $self->set_data(undef);
            $self->set_refs([ \$self->{data} ]);
            $self->set_anchors({});
        }
        elsif ($type eq 'MAP' or $type eq 'SEQ') {
            my $data = $type eq 'MAP' ? {} : [];

            my $ref = $refs->[-1];
            if (not defined $$ref) {
                $$ref = $data;
            }
            elsif (ref $$ref eq 'ARRAY') {
                push @$$ref, $data;
                push @$refs, \$data;
            }
            else {
                die "Unexpected";
            }
            if (defined(my $anchor = $info->{anchor})) {
                $self->anchors->{ $anchor } = \$data;
            }
        }
    }
    elsif ($name eq 'END') {
        if ($info->{type} eq 'DOC') {
            push @$docs, $self->data;
        }
        pop @$refs if @$refs;
    }
    elsif ($name eq 'VALUE' or $name eq 'ALIAS') {
        my $value;
        if ($name eq 'VALUE') {
            $value = $self->render_value($info);
        }
        else {
            my $name = $info->{content};
            if (my $anchor = $self->anchors->{ $name }) {
                $value = $$anchor;
            }
        }

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
