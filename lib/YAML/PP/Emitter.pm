use strict;
use warnings;
package YAML::PP::Emitter;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Common qw/
    YAML_PLAIN_SCALAR_STYLE YAML_SINGLE_QUOTED_SCALAR_STYLE
    YAML_DOUBLE_QUOTED_SCALAR_STYLE YAML_QUOTED_SCALAR_STYLE
    YAML_LITERAL_SCALAR_STYLE YAML_FOLDED_SCALAR_STYLE
    YAML_FLOW_SEQUENCE_STYLE YAML_FLOW_MAPPING_STYLE
/;

use constant DEBUG => $ENV{YAML_PP_EMIT_DEBUG} ? 1 : 0;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        indent => $args{indent} || 2,
    }, $class;
    return $self;
}

sub event_stack { return $_[0]->{event_stack} }
sub set_event_stack { $_[0]->{event_stack} = $_[1] }
sub indent { return $_[0]->{indent} }
sub set_indent { $_[0]->{indent} = $_[1] }
sub writer { $_[0]->{writer} }
sub set_writer { $_[0]->{writer} = $_[1] }

sub init {
    my ($self) = @_;
}

sub mapping_start_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ mapping_start_event\n";
    my ($self, $info) = @_;
    my $stack = $self->event_stack;
    my $last = $stack->[-1];
    my $indent = $last->{indent};
    my $new_indent = $indent;

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
    my $append = $last->{append};

    my $new_append = 0;
    my $yaml = '';
    if ($last->{type} eq 'DOC') {
        if ($append and $props) {
            $yaml .= " $props";
        }
        elsif ($props) {
            $yaml .= "$props";
        }
        if ($append or $props) {
            $yaml .= "\n";
        }
    }
    elsif ($last->{type} eq 'MAPVALUE') {
        if ($props) {
            $yaml .= " $props";
        }
        $yaml .= "\n";
        $new_indent .= ' ' x $self->indent;
    }
    else {
        $new_indent .= ' ' x $self->indent;
        if ($append) {
            $yaml .= " ";
        }
        else {
            $yaml .= $indent;
        }
        if ($last->{type} eq 'SEQ') {
            $yaml .= '-';
        }
        elsif ($last->{type} eq 'MAP') {
            $yaml .= "?";
            $last->{type} = 'COMPLEX';
        }
        elsif ($last->{type} eq 'COMPLEX') {
            $yaml .= ":";
            $last->{type} = 'COMPLEXVALUE';
        }
        else {
            die "Unexpected";
        }
        if ($props) {
            $yaml .= " $props\n";
        }
        else {
            $new_append = 1;
        }
    }
    $self->writer->write($yaml);
    my $new_info = { index => 0, indent => $new_indent, info => $info, append => $new_append };
    if (($info->{style} || '') eq YAML_FLOW_MAPPING_STYLE) {
#        $new_info->{type} = 'FLOWMAP';
        $new_info->{type} = 'MAP';
    }
    else {
        $new_info->{type} = 'MAP';
    }
    push @{ $stack }, $new_info;
    $last->{index}++;
    $last->{append} = 0;
}

sub mapping_end_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ mapping_end_event\n";
    my ($self, $info) = @_;
    my $stack = $self->event_stack;

    my $last = pop @{ $stack };
    if ($last->{index} == 0) {
        my $indent = $last->{indent};
        my $zero_indent = $last->{zero_indent};
        if ($last->{zero_indent}) {
            $indent .= ' ' x $self->indent;
        }
        if ($last->{append}) {
            $self->writer->write(" {}\n");
        }
        else {
            $self->writer->write("$indent\{}\n");
        }
    }
    $last = $stack->[-1];
    if ($last->{type} eq 'SEQ') {
    }
    elsif ($last->{type} eq 'MAP') {
        $last->{type} = 'MAPVALUE';
    }
    elsif ($last->{type} eq 'MAPVALUE') {
        $last->{type} = 'MAP';
    }
}

sub sequence_start_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ sequence_start_event\n";
    my ($self, $info) = @_;
    my $stack = $self->event_stack;
    my $last = $stack->[-1];
    my $indent = $last->{indent};
    my $new_indent = $indent;
    my $yaml = '';

    my $props = '';
    my $anchor = $info->{anchor};
    my $tag = $info->{tag};
    if (defined $anchor) {
        $anchor = "&$anchor";
    }
    if (defined $tag) {
        $tag = $self->emit_tag('seq', $tag);
    }
    $props = join ' ', grep defined, ($anchor, $tag);

    my $new_append = 0;
    my $zero_indent = 0;
    my $append = $last->{append};
    if ($last->{type} eq 'DOC') {
        if ($append and $props) {
            $yaml .= " $props";
        }
        elsif ($props) {
            $yaml .= "$props";
        }
        if ($append or $props) {
            $yaml .= "\n";
        }
    }
    else {
        if ($last->{type} eq 'MAPVALUE') {
            $zero_indent = 1;
        }
        else {
            if ($append) {
                $yaml .= ' ';
            }
            else {
                $yaml .= $indent;
            }
            $new_indent .= ' ' x $self->indent;
            unless ($props) {
                $new_append = 1;
            }
            if ($last->{type} eq 'SEQ') {
                $yaml .= "-";
            }
            elsif ($last->{type} eq 'MAP') {
                $yaml .= "?";
                $last->{type} = 'COMPLEX';
            }
            elsif ($last->{type} eq 'COMPLEXVALUE') {
                $yaml .= ":";
            }
        }
        if ($props) {
            $yaml .= " $props";
        }
        if (not $new_append) {
            $yaml .= "\n";
        }
    }
    $self->writer->write($yaml);
    $last->{index}++;
    $last->{append} = 0;
    my $new_info = {
        index => 0,
        indent => $new_indent,
        info => $info,
        append => $new_append,
        zero_indent => $zero_indent,
    };
    if (($info->{style} || '') eq YAML_FLOW_SEQUENCE_STYLE) {
        $new_info->{type} = 'FLOWSEQ';
    }
    else {
        $new_info->{type} = 'SEQ';
    }
    push @{ $stack }, $new_info;
}

sub sequence_end_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ sequence_end_event\n";
    my ($self, $info) = @_;
    my $stack = $self->event_stack;

    my $last = pop @{ $stack };
    if ($last->{index} == 0) {
        my $indent = $last->{indent};
        my $zero_indent = $last->{zero_indent};
        if ($last->{zero_indent}) {
            $indent .= ' ' x $self->indent;
        }
        if ($last->{append}) {
            $self->writer->write(" []\n");
        }
        else {
            $self->writer->write("$indent\[]\n");
        }
    }
    $last = $stack->[-1];
    if ($last->{type} eq 'MAP') {
        $last->{type} = 'MAPVALUE';
    }
    elsif ($last->{type} eq 'MAPVALUE') {
        $last->{type} = 'MAP';
    }
    elsif ($last->{type} eq 'COMPLEX') {
        $last->{type} = 'COMPLEXVALUE';
    }
    elsif ($last->{type} eq 'COMPLEXVALUE') {
        $last->{type} = 'MAP';
    }
    elsif ($last->{type} eq 'SEQ') {
    }
}

my %forbidden_first = (qw/
    ! 1 & 1 * 1 { 1 } 1 [ 1 ] 1 | 1 > 1 @ 1 ` 1 " 1 ' 1
/, '#' => 1, ',' => 1, " " => 1);

my %control = (
    "\x00" => '\0',
    "\x01" => '\x01',
    "\x02" => '\x02',
    "\x03" => '\x03',
    "\x04" => '\x04',
    "\x05" => '\x05',
    "\x06" => '\x06',
    "\x07" => '\a',
    "\x08" => '\b',
    "\x0b" => '\v',
    "\x0c" => '\f',
    "\x0e" => '\x0e',
    "\x0f" => '\x0f',
    "\x10" => '\x10',
    "\x11" => '\x11',
    "\x12" => '\x12',
    "\x13" => '\x13',
    "\x14" => '\x14',
    "\x15" => '\x15',
    "\x16" => '\x16',
    "\x17" => '\x17',
    "\x18" => '\x18',
    "\x19" => '\x19',
    "\x1a" => '\x1a',
    "\x1b" => '\e',
    "\x1c" => '\x1c',
    "\x1d" => '\x1d',
    "\x1e" => '\x1e',
    "\x1f" => '\x1f',
    "\x{2029}" => '\P',
    "\x{2028}" => '\L',
    "\x85" => '\N',
    "\xa0" => '\_',
);

my $control_re = '\x00-\x08\x0b\x0c\x0e-\x1f\x{2029}\x{2028}\x85\xa0';
my %to_escape = (
    "\n" => '\n',
    "\t" => '\t',
    "\r" => '\r',
    '\\' => '\\\\',
    '"' => '\\"',
    %control,
);
my $escape_re = $control_re . '\n\t\r';
my $escape_re_without_lb = $control_re . '\t\r';


sub scalar_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ scalar_event\n";
    my ($self, $info) = @_;
    my $stack = $self->event_stack;
    my $last = $stack->[-1];
    my $indent = $last->{indent};
    my $value = $info->{value};

    my $props = '';
    my $anchor = $info->{anchor};
    my $tag = $info->{tag};
    if (defined $anchor) {
        $anchor = "&$anchor";
    }
    if (defined $tag) {
        $tag = $self->emit_tag('scalar', $tag);
    }
    $props = join ' ', grep defined, ($anchor, $tag);

    my $append = $last->{append};

    my $style = $info->{style};
    DEBUG and local $Data::Dumper::Useqq = 1;
    $value = '' unless defined $value;
    if (not $style and $value eq '') {
        $style = YAML_SINGLE_QUOTED_SCALAR_STYLE;
    }
    $style ||= YAML_PLAIN_SCALAR_STYLE;
    if ($style eq YAML_QUOTED_SCALAR_STYLE) {
        $style = YAML_SINGLE_QUOTED_SCALAR_STYLE;
    }

    my $first = substr($value, 0, 1);
    # no control characters anywhere
    if ($style ne YAML_DOUBLE_QUOTED_SCALAR_STYLE and $value =~ m/[$control_re]/) {
        $style = YAML_DOUBLE_QUOTED_SCALAR_STYLE;
    }
    elsif ($style eq YAML_SINGLE_QUOTED_SCALAR_STYLE) {
        if ($value =~ m/ \n/ or $value =~ m/\n / or $value =~ m/^\n/ or $value =~ m/\n$/) {
            $style = YAML_DOUBLE_QUOTED_SCALAR_STYLE;
        }
        elsif ($value eq "\n") {
            $style = YAML_DOUBLE_QUOTED_SCALAR_STYLE;
        }
    }
    elsif ($style eq YAML_LITERAL_SCALAR_STYLE or $style eq YAML_FOLDED_SCALAR_STYLE) {
    }
    elsif ($style eq YAML_PLAIN_SCALAR_STYLE) {
        if ($value =~ m/[$escape_re_without_lb]/) {
            $style = YAML_DOUBLE_QUOTED_SCALAR_STYLE;
        }
        elsif ($value eq "\n") {
            $style = YAML_DOUBLE_QUOTED_SCALAR_STYLE;
        }
        elsif ($value =~ m/\n/) {
            $style = YAML_LITERAL_SCALAR_STYLE;
        }
        elsif ($forbidden_first{ $first }) {
            $style = YAML_SINGLE_QUOTED_SCALAR_STYLE;
        }
        elsif (substr($value, 0, 2) =~ m/^([:?-] )/) {
            $style = YAML_SINGLE_QUOTED_SCALAR_STYLE;
        }
        elsif ($value =~ m/: /) {
            $style = YAML_SINGLE_QUOTED_SCALAR_STYLE;
        }
        elsif ($value =~ m/ #/) {
            $style = YAML_SINGLE_QUOTED_SCALAR_STYLE;
        }
        elsif ($value =~ m/[: \t]\z/) {
            $style = YAML_SINGLE_QUOTED_SCALAR_STYLE;
        }
        else {
            $style = YAML_PLAIN_SCALAR_STYLE;
        }
    }

    if (($style eq YAML_LITERAL_SCALAR_STYLE or $style eq YAML_FOLDED_SCALAR_STYLE) and $value eq '') {
        $style = YAML_DOUBLE_QUOTED_SCALAR_STYLE;
    }
    if ($style eq YAML_PLAIN_SCALAR_STYLE) {
        $value =~ s/\n/\n\n/g;
    }
    elsif ($style eq YAML_SINGLE_QUOTED_SCALAR_STYLE) {
        my $new_indent = $last->{indent} . (' ' x $self->indent);
        $value =~ s/(\n+)/"\n" x (1 + (length $1))/eg;
        my @lines = split m/\n/, $value, -1;
        if (@lines > 1) {
            for my $line (@lines[1 .. $#lines]) {
                $line = $new_indent . $line
                    if length $line;
            }
        }
        $value = join "\n", @lines;
        $value =~ s/'/''/g;
        $value = "'" . $value . "'";
    }
    elsif ($style eq YAML_LITERAL_SCALAR_STYLE) {
        DEBUG and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);
        my $indicators = '';
        if ($value =~ m/\A\n* +/) {
            $indicators .= $self->indent;
        }
        if ($value !~ m/\n\z/) {
            $indicators .= '-';
            $value .= "\n";
        }
        elsif ($value =~ m/(\n|\A)\n\z/) {
            $indicators .= '+';
        }
        $value =~ s/^(?=.)/$indent  /gm;
        $value = "|$indicators\n$value";
    }
    elsif ($style eq YAML_FOLDED_SCALAR_STYLE) {
        DEBUG and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$value], ['value']);
        my @lines = split /\n/, $value, -1;
        DEBUG and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@lines], ['lines']);
        my $eol = 0;
        my $indicators = '';
        if ($value =~ m/\A\n* +/) {
            $indicators .= $self->indent;
        }
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
        $value =~ s/([$escape_re"\\])/$to_escape{ $1 }/g;
        $value = '"' . $value . '"';
    }

    DEBUG and warn __PACKAGE__.':'.__LINE__.": (@$stack)\n";
    my $yaml = '';
    my $pvalue = $props;
    if ($props and length $value) {
        $pvalue .= " $value";
    }
    elsif (length $value) {
        $pvalue .= $value;
    }
    my $multiline = ($style eq YAML_LITERAL_SCALAR_STYLE or $style eq YAML_FOLDED_SCALAR_STYLE);
    if ($last->{type} eq 'MAP') {

        if ($props and not length $value) {
            $pvalue .= ' ';
        }
        my $new_event = 'MAPVALUE';
        if ($multiline) {
            # oops, a complex key
            if (not $append) {
                $yaml .= $indent;
            }
            else {
                $yaml .= " ";
            }
            $yaml .= "?";
            $append = 1;
            $new_event = 'COMPLEXVALUE';
        }
        if ($append) {
            $yaml .= " ";
        }
        else {
            $yaml .= $indent;
        }
        $yaml .= $pvalue;
        if (not $multiline) {
            $yaml .= ":";
        }
        $last->{type} = $new_event;
    }
    elsif ($last->{type} eq 'COMPLEXVALUE') {
        if ($append) {
            $yaml .= " ";
        }
        else {
            $yaml .= $indent;
        }
        if (length $pvalue) {
            $yaml .= ": $pvalue";
        }
        else {
            $yaml .= ":";
        }
        if (not $multiline) {
            $yaml .= "\n";
        }
        $last->{type} = 'MAP';
    }
    else {
        if ($last->{type} eq 'MAPVALUE') {
            if (length $pvalue) {
                $yaml .= " $pvalue";
            }
            $last->{type} = 'MAP';
        }
        elsif ($last->{type} eq 'SEQ') {
            if (not $append) {
                $yaml .= $indent;
            }
            else {
                $yaml .= " ";
            }
            $yaml .= "-";
            if (length $pvalue) {
                $yaml .= " $pvalue";
            }
        }
        elsif ($last->{type} eq 'DOC') {
            if (length $pvalue) {
                if ($append) {
                    $yaml .= " ";
                }
                $yaml .= $pvalue;
            }
        }
        else {
#            warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$last], ['last']);
            die "Unexpected";
        }
        if (not $multiline) {
            $yaml .= "\n";
        }
    }
    $last->{index}++;
    $last->{append} = 0;
    $self->writer->write($yaml);
}

sub alias_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ alias_event\n";
    my ($self, $info) = @_;
    my $stack = $self->event_stack;
    my $last = $stack->[-1];
    $last->{index}++;
    my $append = $last->{append};
    my $indent = $last->{indent};

    my $alias = '*' . $info->{value};

    if ($last->{type} eq 'MAP') {
        my $yaml = '';
        if ($append) {
            $yaml .= " ";
        }
        else {
            $yaml .= $indent;
        }
        $self->writer->write("$yaml$alias :");
        $last->{type} = 'MAPVALUE';
    }
    elsif ($last->{type} eq 'MAPVALUE') {
        $self->writer->write(" $alias\n");
        $last->{type} = 'MAP';
    }
    elsif ($last->{type} eq 'SEQ') {
        my $yaml = '';
        if (not $append) {
            $yaml .= $indent;
        }
        else {
            $yaml .= " ";
        }
        $yaml .= "- $alias\n";
        $self->writer->write($yaml);
    }
    elsif ($last->{type} eq 'DOC') {
        # TODO an alias at document level isn't actually valid
        $self->writer->write("$alias\n");
    }
    else {
        $self->writer->write("$indent: $alias\n");
        $last->{type} = 'MAP';
    }
    $last->{append} = 0;
}

sub document_start_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ document_start_event\n";
    my ($self, $info) = @_;
    my $new_append = 0;
    if ($info->{implicit}) {
        $new_append = 0;
    }
    else {
        $new_append = 1;
        $self->writer->write("---");
    }
    $self->set_event_stack([
        { type => 'DOC', index => 0, indent => '', info => $info, append => $new_append }
    ]);
}

sub document_end_event {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": +++ document_end_event\n";
    my ($self, $info) = @_;
    $self->set_event_stack([]);
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

sub finish {
    my ($self) = @_;
    $self->writer->finish;
}

1;
