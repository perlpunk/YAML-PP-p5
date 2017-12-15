# ABSTRACT: YAML Parser
use strict;
use warnings;
package YAML::PP::Parser;

our $VERSION = '0.000'; # VERSION

use constant TRACE => $ENV{YAML_PP_TRACE};
use constant DEBUG => $ENV{YAML_PP_DEBUG} || $ENV{YAML_PP_TRACE};

use YAML::PP::Render;
use YAML::PP::Lexer;
use YAML::PP::Grammar qw/ $GRAMMAR /;
use YAML::PP::Exception;
use YAML::PP::Reader;
use Carp qw/ croak /;


sub new {
    my ($class, %args) = @_;
    my $reader = delete $args{reader} || YAML::PP::Reader->new;
    my $self = bless {
        lexer => YAML::PP::Lexer->new(
            reader => $reader,
        ),
    }, $class;
    my $receiver = delete $args{receiver};
    if ($receiver) {
        $self->set_receiver($receiver);
    }
    return $self;
}
sub receiver { return $_[0]->{receiver} }
sub set_receiver {
    my ($self, $receiver) = @_;
    my $callback;
    if (ref $receiver eq 'CODE') {
        $callback = $receiver;
    }
    else {
        $callback = sub {
            my ($self, $event, $info) = @_;
            return $receiver->$event($info);
        };
    }
    $self->{callback} = $callback;
    $self->{receiver} = $receiver;
}
sub reader { return $_[0]->{reader} }
sub lexer { return $_[0]->{lexer} }
sub callback { return $_[0]->{callback} }
sub set_callback { $_[0]->{callback} = $_[1] }
sub level { return $#{ $_[0]->{offset} } }
sub offset { return $_[0]->{offset} }
sub set_offset { $_[0]->{offset} = $_[1] }
sub events { return $_[0]->{events} }
sub set_events { $_[0]->{events} = $_[1] }
sub new_node { return $_[0]->{new_node} }
sub set_new_node { $_[0]->{new_node} = $_[1] }
sub tagmap { return $_[0]->{tagmap} }
sub set_tagmap { $_[0]->{tagmap} = $_[1] }
sub tokens { return $_[0]->{tokens} }
sub set_tokens { $_[0]->{tokens} = $_[1] }
sub event_stack { return $_[0]->{event_stack} }
sub set_event_stack { $_[0]->{event_stack} = $_[1] }

sub rule { return $_[0]->{rule} }
sub set_rule {
    my ($self, $name) = @_;
    DEBUG and $self->info("set_rule($name)");
    $self->{rule} = $name;
}

sub init {
    my ($self) = @_;
    $self->set_offset([]);
    $self->set_events([]);
    $self->set_new_node(undef);
    $self->set_tagmap({
        '!!' => "tag:yaml.org,2002:",
    });
    $self->set_tokens([]);
    $self->set_rule(undef);
    $self->set_event_stack([]);
    $self->lexer->init;
}

sub parse {
    my ($self, $yaml) = @_;
    my $reader = $self->lexer->reader;
    if (defined $yaml) {
        $reader->set_input($yaml);
    }
    $self->init;
    $self->lexer->init;
    eval {
        $self->parse_stream;
    };
    if (my $error = $@) {
        if (ref $error) {
            croak "$error\n ";
        }
        croak $error;
    }

    DEBUG and $self->highlight_yaml;
    TRACE and $self->debug_tokens;
}

sub parse_stream {
    TRACE and warn "=== parse_stream()\n";
    my ($self) = @_;
    $self->start_stream;

    TRACE and $self->debug_yaml;

    my $implicit = 0;
    while (1) {
        my $next_tokens = $self->lexer->fetch_next_tokens(0);
        last unless @$next_tokens;
        my ($start, $start_line) = $self->parse_document_head($implicit);

        if ( $self->parse_empty($next_tokens) ) {
        }
        if (not @$next_tokens and not $start) {
            last;
        }

        $self->start_document(not $start);

        my $new_type = 'FULLNODE';
        $self->set_rule( $new_type );
        $self->set_new_node($new_type);

        $self->parse_document();

        if (@$next_tokens and $next_tokens->[0]->{name} eq 'DOC_END') {
            $implicit = 0;
            push @{ $self->tokens }, shift @$next_tokens;
            if (@$next_tokens and $next_tokens->[0]->{name} eq 'EOL') {
                push @{ $self->tokens }, shift @$next_tokens;
            }
            else {
                $self->exception("Expected EOL");
            }
        }
        else {
            $implicit = 1;
        }

        $self->end_doc($implicit);

    }

    $self->end_stream;
}

sub parse_document_start {
    TRACE and warn "=== parse_document_start()\n";
    my ($self) = @_;

    my ($start, $start_line) = (0, 0);
    my $next_tokens = $self->lexer->next_tokens;
    if (@$next_tokens and $next_tokens->[0]->{name} eq 'DOC_START') {
        push @{ $self->tokens }, shift @$next_tokens;
        $start = 1;
        if ($next_tokens->[0]->{name} eq 'EOL') {
            push @{ $self->tokens }, shift @$next_tokens;
            $self->lexer->fetch_next_tokens(0);
        }
        elsif ($next_tokens->[0]->{name} eq 'WS') {
            push @{ $self->tokens }, shift @$next_tokens;
            $start_line = 1;
        }
        else {
            $self->debug_yaml;
            $self->exception("Unexpected content after ---");
        }
    }
    return ($start, $start_line);
}

sub parse_document_head {
    TRACE and warn "=== parse_document_head()\n";
    my ($self, $exp_start) = @_;
    my $tokens = $self->tokens;
    while (1) {
        my $next_tokens = $self->lexer->next_tokens;
        last unless @$next_tokens;
        if ($self->parse_empty($next_tokens)) {
            next;
        }
        if ($next_tokens->[0]->{name} eq 'YAML_DIRECTIVE') {
        }
        elsif ($next_tokens->[0]->{name} eq 'TAG_DIRECTIVE') {
            my ($name, $tag_alias, $tag_url) = split ' ', $next_tokens->[0]->{value};
            $self->tagmap->{ $tag_alias } = $tag_url;
        }
        elsif ($next_tokens->[0]->{name} eq 'RESERVED_DIRECTIVE') {
        }
        else {
            last;
        }
        if ($exp_start) {
            $self->exception("Expected ---");
        }
        $exp_start = 1;
        push @$tokens, shift @$next_tokens;
        push @$tokens, shift @$next_tokens;
        $self->lexer->fetch_next_tokens(0);
    }
    my ($start, $start_line) = $self->parse_document_start;
    if ($exp_start and not $start) {
        $self->exception("Expected ---");
    }
    return ($start, $start_line);
}

my %nodetypes = (
    MAPVALUE => 'NODETYPE_COMPLEX',
    MAP => 'NODETYPE_MAP',
    SEQ => 'NODETYPE_SEQ',
    SEQ0 => 'NODETYPE_SEQ',
    FLOWMAP => 'NODETYPE_FLOWMAP',
    FLOWMAPVALUE => 'NODETYPE_FLOWMAPVALUE',
    FLOWSEQ => 'NODETYPE_FLOWSEQ',
);

sub parse_document {
    TRACE and warn "=== parse_document()\n";
    my ($self) = @_;

    my $lexer = $self->lexer;
    my $next_tokens = $lexer->next_tokens;
    my $event_types = $self->events;
    my $stack = $self->event_stack;
    $lexer->fetch_next_tokens(0);
    LINE: while (1) {

        TRACE and $self->info("----------------------- LOOP");
        TRACE and $self->debug_events;

        unless (@$next_tokens) {
            return $self->end_document;
        }
        if ( $next_tokens->[0]->{name} eq 'EOL' ) {
            push @{ $self->tokens }, shift @$next_tokens;
            $lexer->fetch_next_tokens(0);
            next LINE;
        }

        my $end = $self->check_indent();
        if ($end) {
            return $self->end_document;
        }

        DEBUG and $self->info("----------------> parse_next_line");
        while (1) {
            unless ($self->new_node) {
                $self->set_rule( $nodetypes{ $event_types->[-1] } );
            }

            my $res = $self->parse_tokens();

#            if (@$stack) {
#                $self->process_events( $res );
#            }

            last if (not @$next_tokens or $next_tokens->[0]->{column} == 0);
        }
        unless (@$next_tokens) {
            $lexer->fetch_next_tokens(0);
        }
    }

    return;
}

sub check_indent {
    my ($self) = @_;

    my $next_tokens = $self->lexer->next_tokens;
    my $next_token = $next_tokens->[0];
    if ($next_token->{column} != 0) {
        return;
    }

    my $event_types = $self->events;
    my $tokens = $self->tokens;
    my $space = 0;

    if ($next_token->{name} eq 'INDENT') {
        $space = length $next_token->{value};
        push @$tokens, shift @$next_tokens;
        $next_token = $next_tokens->[0];
    }
    elsif ($next_token->{name} eq 'DOC_START') {
        return 1;
    }
    elsif ($next_token->{name} eq 'DOC_END') {
        return 1;
    }
    elsif ($self->level < 2 and not $self->new_node) {
        return 1;
    }
    if ($event_types->[-1] =~ m/^FLOW/) {
        return;
    }

    my $indent = $self->offset->[ -1 ];

    TRACE and $self->info("INDENT: space=$space indent=$indent");

    if ($space > $indent) {
        unless ($self->new_node) {
            $self->exception("Bad indendation in " . $self->events->[-1]);
        }
        return;
    }

    my $exp = $event_types->[-1];


    if ($self->new_node) {
        # unindented sequence starts
        my $seq_start = $next_token->{name} eq 'DASH';
        if ($space == $indent and $seq_start and $exp eq 'MAPVALUE') {
            return;
        }
        else {
            $self->scalar_event({ style => ':', value => undef });
        }
    }

    if ($space < $indent) {
        $exp = $self->remove_nodes($space);
    }

    if ($exp eq 'SEQ0' and $next_token->{name} ne 'DASH') {
        TRACE and $self->info("In unindented sequence");
        $self->end_sequence;
        $exp = $self->events->[-1];
    }

    if ($self->offset->[-1] != $space) {
        $self->exception("Expected $exp");
    }

    return;
}

sub end_document {
    my ($self) = @_;
    if ($self->lexer->flowcontext) {
        die "Unexpected end of flow context";
    }
    if ($self->new_node) {
        $self->scalar_event({ style => ':', value => undef });
    }
    $self->remove_nodes(-1);
}

my %next_event = (
    MAP => 'MAPVALUE',
    MAPVALUE => 'MAP',
    SEQ => 'SEQ',
    SEQ0 => 'SEQ0',
    DOC => 'DOC',
    STR => 'STR',
    FLOWSEQ => 'FLOWSEQ',
    FLOWMAP => 'FLOWMAPVALUE',
    FLOWMAPVALUE => 'FLOWMAP',
);

my %render_methods = (
    q/:/ => 'render_multi_val',
    q/"/ => 'render_quoted',
    q/'/ => 'render_quoted',
    q/>/ => 'render_block_scalar',
    q/|/ => 'render_block_scalar',
);

my %event_to_method = (
    MAP => 'mapping',
    FLOWMAP => 'mapping',
    SEQ => 'sequence',
    SEQ0 => 'sequence',
    FLOWSEQ => 'sequence',
    DOC => 'document',
    STR => 'stream',
    VAL => 'scalar',
    ALI => 'alias',
    MAPVALUE => 'mapping',
);

#sub process_events {
#    my ($self, $res) = @_;
#
#    my $event_stack = $self->event_stack;
#    return unless @$event_stack;
#
#    if (@$event_stack == 1 and $event_stack->[0]->[0] eq 'properties') {
#        return;
#    }
#
#    my $event_types = $self->events;
#    my $properties;
#    my @send_events;
#    for my $event (@$event_stack) {
#        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$event], ['event']);
#        my ($type, $info) = @$event;
#        if ($type eq 'properties') {
#            $properties = $info;
#        }
#        elsif ($type eq 'scalar') {
#            $info->{event_name} = 'scalar_event';
#            $event_types->[-1] = $next_event{ $event_types->[-1] };
#            push @send_events, $info;
#        }
#        elsif ($type eq 'begin') {
#            my $name = $info->{name};
#            $info->{event_name} = $event_to_method{ $name } . '_start_event';
#            push @{ $event_types }, $name;
#            push @{ $self->offset }, $info->{offset};
#            push @send_events, $info;
#        }
#        elsif ($type eq 'end') {
#            my $name = $info->{name};
#            $info->{event_name} = $event_to_method{ $name } . '_end_event';
#            $self->$type($name, $info);
#            push @send_events, $info;
#            if (@$event_types) {
#                $event_types->[-1] = $next_event{ $event_types->[-1] };
#            }
#        }
#        elsif ($type eq 'alias') {
#            if ($properties) {
#                $self->exception("Parse error: Alias not allowed in this context");
#            }
#            $info->{event_name} = 'alias_event';
#            $event_types->[-1] = $next_event{ $event_types->[-1] };
#            push @send_events, $info;
#        }
#    }
#    @$event_stack = ();
#    for my $info (@send_events) {
#        DEBUG and $self->debug_event( $info->{event_name} => $info );
#        $self->callback->($self, $info->{event_name}, $info);
#    }
#}

sub parse_tokens {
    my ($self) = @_;
    my $res = {};
    my $next_rule_name = $self->rule;
    DEBUG and $self->info("----------------> parse_tokens($next_rule_name)");
    my $next_rule = $GRAMMAR->{ $next_rule_name };

    TRACE and $self->debug_rules($next_rule);
    TRACE and $self->debug_yaml;
    DEBUG and $self->debug_next_line;

    my $tokens = $self->tokens;
    my $next_tokens = $self->lexer->next_tokens;
    $res->{offset} = $next_tokens->[0]->{column};
    RULE: while ($next_rule_name) {
        DEBUG and $self->info("RULE: $next_rule_name");

        unless (@$next_tokens) {
            $self->exception("No more tokens");
        }
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$next_tokens->[0]], ['next_token']);
        my $got = $next_tokens->[0]->{name};
        my $def = $next_rule->{ $got };
        if ($def) {
            if ($got eq 'END') {
                shift @$next_tokens;
            }
            else {
                push @$tokens, shift @$next_tokens;
            }
        }
        elsif ($def = $next_rule->{DEFAULT}) {
            $got = 'DEFAULT';
        }
        else {
            $self->expected(
                expected => [keys %$next_rule],
                got => $next_tokens->[0],
            );
        }

        DEBUG and $self->got("---got $got");
        if (my $sub = $def->{match}) {
            DEBUG and $self->info("CALLBACK $sub");
            $self->$sub($tokens->[-1]);
        }
        my $node = $def->{node};
        my $new = $node || $def->{new};
        if ($new) {
            $next_rule_name = $new;
            DEBUG and $self->got("NEW: $next_rule_name");
#            if ($node) {
#                $self->set_new_node($node);
#            }

            if ($def->{return}) {
                $self->set_rule($next_rule_name);
                return $res;
            }

            $next_rule = $GRAMMAR->{ $next_rule_name }
                or die "Unexpected rule $next_rule_name";
            next RULE;
        }
        elsif ($def->{return}) {
            $self->set_new_node(undef);
            return $res;
        }
        $next_rule_name .= " - $got"; # for debugging
        $next_rule = $def;

    }

    die "Unexpected";
}

sub end_sequence {
    my ($self) = @_;
    my $event_types = $self->events;
    pop @{ $event_types };
    pop @{ $self->offset };
    my $info = { event_name => 'sequence_end_event' };
    $self->callback->($self, $info->{event_name} => $info );
    $event_types->[-1] = $next_event{ $event_types->[-1] };
}

sub remove_nodes {
    my ($self, $space) = @_;
    my $offset = $self->offset;
    my $event_types = $self->events;

    my $exp = $self->events->[-1];
    while (@$offset) {
        if ($offset->[ -1 ] <= $space) {
            last;
        }
        if ($exp eq 'MAPVALUE') {
            $self->scalar_event({ style => ':', value => undef });
            $exp = 'MAP';
        }
        my $info = { name => $exp };
        $info->{event_name} = $event_to_method{ $exp } . '_end_event';
        pop @{ $event_types };
        pop @{ $offset };
        $self->callback->($self, $info->{event_name} => $info );
        $event_types->[-1] = $next_event{ $event_types->[-1] };
        $exp = $event_types->[-1];
    }
    return $exp;
}

sub parse_empty {
    TRACE and warn "=== parse_empty()\n";
    my ($self, $next_tokens) = @_;
    my $empty = 0;
    while ( @$next_tokens and ($next_tokens->[0]->{name} eq 'EOL' )) {
        push @{ $self->tokens }, shift @$next_tokens;
        $self->lexer->fetch_next_tokens(0);
        $empty++;
    }
    return $empty;
}

sub start_stream {
    my ($self) = @_;
    push @{ $self->events }, 'STR';
    push @{ $self->offset }, -1;
    $self->callback->($self, 'stream_start_event', {});
}

sub start_document {
    my ($self, $implicit) = @_;
    push @{ $self->events }, 'DOC';
    push @{ $self->offset }, -1;
    $self->callback->($self, 'document_start_event', { implicit => $implicit });
}

sub start_sequence {
    my ($self, $offset) = @_;
    my $offsets = $self->offset;
    if ($offsets->[-1] == $offset) {
        push @{ $self->events }, 'SEQ0';
    }
    else {
        push @{ $self->events }, 'SEQ';
    }
    push @{ $offsets }, $offset;
    my $event_stack = $self->event_stack;
    my $info = {};
    if (@$event_stack and $event_stack->[-1]->[0] eq 'properties') {
        my $properties = pop @$event_stack;
        $self->node_properties($properties->[1], $info);
    }
    $self->callback->($self, 'sequence_start_event', $info);
}

sub start_flow_sequence {
    my ($self, $offset) = @_;
    my $offsets = $self->offset;
    push @{ $self->events }, 'FLOWSEQ';
    push @{ $offsets }, $offset;
    my $event_stack = $self->event_stack;
    my $info = { style => 'flow' };
    if (@$event_stack and $event_stack->[-1]->[0] eq 'properties') {
        $self->fetch_inline_properties($event_stack, $info);
    }
    $self->callback->($self, 'sequence_start_event', $info);
}

sub start_flow_mapping {
    my ($self, $offset) = @_;
    my $offsets = $self->offset;
    push @{ $self->events }, 'FLOWMAP';
    push @{ $offsets }, $offset;
    my $event_stack = $self->event_stack;
    my $info = { style => 'flow' };
    if (@$event_stack and $event_stack->[-1]->[0] eq 'properties') {
        $self->fetch_inline_properties($event_stack, $info);
    }
    $self->callback->($self, 'mapping_start_event', $info);
}

sub end_flow_sequence {
    my ($self) = @_;
    my $event_types = $self->events;
    pop @{ $event_types };
    pop @{ $self->offset };
    my $info = { event_name => 'sequence_end_event' };
    $self->callback->($self, $info->{event_name}, $info);
    $event_types->[-1] = $next_event{ $event_types->[-1] };
}

sub end_flow_mapping {
    my ($self) = @_;
    my $event_types = $self->events;
    pop @{ $event_types };
    pop @{ $self->offset };
    my $info = { event_name => 'mapping_end_event' };
    $self->callback->($self, $info->{event_name}, $info);
    $event_types->[-1] = $next_event{ $event_types->[-1] };
}

sub start_mapping {
    my ($self, $offset) = @_;
    my $offsets = $self->offset;
    push @{ $self->events }, 'MAP';
    push @{ $offsets }, $offset;
    my $event_stack = $self->event_stack;
    my $info = {};
    if (@$event_stack and $event_stack->[-1]->[0] eq 'properties') {
        my $properties = pop @$event_stack;
        $self->node_properties($properties->[1], $info);
    }
    $self->callback->($self, 'mapping_start_event', $info);
}

sub end_doc {
    my ($self, $implicit) = @_;
    my $last = pop @{ $self->events };
    $self->exception("Unexpected event type $last") unless $last eq 'DOC';
    pop @{ $self->offset };
    $self->set_tagmap({ '!!' => "tag:yaml.org,2002:" });
    $self->callback->($self, 'document_end_event', { implicit => $implicit });
}

sub end_stream {
    my ($self) = @_;
    my $last = pop @{ $self->events };
    $self->exception("Unexpected event type $last") unless $last eq 'STR';
    pop @{ $self->offset };
    $self->callback->($self, 'stream_end_event', { });
}

sub fetch_inline_properties {
    my ($self, $stack, $info) = @_;
    my $properties = $stack->[-1];

    $properties = $properties->[1];
    my $property_offset;
    if ($properties) {
        for my $p (@{ $properties->{inline} }) {
            my $type = $p->{type};
            if (exists $info->{ $type }) {
                $self->exception("A node can only have one $type");
            }
            $info->{ $type } = $p->{value};
            unless (defined $property_offset) {
                $property_offset = $p->{offset};
                $info->{offset} = $p->{offset};
            }
        }
        delete $properties->{inline};
        undef $properties unless $properties->{newline};
    }

    unless ($properties) {
        pop @$stack;
    }
}

sub node_properties {
    my ($self, $properties, $info) = @_;
    if ($properties) {
        for my $p (@{ $properties->{newline} }) {
            my $type = $p->{type};
            if (exists $info->{ $type }) {
                $self->exception("A node can only have one $type");
            }
            $info->{ $type } = $p->{value};
        }
        undef $properties;
    }
}

sub scalar_event {
    my ($self, $info) = @_;
    my $event_types = $self->events;
    my $event_stack = $self->event_stack;
    if (@$event_stack and $event_stack->[-1]->[0] eq 'properties') {
        my $properties = pop @$event_stack;
        $properties = $self->node_properties($properties->[1], $info);
    }
    my $method = $render_methods{ $info->{style} };
    YAML::PP::Render->$method( $info );

    $self->callback->($self, 'scalar_event', $info);
    $self->set_new_node(undef);
    $event_types->[-1] = $next_event{ $event_types->[-1] };
}

sub alias_event {
    my ($self, $info) = @_;
    my $event_stack = $self->event_stack;
    if (@$event_stack and $event_stack->[-1]->[0] eq 'properties') {
        $self->exception("Parse error: Alias not allowed in this context");
    }
    my $event_types = $self->events;
    $self->callback->($self, 'alias_event', $info);
    $self->set_new_node(undef);
    $event_types->[-1] = $next_event{ $event_types->[-1] };
}

sub end {
    my ($self, $event, $info) = @_;

    my $event_types = $self->events;
    pop @{ $self->offset };

    my $last = pop @{ $event_types };
    if ($last ne $event) {
        die "end($event): Unexpected event '$last', expected $event";
    }

    return unless @$event_types;
}

sub event_to_test_suite {
    my ($self, $event) = @_;
    if (ref $event) {
        my ($ev, $info) = @$event;
        if ($event_to_method{ $ev }) {
            $ev = $event_to_method{ $ev } . "_event";
        }
        my $string;
        my $content = $info->{value};

        my $properties = '';
        $properties .= " &$info->{anchor}" if defined $info->{anchor};
        $properties .= " <$info->{tag}>" if defined $info->{tag};

        if ($ev eq 'document_start_event') {
            $string = "+DOC";
            $string .= " ---" unless $info->{implicit};
        }
        elsif ($ev eq 'document_end_event') {
            $string = "-DOC";
            $string .= " ..." unless $info->{implicit};
        }
        elsif ($ev eq 'stream_start_event') {
            $string = "+STR";
        }
        elsif ($ev eq 'stream_end_event') {
            $string = "-STR";
        }
        elsif ($ev eq 'mapping_start_event') {
            $string = "+MAP";
            $string .= $properties;
            if (0) {
                # doesn't match yaml-test-suite format
                if ($info->{style} and $info->{style} eq 'flow') {
                    $string .= " {}";
                }
            }
        }
        elsif ($ev eq 'sequence_start_event') {
            $string = "+SEQ";
            $string .= $properties;
            if (0) {
                # doesn't match yaml-test-suite format
                if ($info->{style} and $info->{style} eq 'flow') {
                    $string .= " []";
                }
            }
        }
        elsif ($ev eq 'mapping_end_event') {
            $string = "-MAP";
        }
        elsif ($ev eq 'sequence_end_event') {
            $string = "-SEQ";
        }
        elsif ($ev eq 'scalar_event') {
            $string = '=VAL';
            $string .= $properties;
            if (defined $content) {
                $content =~ s/\\/\\\\/g;
                $content =~ s/\t/\\t/g;
                $content =~ s/\r/\\r/g;
                $content =~ s/\n/\\n/g;
                $content =~ s/[\b]/\\b/g;
            }
            else {
                $content = '';
            }
            $string .= ' ' . $info->{style} . ($content // '');
        }
        elsif ($ev eq 'alias_event') {
            $string = "=ALI *$content";
        }
        return $string;
    }
}

sub debug_events {
    my ($self) = @_;
    $self->note("EVENTS: ("
        . join (' | ', @{ $_[0]->events }) . ')'
    );
    $self->debug_offset;
}

sub debug_offset {
    my ($self) = @_;
    $self->note(
        qq{OFFSET: (}
        . join (' | ', map { defined $_ ? sprintf "%-3d", $_ : '?' } @{ $_[0]->offset })
        . qq/) level=@{[ $_[0]->level ]}]}/
    );
}

sub debug_yaml {
    my ($self) = @_;
    my $line = $self->lexer->line;
    $self->note("LINE NUMBER: $line");
    my $next_tokens = $self->lexer->next_tokens;
    if (@$next_tokens) {
        $self->debug_tokens($next_tokens);
    }
}

sub debug_next_line {
    my ($self) = @_;
    my $next_line = $self->lexer->next_line // [];
    my $line = $next_line->[0] // '';
    $line =~ s/( +)$/'·' x length $1/e;
    $line =~ s/\t/▸/g;
    $self->note("NEXT LINE: >>$line<<");
}

sub note {
    my ($self, $msg) = @_;
    require Term::ANSIColor;
    warn Term::ANSIColor::colored(["yellow"], "============ $msg"), "\n";
}

sub info {
    my ($self, $msg) = @_;
    require Term::ANSIColor;
    warn Term::ANSIColor::colored(["cyan"], "============ $msg"), "\n";
}

sub got {
    my ($self, $msg) = @_;
    require Term::ANSIColor;
    warn Term::ANSIColor::colored(["green"], "============ $msg"), "\n";
}

sub debug_event {
    my ($self, $event, $info) = @_;
    my $str = $self->event_to_test_suite([$event, $info]);
    require Term::ANSIColor;
    warn Term::ANSIColor::colored(["magenta"], "============ $str"), "\n";
}

sub debug_rules {
    my ($self, $rules) = @_;
    local $Data::Dumper::Maxdepth = 2;
    $self->note("RULES:");
    for my $rule ($rules) {
        if (ref $rule eq 'ARRAY') {
            my $first = $rule->[0];
            if (ref $first eq 'SCALAR') {
                $self->info("-> $$first");
            }
            else {
                if (ref $first eq 'ARRAY') {
                    $first = $first->[0];
                }
                $self->info("TYPE $first");
            }
        }
        else {
            eval {
                my @keys = sort keys %$rule;
                $self->info("@keys");
            };
        }
    }
}

sub debug_tokens {
    my ($self, $tokens) = @_;
    $tokens ||= $self->tokens;
    require Term::ANSIColor;
    for my $token (@$tokens) {
        my $type = Term::ANSIColor::colored(["green"],
            sprintf "%-22s L %2d C %2d ",
                $token->{name}, $token->{line}, $token->{column} + 1
        );
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Terse = 1;
        require Data::Dumper;
        my $str = Data::Dumper->Dump([$token->{value}], ['str']);
        chomp $str;
        $str =~ s/(^.|.$)/Term::ANSIColor::colored(['blue'], $1)/ge;
        warn "$type$str\n";
    }

}

sub highlight_yaml {
    my ($self) = @_;
    require YAML::PP::Highlight;
    my $tokens = $self->tokens;
    my $highlighted = YAML::PP::Highlight->ansicolored($tokens);
    warn $highlighted;
}

sub exception {
    my ($self, $msg, %args) = @_;
    my $next = $self->lexer->next_tokens;
    my $line = @$next ? $next->[0]->{line} : $self->lexer->line;
    my $next_line = $self->lexer->next_line;
    my $caller = $args{caller} || [ caller(0) ];
    my $e = YAML::PP::Exception->new(
        line => $line,
        msg => $msg,
        next => $next,
        where => $caller->[1] . ' line ' . $caller->[2],
        yaml => $next_line,
    );
    croak $e;
}

sub expected {
    my ($self, %args) = @_;
    my $expected = $args{expected};
    @$expected = sort grep { m/^[A-Z_]+$/ } @$expected;
    my $got = $args{got}->{name};
    my @caller = caller(0);
    $self->exception("Expected (@$expected), but got $got",
        caller => \@caller,
    );
}

sub cb_tag {
    my ($self, $token) = @_;
    my $stack = $self->event_stack;
    if (! @$stack or $stack->[-1]->[0] ne 'properties') {
        push @$stack, [ properties => {} ];
    }
    my $last = $stack->[-1]->[1];
    my $tag = YAML::PP::Render::render_tag($token->{value}, $self->tagmap);
    $last->{inline} ||= [];
    push @{ $last->{inline} }, {
        type => 'tag',
        value => $tag,
        offset => $token->{column},
    };
}

sub cb_anchor {
    my ($self, $token) = @_;
    my $anchor = $token->{value};
    $anchor = substr($anchor, 1);
    my $stack = $self->event_stack;
    if (! @$stack or $stack->[-1]->[0] ne 'properties') {
        push @$stack, [ properties => {} ];
    }
    my $last = $stack->[-1]->[1];
    $last->{inline} ||= [];
    push @{ $last->{inline} }, {
        type => 'anchor',
        value => $anchor,
        offset => $token->{column},
    };
}

sub cb_property_eol {
    my ($self, $res) = @_;
    my $stack = $self->event_stack;
    my $last = $stack->[-1]->[1];
    my $inline = delete $last->{inline} or return;
    my $newline = $last->{newline} ||= [];
    push @$newline, @$inline;
}

sub cb_mapkey {
    my ($self, $token) = @_;
    my $stack = $self->event_stack;
    my $info = {
        style => ':',
        value => $token->{value},
        offset => $token->{column},
    };
    if (@$stack and $stack->[-1]->[0] eq 'properties') {
        $self->fetch_inline_properties($stack, $info);
    }
    push @{ $stack }, [ scalar => $info ];
}

sub cb_send_mapkey {
    my ($self, $res) = @_;
    my $last = pop @{ $self->event_stack };
    $self->scalar_event($last->[1]);
    $self->set_new_node(1);
}

sub cb_send_scalar {
    my ($self, $res) = @_;
    my $last = pop @{ $self->event_stack };
    $self->scalar_event($last->[1]);
}

sub cb_empty_mapkey {
    my ($self, $token) = @_;
    my $stack = $self->event_stack;
    my $info = {
        style => ':',
        value => undef,
        offset => $token->{column},
    };
    if (@$stack and $stack->[-1]->[0] eq 'properties') {
        $self->fetch_inline_properties($stack, $info);
    }
    $self->scalar_event($info);
    $self->set_new_node(1);
}

sub cb_send_alias {
    my ($self, $token) = @_;
    my $alias = substr($token->{value}, 1);
    $self->alias_event({ value => $alias });
    $self->set_new_node(1);
}

sub cb_send_alias_from_stack {
    my ($self, $token) = @_;
    my $last = pop @{ $self->event_stack };
    $self->alias_event($last->[1]);
    $self->set_new_node(1);
}

sub cb_alias {
    my ($self, $token) = @_;
    my $alias = substr($token->{value}, 1);
    push @{ $self->event_stack }, [ alias => {
        value => $alias,
        offset => $token->{column},
    }];
}

sub cb_question {
    my ($self, $res) = @_;
    $self->set_new_node(1);
}

sub cb_empty_complexvalue {
    my ($self, $res) = @_;
    $self->scalar_event({ style => ':', value => undef });
}

sub cb_questionstart {
    my ($self, $token) = @_;
    $self->start_mapping($token->{column});
}

sub cb_complexcolon {
    my ($self, $res) = @_;
    $self->set_new_node(1);
}

sub cb_seqstart {
    my ($self, $token) = @_;
    my $column = $token->{column};
    $self->start_sequence($column);
    $self->set_new_node(1);
}

sub cb_seqitem {
    my ($self, $res) = @_;
    $self->set_new_node(1);
}

sub cb_start_quoted {
    my ($self, $token) = @_;
    my $stack = $self->event_stack;
    my $info = {
        style => $token->{value},
        value => [],
        offset => $token->{column},
    };
    if (@$stack and $stack->[-1]->[0] eq 'properties') {
        $self->fetch_inline_properties($stack, $info);
    }
    push @{ $stack }, [ scalar => $info ];
}

sub cb_fetch_tokens_quoted {
    my ($self) = @_;
    my $indent = $self->offset->[-1] + 1;
    $self->lexer->fetch_next_tokens($indent);
}

sub cb_start_plain {
    my ($self, $token) = @_;
    my $stack = $self->event_stack;
    my $info = {
            style => ':',
            value => [ $token->{value} ],
            offset => $token->{column},
    };
    if (@$stack and $stack->[-1]->[0] eq 'properties') {
        $self->fetch_inline_properties($stack, $info);
    }
    push @{ $stack }, [ scalar => $info ];
}

sub cb_empty_plain {
    my ($self, $res) = @_;
    my $stack = $self->event_stack;
    push @{ $stack->[-1]->[1]->{value} }, '';
    $self->cb_fetch_tokens_plain;
}

sub cb_fetch_tokens_plain {
    my ($self) = @_;
    my $indent = $self->offset->[-1] + 1;
    $self->lexer->set_context('plain');
    $self->lexer->fetch_next_tokens($indent);
}

sub cb_start_flowseq {
    my ($self, $token) = @_;
    $self->start_flow_sequence($token->{column});
    $self->set_new_node(1);
}

sub cb_start_flowmap {
    my ($self, $token) = @_;
    $self->start_flow_mapping($token->{column});
    $self->set_new_node(1);
}

sub cb_end_flowseq {
    my ($self, $res) = @_;
    $self->end_flow_sequence;
    $self->set_new_node(undef);
}

sub cb_flow_comma {
    my ($self) = @_;
    $self->set_new_node(1);
}

sub cb_flow_colon {
    my ($self) = @_;
    $self->set_new_node(1);
}

sub cb_end_flowmap {
    my ($self, $res) = @_;
    $self->end_flow_mapping;
    $self->set_new_node(undef);
}

sub cb_empty_flowmap_value {
    my ($self, $token) = @_;
    my $stack = $self->event_stack;
    my $info = {
        style => ':',
        value => undef,
        offset => $token->{column},
    };
    if (@$stack and $stack->[-1]->[0] eq 'properties') {
        $self->fetch_inline_properties($stack, $info);
    }
    $self->scalar_event($info);
    $self->set_new_node(undef);
}

sub cb_take {
    my ($self, $token) = @_;
    my $stack = $self->event_stack;
    push @{ $stack->[-1]->[1]->{value} }, $token->{value};
}

sub cb_empty_quoted_line {
    my ($self, $res) = @_;
    my $stack = $self->event_stack;
    push @{ $stack->[-1]->[1]->{value} }, '';
    $self->cb_fetch_tokens_quoted;
}

sub cb_insert_map_alias {
    my ($self, $res) = @_;
    my $stack = $self->event_stack;
    my $scalar = pop @$stack;
    my $info = $scalar->[1];
    $self->start_mapping($info->{offset});
    $self->alias_event($info);
    $self->set_new_node(1);
}

sub cb_insert_map {
    my ($self, $res) = @_;
    my $stack = $self->event_stack;
    my $scalar = pop @$stack;
    my $info = $scalar->[1];
    $self->start_mapping($info->{offset});
    $self->scalar_event($info);
    $self->set_new_node(1);
}

sub cb_insert_empty_map {
    my ($self, $token) = @_;
    my $stack = $self->event_stack;
    my $info = {
        style => ':',
        value => undef,
        offset => $token->{column},
    };
    if (@$stack and $stack->[-1]->[0] eq 'properties') {
        $self->fetch_inline_properties($stack, $info);
    }
    $self->start_mapping($info->{offset});
    $self->scalar_event($info);
    $self->set_new_node(1);
}

sub cb_block_scalar {
    my ($self, $token) = @_;
    my $type = $token->{value};
    my $stack = $self->event_stack;
    my $info = {
        style => $type,
        value => [],
        current_indent => $self->offset->[-1] + 1,
        offset => $token->{column},
    };
    if (@$stack and $stack->[-1]->[0] eq 'properties') {
        $self->fetch_inline_properties($stack, $info);
    }
    push @{ $self->event_stack }, [ scalar => $info ];
    $self->lexer->set_context('block_scalar_start');
}

sub cb_add_block_scalar_indent {
    my ($self, $token) = @_;
    my $indent = $token->{value};
    my $event = $self->event_stack->[-1]->[1];
    $event->{block_indent} = $indent;
    $event->{got_indent} = 1;
    $event->{current_indent} = $indent;
    $self->lexer->set_context('block_scalar');
}

sub cb_add_block_scalar_chomp {
    my ($self, $token) = @_;
    my $chomp = $token->{value};
    $self->event_stack->[-1]->[1]->{block_chomp} = $chomp;
}

sub cb_block_scalar_empty_line {
    my ($self, $res) = @_;
    my $event = $self->event_stack->[-1]->[1];
    push @{ $event->{value} }, '';
    $self->lexer->fetch_next_tokens($event->{current_indent});
}

sub cb_block_scalar_start_indent {
    my ($self, $token) = @_;
    my $event = $self->event_stack->[-1]->[1];
    $event->{current_indent} = length $token->{value};
}

sub cb_fetch_tokens_block_scalar {
    my ($self, $res) = @_;
    my $event = $self->event_stack->[-1]->[1];
    $self->lexer->fetch_next_tokens($event->{current_indent})
}

sub cb_block_scalar_start_content {
    my ($self, $token) = @_;
    my $event = $self->event_stack->[-1]->[1];
    push @{ $event->{value} }, $token->{value};
    $self->lexer->set_context('block_scalar');
}

sub cb_block_scalar_content {
    my ($self, $token) = @_;
    my $event = $self->event_stack->[-1]->[1];
    push @{ $event->{value} }, $token->{value};
}

1;
