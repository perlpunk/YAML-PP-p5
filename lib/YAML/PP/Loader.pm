use strict;
use warnings;
package YAML::PP::Loader;

use YAML::PP::Parser;

use constant DEBUG => ($ENV{YAML_PP_LOAD_DEBUG} or $ENV{YAML_PP_LOAD_TRACE}) ? 1 : 0;
use constant TRACE => $ENV{YAML_PP_LOAD_TRACE} ? 1 : 0;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
    }, $class;
    return $self;
}

sub data { return $_[0]->{data} }
sub refs { return $_[0]->{refs} }

sub Load {
    my ($self, $yaml) = @_;
    my @documents;
    my $parser = YAML::PP::Parser->new(
        receiver => sub { $self->event(@_, \@documents) },
    );
    $self->{data} = undef;
    $self->{refs} = [];
    $parser->parse($yaml);
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
            $self->{data} = undef;
            $self->{refs} = [ \$self->{data} ];
        }
        elsif ($type eq 'MAP' or $type eq 'SEQ') {
            my $data = $type eq 'MAP' ? {} : [];

            my $ref = $refs->[-1];
            if (not defined $$ref) {
                $$ref = $data;
                return;
            }

            if (ref $$ref eq 'ARRAY') {
                push @$$ref, $data;
                push @$refs, \$data;
                return;
            }

            die "Unexpected";
        }
    }
    elsif ($name eq 'END') {
        if ($info->{type} eq 'DOC') {
            push @$docs, $self->{data};
        }
        pop @$refs if @$refs;
    }
    elsif ($name eq 'VALUE') {
        my $value = $self->render_value($info);

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
    if ($content =~ m/^([1-9]\d*|\d+\.\d+)$/){
        $value = 0 + $1;
    }
    elsif ($content eq 'true') {
        require JSON::PP;
        $value = JSON::PP::true();
    }
    elsif ($content eq 'false') {
        require JSON::PP;
        $value = JSON::PP::false();
    }
    else {
        $value = $content;
        $value =~ s/\\n/\n/g;
        $value =~ s/\\t/\t/g;
    }
    return $value;
}

1;
