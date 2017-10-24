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
    $self->begin('STR', -1);

    TRACE and $self->debug_yaml;

    my $implicit = 0;
    while (1) {
        my $next_tokens = $self->lexer->fetch_next_tokens(0);
        last unless @$next_tokens;
        my ($start, $start_line) = $self->parse_document_head($implicit);

        if ( $self->parse_empty($next_tokens) ) {
        }
        last unless @$next_tokens;

        $self->begin('DOC', -1, { implicit => $start ? 0 : 1 });

        my $new_type = $start_line ? 'FULLSTARTNODE' : 'FULLNODE';
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

        $self->end('DOC', { implicit => $implicit });

    }

    $self->end('STR');
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

sub parse_document {
    TRACE and warn "=== parse_document()\n";
    my ($self) = @_;

    my $next_tokens = $self->lexer->next_tokens;
    while (1) {

        TRACE and $self->info("----------------------- LOOP");
        TRACE and $self->debug_yaml;
        TRACE and $self->debug_events;


        {
            $self->lexer->fetch_next_tokens(0);
            $self->parse_empty($next_tokens);
            my $end = $self->check_indent();
            return if $end;
        }

        $self->parse_next_line();
    }

    TRACE and $self->debug_events;
    return 1;
}

sub check_indent {
    my ($self, %args) = @_;

    my $next_tokens = $self->lexer->next_tokens;
    #TRACE and $self->info("NEXT TOKENS:");
    #TRACE and $self->debug_tokens($next_tokens);
    my $next_token = $next_tokens->[0];
    if ($next_token and $next_token->{column} != 0) {
        return;
    }

    my $new_node = $self->new_node;
    my $exp = $self->events->[-1];
    my $end = 0;
    my $indent = 0;
    my $tokens = $self->tokens;

    if (not $next_token) {
        $end = 1;
    }
    elsif ($next_token->{name} eq 'DOC_START') {
        $end = 1;
    }
    elsif ($next_token->{name} eq 'DOC_END') {
        $end = 1;
    }
    elsif ($self->level < 2 and not $new_node) {
        $end = 1;
    }
    if ($end) {
        my $level = $self->level;
        my $remove = $level - 1;
        if ($new_node) {
            $self->set_new_node(undef);
            push @{ $self->event_stack }, [ scalar => { style => ':' } ];
            $self->process_events(result => {});
        }
        $exp = $self->remove_nodes($remove);
        return $end;
    }

    my $space = 0;
    if ($next_token->{name} eq 'INDENT') {
        $space = length $next_token->{value};
        push @$tokens, shift @$next_tokens;
        $next_token = $next_tokens->[0];
    }

    $indent = $self->offset->[ -1 ];

    TRACE and $self->info("INDENT: space=$space indent=$indent");

    if ($space > $indent) {
        unless ($new_node) {
            $self->exception("Bad indendation in $exp");
        }
        return;
    }
    else {

        my $seq_start = $next_token->{name} eq 'DASH';
        TRACE and $self->info("SEQSTART: $seq_start");

        my $remove = $self->reset_indent($space);

        if ($new_node) {
            # unindented sequence starts
            if ($remove == 0 and $seq_start and $exp eq 'MAP') {
            }
            else {
                undef $new_node;
                $self->set_new_node(undef);
                push @{ $self->event_stack }, [ scalar => { style => ':' } ];
                $self->process_events(result => {});
            }
        }

        if ($remove) {
            $exp = $self->remove_nodes($remove);
        }


        unless ($new_node) {
            if ($exp eq 'SEQ' and not $seq_start) {
                my $ui = $self->in_unindented_seq;
                if ($ui) {
                    TRACE and $self->info("In unindented sequence");
                    $self->end('SEQ');
                    TRACE and $self->debug_events;
                    $exp = $self->events->[-1];
                }
                else {
                    $self->exception("Expected sequence item");
                }
            }


            if ($self->offset->[-1] != $space) {
                $self->exception("Expected $exp");
            }
        }
    }

    return;
}

sub parse_next_line {
    my ($self) = @_;
    DEBUG and $self->info("----------------> parse_next_line()");
    my $new_node = $self->new_node;
    my $tokens = $self->tokens;

    while (1) {
        unless ($new_node) {
            my $exp = $self->events->[-1];
            if ($exp eq 'MAP') {
                $self->set_rule( 'FULL_MAPKEY' );
            }
            else {
                $self->set_rule( "NODETYPE_$exp" );
            }
        }

        my $res = $self->parse_tokens();

        return unless $res->{name};

        $self->process_events( result => $res );

        if ($res->{new_type} eq 'END') {
            $self->set_new_node(undef);
            return;
        }

        if ($res->{name} eq 'MAPKEY' or $res->{name} eq 'COMPLEXCOLON') {
            $self->events->[-1] = 'MAP';
        }
        elsif ($res->{name} eq 'COMPLEX') {
            $self->events->[-1] = 'COMPLEX';
        }

        $new_node = $res->{new_type};
        $self->set_new_node($res->{new_type});

        return if $tokens->[-1]->{name} eq 'EOL';
    }

    return;
}

sub process_events {
    my ($self, %args) = @_;

    my $event_stack = $self->event_stack;
    return unless @$event_stack;

    if (@$event_stack == 1 and $event_stack->[0]->[0] eq 'properties') {
        return;
    }
    my $res = $args{result};

    my $properties;
    for my $event (@$event_stack) {
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$event], ['event']);
        if ($event->[0] eq 'properties') {
            $properties = $event->[1];
        }
        elsif ($event->[0] eq 'scalar') {
            my ($type, $info) = @$event;
            if ($properties) {
                for my $p (@{ $properties->{newline} }, @{ $properties->{inline} }) {
                    my $type = $p->{type};
                    if (exists $info->{ $type }) {
                        $self->exception("A node can only have one $type");
                    }
                    $info->{ $type } = $p->{value};
                }
                undef $properties;
            }
            $self->scalar_event_render( $info );
        }
        elsif ($event->[0] eq 'begin') {
            my $offset = $res->{offset};
            my ($type, $name, $info) = @$event;
            if ($properties and $properties->{newline}) {

                for my $p (@{ $properties->{newline} }) {
                    my $type = $p->{type};
                    if (exists $info->{ $type }) {
                        $self->exception("A node can only have one $type");
                    }
                    $info->{ $type } = $p->{value};
                }
                delete $properties->{newline};
                undef $properties unless keys %$properties;
            }
            $self->$type($name, $offset, $info );
        }
        elsif ($event->[0] eq 'alias') {
            my ($type, $info) = @$event;
            if ($properties) {
                $self->exception("Parse error: Alias not allowed in this context");
            }
            $info->{content} = delete $info->{alias};
            DEBUG and $self->debug_event( 'alias_event' => $info );
            $self->callback->($self, 'alias_event', $info);
        }
    }
    @$event_stack = ();
}

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
    RULE: while (1) {
        last unless $next_rule_name;

        DEBUG and $self->info("RULE: $next_rule_name");
        unless (@$next_tokens) {
            $self->exception("No more tokens");
            return;
        }
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$next_tokens->[0]], ['next_token']);
        my $got = $next_tokens->[0]->{name};
        my $def = $next_rule->{ $got };
        if ($def) {
            push @$tokens, shift @$next_tokens;
        }
        else {
            $def = $next_rule->{DEFAULT};
            $got = 'DEFAULT';
        }

        unless ($def) {
            DEBUG and $self->not("---not $next_tokens->[0]->{name}");
            my @possible = sort grep { m/^[A-Z_]+$/ } keys %$next_rule;
            $self->expected(
                expected => \@possible,
                got => $next_tokens->[0],
            );
            return;
        }

        DEBUG and $self->got("---got $got");
        if (my $sub = $def->{match}) {
            DEBUG and $self->info("CALLBACK $sub");
            $self->$sub($res);
        }
        if ($def->{fetch}) {
            DEBUG and $self->info("fetch_next_tokens");
            $self->lexer->fetch_next_tokens(0);
        }
        if (my $new = $def->{new}) {
            $next_rule_name = $new;
            DEBUG and $self->got("NEW: $next_rule_name");

            if ($next_rule_name eq 'ERROR') {
                $self->exception("Got unexpected $next_tokens->[0]->{name}");
            }
            if ($def->{return}) {
                $self->set_rule($next_rule_name);
                $res->{new_type}= $next_rule_name;
                return $res;
            }

            if ($next_rule_name eq 'PREVIOUS') {
                my $node_type = $self->new_node;
                $next_rule_name = $node_type;
                $next_rule_name =~ s/^FULL//;

                $next_rule_name = "NODETYPE_$next_rule_name";
            }
            if (exists $GRAMMAR->{ $next_rule_name }) {
                $next_rule = $GRAMMAR->{ $next_rule_name };
                next RULE;
            }

            $self->set_rule($next_rule_name);
            $res->{new_type}= $next_rule_name;
            return $res;
        }
        $next_rule_name .= " - $got"; # for debugging
        $next_rule = $def;

    }

    die "Unexpected";
    return;
}

sub scalar_event_render {
    my ($self, $res) = @_;

    my $value = delete $res->{value};
    my $style = $res->{style} // ':';
    if ($style eq ':') {
        if (ref $value) {
            $value = YAML::PP::Render::render_multi_val($value);
        }
    }
    elsif ($style eq '"') {
        $value = YAML::PP::Render::render_quoted(
            double => 1,
            lines => $value,
        );
    }
    elsif ($style eq "'") {
        $value = YAML::PP::Render::render_quoted(
            double => 0,
            lines => $value,
        );
    }
    $res->{content} = $value;
    $self->scalar_event( $res );
}

sub remove_nodes {
    my ($self, $count) = @_;
    my $exp = $self->events->[-1];
    for (1 .. $count) {
        if ($exp eq 'COMPLEX') {
            $self->scalar_event({ style => ':' });
            $self->events->[-1] = 'MAP';
            $self->end('MAP');
        }
        elsif ($exp eq 'MAP' or $exp eq 'SEQ' or $exp eq 'END') {
            $self->end($exp);
        }
        $exp = $self->events->[-1];
        TRACE and $self->debug_events;
    }
    TRACE and $self->info("Removed $count nodes");
    return $exp;
}

sub reset_indent {
    my ($self, $space) = @_;
    TRACE and warn "=== reset_indent($space)\n";
    my $off = $self->offset;
    my $i = $#$off;
    while ($i > 1) {
        my $test_indent = $off->[ $i ];
        if ($test_indent == $space) {
            last;
        }
        elsif ($test_indent <= $space) {
            last;
        }
        $i--;
    }
    return $#$off - $i;
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

sub in_unindented_seq {
    my ($self) = @_;
    if ($self->level > 2) {
        my $seq_indent = $self->offset->[ -1 ];
        my $prev_indent = $self->offset->[ -2 ];
        if ($prev_indent == $seq_indent) {
            return 1;
        }
    }
    return 0;
}

sub in {
    my ($self, $event) = @_;
    return $self->events->[-1] eq $event;
}

my %event_to_method = (
    MAP => 'mapping',
    SEQ => 'sequence',
    DOC => 'document',
    STR => 'stream',
    VAL => 'scalar',
    ALI => 'alias',
    COMPLEX => 'mapping',
);

sub scalar_event {
    my ($self, $info) = @_;

    DEBUG and $self->debug_event( $event_to_method{VAL} . "_event" => $info );
    $self->callback->($self, $event_to_method{VAL} . "_event", $info);
}

sub alias_event {
    my ($self, $info) = @_;

    DEBUG and $self->debug_event( $event_to_method{ALI} . "_event" => $info );
    $self->callback->($self, $event_to_method{ALI} . "_event", $info);
}

sub begin {
    my ($self, $event, $offset, $info) = @_;
    $info->{type} = $event;

    DEBUG and $self->debug_event( $event_to_method{ $event } . "_start_event" => $info );
    $self->callback->($self,
        $event_to_method{ $event } . "_start_event" => $info
    );
    push @{ $self->events }, $event;
    push @{ $self->offset }, $offset;
    TRACE and $self->debug_events;
}

sub end {
    my ($self, $event, $info) = @_;
    $info->{type} = $event;

    pop @{ $self->offset };

    my $last = pop @{ $self->events };
    if ($last ne $event) {
        die "end($event): Unexpected event '$last', expected $event";
    }

    DEBUG and $self->debug_event( $event_to_method{ $event } . "_end_event" => $info );
    $self->callback->($self,
        $event_to_method{ $event } . "_end_event" => $info
    );
    if ($event eq 'DOC') {
        $self->set_tagmap({
            '!!' => "tag:yaml.org,2002:",
        });
    }
}

sub event_to_test_suite {
    my ($self, $event) = @_;
    if (ref $event) {
        my ($ev, $info) = @$event;
        if ($event_to_method{ $ev }) {
            $ev = $event_to_method{ $ev } . "_event";
        }
        my $string;
        my $type = $info->{type};
        my $content = $info->{content};

        my $properties = '';
        $properties .= " &$info->{anchor}" if defined $info->{anchor};
        $properties .= " $info->{tag}" if defined $info->{tag};

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
        }
        elsif ($ev eq 'sequence_start_event') {
            $string = "+SEQ";
            $string .= $properties;
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

sub not {
    my ($self, $msg) = @_;
    require Term::ANSIColor;
    warn Term::ANSIColor::colored(["red"], "============ $msg"), "\n";
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
    my $got = $args{got}->{name};
    my @caller = caller(0);
    $self->exception("Expected (@$expected), but got $got",
        caller => \@caller,
    );
}

sub cb_tag {
    my ($self, $res) = @_;
    my $stack = $self->event_stack;
    if (! @$stack or $stack->[-1]->[0] ne 'properties') {
        push @$stack, [ properties => {} ];
    }
    my $last = $stack->[-1]->[1];
    my $tag = YAML::PP::Render::render_tag($self->tokens->[-1]->{value}, $self->tagmap);
    $last->{inline} ||= [];
    push @{ $last->{inline} }, {
        type => 'tag',
        value => $tag,
    };
}

sub cb_anchor {
    my ($self, $res) = @_;
    my $anchor = $self->tokens->[-1]->{value};
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
    my ($self, $res) = @_;
    $res->{name} ||= 'NOOP';
    push @{ $self->event_stack }, [ scalar => {
        style => ':',
        value => $self->tokens->[-1]->{value},
    }];
}

sub cb_empty_mapkey {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->event_stack }, [ scalar => {
        style => ':',
        value => undef,
    }];
}

sub cb_doublequoted_key {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->event_stack }, [ scalar => {
        style => '"',
        value => [ $self->tokens->[-1]->{value} ],
    }];
}

sub cb_singlequoted_key {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->event_stack }, [ scalar => {
        style => "'",
        value => [ $self->tokens->[-1]->{value} ],
    }];
}

sub cb_mapkey_alias {
    my ($self, $res) = @_;
    my $alias = $self->tokens->[-1]->{value};
    $alias = substr($alias, 1);
    $res->{name} = 'NOOP';
    push @{ $self->event_stack }, [ alias => {
        alias => $alias,
    }];
}

sub cb_question {
    my ($self, $res) = @_;
    $res->{name} = 'COMPLEX';
}

sub cb_empty_complexvalue {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->event_stack }, [ scalar => { style => ':' }];
}

sub cb_questionstart {
    my ($self, $res) = @_;
    push @{ $self->event_stack }, [ begin => 'COMPLEX', { }];
    $res->{name} = 'NOOP';
}

sub cb_complexcolon {
    my ($self, $res) = @_;
    $res->{name} = 'COMPLEXCOLON';
}

sub cb_seqstart {
    my ($self, $res) = @_;
    push @{ $self->event_stack }, [ begin => 'SEQ', { }];
    $res->{name} = 'NOOP';
}

sub cb_seqitem {
    my ($self, $res) = @_;
    $res->{name} = 'NOOP';
}

sub cb_start_quoted {
    my ($self, $res) = @_;
    push @{ $self->event_stack }, [
        scalar => {
            style => $self->tokens->[-1]->{value},
            value => [],
        },
    ];
}

sub cb_start_plain {
    my ($self, $res) = @_;
    push @{ $self->event_stack }, [
        scalar => {
            style => ':',
            value => [ $self->tokens->[-1]->{value} ],
        },
    ];
}

sub cb_start_alias {
    my ($self, $res) = @_;
    my $alias = $self->tokens->[-1]->{value};
    $alias = substr($alias, 1);
    push @{ $self->event_stack }, [
        alias => {
            alias => $alias,
        },
    ];
}

sub cb_take {
    my ($self, $res) = @_;
    my $stack = $self->event_stack;
    push @{ $stack->[-1]->[1]->{value} }, $self->tokens->[-1]->{value};
}

sub cb_got_scalar {
    my ($self, $res) = @_;
    $res->{name} = 'NOOP';
}

sub cb_insert_map {
    my ($self, $res) = @_;
    my $stack = $self->event_stack;
    if (@$stack and $stack->[-1]->[0] ne 'properties') {
        splice @$stack, -1, 0, [ begin => 'MAP' => {} ];
    }
    else {
        push @$stack,
        [ begin => 'MAP' => {} ],
        [ scalar => { style => ':', value => undef } ];
    }
    $res->{name} = 'NOOP';
}

sub cb_got_multiscalar {
    my ($self, $res) = @_;
    my $stack = $self->event_stack;
    my $multi = $self->lexer->parse_plain_multi($self);
    push @{ $stack->[-1]->[1]->{value} }, @{ $multi };
    $res->{name} = 'NOOP';
}

sub cb_block_scalar {
    my ($self, $res) = @_;
    my $type = $self->tokens->[-1]->{value};
    push @{ $self->event_stack }, [ scalar => {
        style => $type,
    }];
    $res->{name} = 'NOOP';
}

sub cb_add_block_scalar_indent {
    my ($self, $res) = @_;
    my $indent = $self->tokens->[-1]->{value};
    $self->event_stack->[-1]->[1]->{block_indent} = $indent;
}

sub cb_add_block_scalar_chomp {
    my ($self, $res) = @_;
    my $chomp = $self->tokens->[-1]->{value};
    $self->event_stack->[-1]->[1]->{block_chomp} = $chomp;
}

sub cb_read_block_scalar {
    my ($self, $res) = @_;
    my $event = $self->event_stack->[-1]->[1];
    my $lines = $self->parse_block_scalar(
        indent => $event->{block_indent},
    );
    my $string = YAML::PP::Render::render_block_scalar(
        block_type => $event->{style},
        chomp => $event->{block_chomp},
        lines => $lines,
    );
    $event->{value} = $string;
}

sub parse_block_scalar {
    TRACE and warn "=== parse_block_scalar()\n";
    my ($self, %args) = @_;
    my $lexer = $self->lexer;
    my $tokens = $self->tokens;
    my $next_tokens = $lexer->next_tokens;
    my $indent = $self->offset->[-1] + 1;

    my $exp_indent = $args{indent} || 0;

    my @lines;

    my $got_indent = 0;
    if ($exp_indent) {
        $indent = $exp_indent;
        $got_indent = 1;
    }
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$indent], ['indent']);
    my @tokens;
    while (1) {
        my $next_tokens = $lexer->_fetch_next_tokens_block_scalar($indent)
            or last;
        if ($next_tokens->[0]->{name} eq 'EOL') {
            push @$tokens, shift @$next_tokens;
            push @lines, '';
            next;
        }
        my $spaces = shift @$next_tokens;
        if ($next_tokens->[0]->{name} eq 'EOL') {
            push @$tokens, $spaces;
            push @$tokens, shift @$next_tokens;
            push @lines, '';
            next;
        }
        my $more_spaces;
        if ($next_tokens->[0]->{name} eq 'SPACE') {
            $more_spaces = shift @$next_tokens;
        }
        my ($content, $lb) = @$next_tokens;
        @$next_tokens = ();

        unless ($got_indent) {
            if ($more_spaces) {
                $spaces->{value} .= $more_spaces->{value};
                $indent += length $more_spaces->{value};
                undef $more_spaces;
            }
            unless (length $content->{value}) {
                push @$tokens, $spaces;
                push @$tokens, $lb;
                push @lines, '';
                next;
            }

            # first non-empty line
            $got_indent = 1;

        }
        push @$tokens, $spaces;

        my $value = $content->{value};
        if ($more_spaces) {
            push @$tokens, $more_spaces;
            $value = $more_spaces->{value} . $value;
        }
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$content], ['content']);

        push @$tokens, $content;
        push @$tokens, $lb;
        push @lines, $value;

    }
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@lines], ['lines']);

    return \@lines;
}


sub cb_flow_map {
    $_[0]->exception("Not Implemented: Flow Style");
}

sub cb_flow_seq {
    $_[0]->exception("Not Implemented: Flow Style");
}


1;
