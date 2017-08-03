# ABSTRACT: YAML Parser
use strict;
use warnings;
package YAML::PP::Parser;

our $VERSION = '0.000'; # VERSION

use constant TRACE => $ENV{YAML_PP_TRACE};
use constant DEBUG => $ENV{YAML_PP_DEBUG} || $ENV{YAML_PP_TRACE};

use YAML::PP::Render;
use YAML::PP::Tokenizer;
use YAML::PP::Grammar qw/ $GRAMMAR /;


sub new {
    my ($class, %args) = @_;
    my $reader = delete $args{reader};
    my $self = bless {
        reader => $reader,
        tokenizer => YAML::PP::Tokenizer->new,
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
sub reader {
    my ($self) = @_;
    if (defined $self->{reader}) {
        return $self->{reader};
    }

    my $input = $self->{input} // die "No input";

    require YAML::PP::Reader;
    return YAML::PP::Reader->new(input => $input);
}
sub tokenizer { return $_[0]->{tokenizer} }
sub callback { return $_[0]->{callback} }
sub set_callback { $_[0]->{callback} = $_[1] }
sub yaml { return $_[0]->{yaml} }
sub set_yaml { $_[0]->{yaml} = $_[1] }
sub level { return $_[0]->{level} }
sub set_level { $_[0]->{level} = $_[1] }
sub offset { return $_[0]->{offset} }
sub set_offset { $_[0]->{offset} = $_[1] }
sub events { return $_[0]->{events} }
sub set_events { $_[0]->{events} = $_[1] }
sub tagmap { return $_[0]->{tagmap} }
sub set_tagmap { $_[0]->{tagmap} = $_[1] }
sub tokens { return $_[0]->{tokens} }
sub set_tokens { $_[0]->{tokens} = $_[1] }
sub rules { return $_[0]->{rules} }
sub set_rules { $_[0]->{rules} = $_[1] }
sub stack { return $_[0]->{stack} }
sub set_stack { $_[0]->{stack} = $_[1] }

my $RE_WS = '[\t ]';
my $RE_LB = '[\r\n]';
my $RE_DOC_END = qr/\A(\.\.\.)(?=$RE_WS|$)/m;
my $RE_DOC_START = qr/\A(---)(?=$RE_WS|$)/m;
my $RE_EOL = qr/\A($RE_WS+#.*|$RE_WS+)?$RE_LB/;

#ns-word-char    ::= ns-dec-digit | ns-ascii-letter | “-”
my $RE_NS_WORD_CHAR = '[0-9A-Za-z-]';
my $RE_URI_CHAR = '(?:' . '%[0-9a-fA-F]{2}' .'|'.  q{[0-9A-Za-z#;/?:@&=+$,_.!*'\(\)\[\]-]} . ')';
my $RE_NS_TAG_CHAR = '(?:' . '%[0-9a-fA-F]{2}' .'|'.  q{[0-9A-Za-z#;/?:@&=+$_.*'\(\)-]} . ')';

#  [#x21-#x7E]          /* 8 bit */
# | #x85 | [#xA0-#xD7FF] | [#xE000-#xFFFD] /* 16 bit */
# | [#x10000-#x10FFFF]                     /* 32 bit */

our $RE_INT = '[+-]?[1-9]\d*';
our $RE_OCT = '0o[1-7][0-7]*';
our $RE_HEX = '0x[1-9a-fA-F][0-9a-fA-F]*';
our $RE_FLOAT = '[+-]?(?:\.\d+|\d+\.\d*)(?:[eE][+-]?\d+)?';
our $RE_NUMBER ="'(?:$RE_INT|$RE_OCT|$RE_HEX|$RE_FLOAT)";

my $plain_start_word_re = '[^*!&\s#][^\r\n\s]*';
my $plain_word_re = '[^#\r\n\s][^\r\n\s]*';



sub parse {
    my ($self, $yaml) = @_;
    if (defined $yaml) {
        $self->{input} = $yaml;
    }
    $self->set_yaml(\$self->reader->read);
    $self->set_level(-1);
    $self->set_offset([0]);
    $self->set_events([]);
    $self->set_tagmap({
        '!!' => "tag:yaml.org,2002:",
    });
    $self->set_tokens([]);
    $self->set_rules([]);
    $self->set_stack({});
    $self->tokenizer->init;
    $self->parse_stream;

    DEBUG and $self->highlight_yaml;
    TRACE and $self->debug_tokens;
    if (DEBUG and $ENV{YAML_PP_STATS}) {
        my %match = %YAML::PP::Tokenizer::MATCH_RULE;
        my %check = %YAML::PP::Tokenizer::CHECK_RULE;
        warn __PACKAGE__.':'.__LINE__.": ----- REGEXES\n";
        for my $key (sort { $match{ $b } <=> $match{ $a } } keys %match) {
            warn __PACKAGE__.':'.__LINE__.": $key: $match{ $key };\n";
        }
        warn __PACKAGE__.':'.__LINE__.": ----- RULE CHECKS\n";
        for my $key (sort { $check{ $b } <=> $check{ $a } } keys %check) {
            warn __PACKAGE__.':'.__LINE__.": $key: $check{ $key };\n";
        }
    }
}

use constant NODE_TYPE => 0;
use constant NODE_OFFSET => 1;

sub parse_stream {
    TRACE and warn "=== parse_stream()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    $self->begin('STR', -1);

    TRACE and $self->debug_yaml;

    my $exp_start = 0;
    while (length $$yaml) {
        my $head = $self->parse_document_head();
        my ($start, $start_line) = $self->parse_document_start;
        if (($head or $exp_start) and not $start) {
            die "Expected ---";
        }
        $exp_start = 0;
        $self->parse_empty;
        last unless length $$yaml;

        if ($start) {
            $self->begin('DOC', -1, { content => "---" });
        }
        else {
            $self->begin('DOC', -1);
        }

        my $new_type = $start_line ? 'FULLSTARTNODE' : 'FULLNODE';
        my $new_node = [ $new_type => 0 ];
        $self->set_rules([ $GRAMMAR->{ FULLNODE } ]);
        my ($end) = $self->parse_document($new_node);
        if ($end) {
            $self->end('DOC', { content => "..." });
        }
        else {
            $exp_start = 1;
            $self->end('DOC');
        }

    }

    $self->end('STR');
}

sub parse_document_start {
    TRACE and warn "=== parse_document_start()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;

    my ($start, $start_line) = (0, 0);
    if ($$yaml =~ s/$RE_DOC_START//) {
        push @{ $self->tokens }, ['DOC_START', $1];
        $start = 1;
        my $eol = $$yaml =~ s/\A($RE_EOL|\z)//;
        push @{ $self->tokens }, ['EOL', $1] if $eol;
        unless ($eol) {
            if ($$yaml =~ s/\A($RE_WS+)//) {
                push @{ $self->tokens }, ['WS', $1];
                $start_line = 1;
            }
            else {
                warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
                die "Unexpected content after ---";
            }
        }
    }
    return ($start, $start_line);
}

sub parse_document_head {
    TRACE and warn "=== parse_document_head()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    my $tokens = $self->tokens;
    my $head;
    while (length $$yaml) {
        $self->parse_empty;
        if ($$yaml =~ s/\A(\s*%YAML ?1\.2$RE_WS*)//) {
            push @$tokens, ['YAML_DIRECTIVE', $1];
            $head = 1;
            next;
        }
        if ($$yaml =~ s/\A(\s*%TAG +(!$RE_NS_WORD_CHAR*!|!) +(tag:\S+|!$RE_URI_CHAR+)$RE_WS*)//) {
            push @$tokens, ['TAG_DIRECTIVE', $1];
            $head = 1;
            my $tag_alias = $2;
            my $tag_url = $3;
            $self->tagmap->{ $tag_alias } = $tag_url;
            next;
        }
        if ($$yaml =~ s/\A(\s*\A%(?:\w+).*)//) {
            push @$tokens, ['RESERVED_DIRECTIVE', $1];
            warn "Found reserved directive '$1'";
            $head = 1;
            next;
        }
        last;
    }
    return $head;
}


sub parse_document {
    TRACE and warn "=== parse_document()\n";
    my ($self, $new_node) = @_;

    my $next_full_line = 1;
    my $tokens = $self->tokens;
    while (1) {

        TRACE and $self->info("----------------------- LOOP");
        TRACE and $self->info("EXPECTED: (@$new_node)") if $new_node;
        TRACE and $self->debug_yaml;
        TRACE and $self->debug_events;

        my $exp = $self->events->[-1];
        my $offset = 0;
        if ($next_full_line) {
            my $yaml = $self->yaml;
            my $next_tokens = $self->tokenizer->fetch_next_tokens(0, $yaml);
            TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$next_tokens], ['next_tokens']);
            if (@$next_tokens and $next_tokens->[0]->[0] eq 'INDENT') {
                $offset = length $next_tokens->[0]->[1];
                push @$tokens, $next_tokens->[0];
                shift @$next_tokens;
            }
            if (@$next_tokens == 1 and $next_tokens->[0]->[0] =~ m/EOL|EMPTY/) {
                push @$tokens, shift @$next_tokens;
                TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$next_tokens], ['next_tokens']);
                if ($tokens->[-1]->[1] eq '') {
                }
                else {
                    next;
                }
                TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$next_tokens], ['next_tokens']);
            }

            my $end;
            my $explicit_end;
            ($new_node, $end, $explicit_end) = $self->check_indent(
                next_tokens => $next_tokens,
                space => $offset,
                expected => $exp,
                new_node => $new_node,
            );
            $exp = $self->events->[-1];
            if ($explicit_end) {
                return 1;
            }
            if ($end) {
                return;
            }

        }
        else {
            TRACE and $self->info("ON SAME LINE: INDENT");
            $offset = $new_node->[NODE_OFFSET];
        }
        $next_full_line = 1;

        TRACE and $self->info("Expecting $exp");

        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$new_node], ['new_node']);

        my ($res) = $self->parse_next(
            expected => $exp,
            node_type => ($new_node ? $new_node->[NODE_TYPE] : undef),
        );
        next unless $res;

        ($new_node) = $self->process_result(
            result => $res,
            offset => $offset,
            expected => $exp,
        );

        $next_full_line = $res->{eol} ? 1 : 0;
    }

    TRACE and $self->debug_events;
    return 0;
}

sub check_indent {
    my ($self, %args) = @_;
    my $exp = $args{expected};
    my $new_node = $args{new_node};
    my $space = $args{space};
    my $next_tokens = $args{next_tokens};
    my $yaml = $self->yaml;
    my $end = 0;
    my $explicit_end = 0;
    my $indent = 0;
    my $tokens = $self->tokens;

    if (@$next_tokens) {
        if ($next_tokens->[0]->[1] eq '') {
            $end = 1;
        }
    }
    else {
        my $eoyaml = not length $$yaml;
        if ($eoyaml) {
            $end = 1;
        }
    }
    if ($end) {
    }
    else {

        $indent = $self->offset->[ -1 ];
        if ($indent == -1 and $space == 0 and not $new_node) {
            $space = -1;
        }
    }

    TRACE and $self->info("INDENT: space=$space indent=$indent");

    if ($space <= 0) {
        if (@$next_tokens and $next_tokens->[0]->[0] eq 'DOC_START') {
        }
        elsif ($$yaml =~ s/$RE_DOC_END//) {
            push @$tokens, ['DOC_END', $1];
            $$yaml =~ s/($RE_EOL|\z)// or die "Unexpected";
            push @$tokens, ['EOL', $1];
            $end = 1;
            $explicit_end = 1;
            $space = -1;
        }
        elsif ($$yaml =~ $RE_DOC_START) {
            $end = 1;
        }
    }

    if ($space > $indent) {
        unless ($new_node) {
            die "Bad indendation in $exp";
        }
    }
    else {

        if ($space <= 0) {
            unless ($end) {
                if ($self->level < 2 and not $new_node) {
                    $end = 1;
                }
            }
            if ($end) {
                $space = -1;
            }
        }

        my $seq_start = 0;
        if (not $end and $$yaml =~ m/\A-($RE_WS|$)/m) {
            $seq_start = length $1 ? 2 : 1;
        }
        TRACE and $self->info("SEQSTART: $seq_start");

        my $remove = $self->reset_indent($space);

        if ($new_node) {
            # unindented sequence starts
            if ($remove == 0 and $seq_start and $exp eq 'MAP') {
            }
            else {
                my $properties = $self->stack->{node_properties} ||= {};
                undef $new_node;
                $self->event_value({ style => ':', %$properties });
                %$properties = ();
            }
        }

        if ($remove) {
            $exp = $self->remove_nodes($remove);
        }

        unless ($end) {

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
                        die "Expected sequence item";
                    }
                }


                if ($self->offset->[-1] != $space) {
                    die "Expected $exp";
                }
            }
        }
    }

    return ($new_node, $end, $explicit_end);
}

sub process_result {
    my ($self, %args) = @_;
    my $res = $args{result};
    my $offset = $args{offset};
    my $exp = $args{expected};

    my $stack = $self->stack;
    my $props = $stack->{node_properties} ||= {};
    my $properties = $stack->{properties} ||= {};
    my $stack_events = $stack->{events} || [];

    for my $event (@$stack_events) {
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$event], ['event']);
        my ($type, $name, $res) = @$event;
        if ($type eq 'begin') {
            $self->$type($name, $offset, { %$res, %$props });
            %$props = ();
        }
        elsif ($type eq 'value') {
            for my $key (keys %$properties) {
                $props->{ $key } = $properties->{ $key };
            }
            $self->res_to_event({ %$res, %$props });
            %$properties = ();
            %$props = ();
        }
        elsif ($type eq 'alias') {
            if (keys %$props or keys %$properties) {
                die "Parse error: Alias not allowed in this context";
            }
            $self->res_to_event({ %$res });
        }
    }
    @$stack_events = ();

    my $got = $res->{name};
    TRACE and $self->got("GOT $got");
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$res], ['res']);
    TRACE and $self->highlight_yaml;

    if ($got eq 'SCALAR') {
        return;
    }

    if ($got eq "MAPSTART") { }
    elsif ($got eq "MAPKEY") {
        if ($exp eq 'COMPLEX') {
            $self->events->[-1] = 'MAP';
        }
    }
    elsif ($got eq 'NOOP') { }
    elsif ($got eq 'SEQITEM') { }
    elsif ($got eq 'COMPLEX') {
        if ($exp eq 'MAP') {
            $self->events->[-1] = 'COMPLEX';
        }
    }
    elsif ($got eq 'COMPLEXCOLON') {
        $self->events->[-1] = 'MAP';
    }
    else {
        die "Unexpected res $got";
    }

    my $new_offset = $offset + 1 + ($res->{ws} || 0);
    my $new_type = $res->{new_type};
    my $new_node = [ $new_type => $new_offset ];
#    if ($new_type eq 'MAPVALUE') {
#        $new_type = 'FULLMAPVALUE';
#    }
    $self->set_rules([ $GRAMMAR->{ FULLNODE } ]);
    return $new_node;
}

my %TYPE2RULE = (
    MAP => {
        %{ $GRAMMAR->{RULE_MAPKEY_ALIAS} },
        %{ $GRAMMAR->{RULE_MAPKEY} },
    },
    MAPSTART => {
        %{ $GRAMMAR->{RULE_MAPSTART} },
    },
    SEQ => { %{ $GRAMMAR->{RULE_SEQITEM} } },
    MAPKEY => {
        %{ $GRAMMAR->{RULE_MAPKEY_ALIAS} },
        %{ $GRAMMAR->{RULE_MAPKEY} },
    },
    COMPLEX => {
        %{ $GRAMMAR->{RULE_COMPLEXVALUE} },
#        %{ $GRAMMAR->{RULE_MAPKEY_ALIAS} },
#        %{ $GRAMMAR->{RULE_MAPKEY} },
    },
    STARTNODE => {
        %{ $GRAMMAR->{RULE_SINGLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_DOUBLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_BLOCK_SCALAR} },
        %{ $GRAMMAR->{RULE_PLAIN} },
    },
    MAPVALUE => {
        %{ $GRAMMAR->{RULE_ALIAS_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_SINGLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_DOUBLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_BLOCK_SCALAR} },
        %{ $GRAMMAR->{RULE_PLAIN} },
    },
    NODE => {
        %{ $GRAMMAR->{RULE_SEQSTART} },
        %{ $GRAMMAR->{RULE_COMPLEX} },
        %{ $GRAMMAR->{RULE_SINGLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_DOUBLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_BLOCK_SCALAR} },
        %{ $GRAMMAR->{RULE_ALIAS_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_PLAIN_KEY_OR_NODE} },
    },
);

sub parse_next {
    TRACE and warn "=== parse_next()\n";
    my ($self, %args) = @_;
    my $node_type = $args{node_type};
    my $exp = delete $args{expected};
    my $res;
    my $rules = $self->rules;
    unless ($rules) {
        $rules = [];
        $self->set_rules($rules);
    }

    my $expected_type = $exp;
    my $no_alias = 0;
    if ($node_type or $exp eq 'MAP') {
        unless ($node_type) {
            @$rules = $GRAMMAR->{FULL_MAPKEY};
        }
        my ($success, $new_type) = $self->tokenizer->parse_tokens($self,
            callback => sub {
                my ($self, $sub) = @_;
                $self->$sub(undef);
            },
        );
        if (not $new_type and not $success) {
            die "Expected " . ($node_type ? "new node ($node_type)" : $exp);
        }
        my $return = 0;
        if ($new_type and $node_type) {
            if ($new_type =~ s/^TYPE_//) {
                $return = 1;
                @$rules = \$new_type;
            }
            elsif ($new_type eq 'PREVIOUS') {
                $new_type = $node_type;
                $new_type =~ s/^FULL//;
            }
        }
        if ($return) {
            return;
        }


        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$new_type], ['new_type']);
        unless ($new_type) {
            warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$rules], ['rules']);
            die "This should never happen";
        }
        # we got an anchor or tag
        $no_alias = $success ? 1 : 0;

        $expected_type = $new_type;
    }

    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$expected_type], ['expected_type']);
    @$rules = $TYPE2RULE{ $expected_type };

    $res = {};
    my ($success, $new_type) = $self->tokenizer->parse_tokens($self,
        callback => sub {
            my ($self, $sub) = @_;
            $self->$sub($res);
        },
    );

    unless ($success) {
        die "Expected $expected_type";
    }

    if (not $new_type) {
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$new_type], ['new_type']);
        die "This should never happen";
    }

    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$new_type], ['new_type']);
    $new_type =~ s/^TYPE_//;
    my $stack = $self->stack;
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$stack], ['stack']);

    if (defined $res->{alias} and $no_alias) {
        die "Parse error: Alias not allowed in this context";
    }

    $res->{new_type}= $new_type;
    return ($res);
}

sub res_to_event {
    my ($self, $res) = @_;
    if (defined(my $alias = $res->{alias})) {
        $self->event([ ALI => { content => $alias }]);
    }
    else {
        my $value = delete $res->{value};
        my $style = $res->{style} // ':';
        if ($style eq ':') {
            if (ref $value) {
                $value = YAML::PP::Render::render_multi_val($value);
            }
            elsif (defined $value) {
                $value =~ s/\\/\\\\/g;
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
        $self->event_value( $res );
    }
}

sub remove_nodes {
    my ($self, $count) = @_;
    my $exp = $self->events->[-1];
    for (1 .. $count) {
        if ($exp eq 'COMPLEX') {
            $self->event_value({ style => ':' });
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

sub parse_plain_multi {
    TRACE and warn "=== parse_plain_multi()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    my @multi;
    my $indent = $self->offset->[ -1 ] + 1;
    my $tokens = $self->tokens;

    my $indent_re = $RE_WS . '{' . $indent . '}';
    while (1) {
        last if not length $$yaml;

        unless ($$yaml =~ s/\A($indent_re)//) {
            last;
        }
        push @$tokens, ['INDENT', $1];

        if ($indent == 0) {
            last if $$yaml =~ $RE_DOC_END;
            last if $$yaml =~ $RE_DOC_START;
        }
        if ($$yaml =~ s/\A($RE_WS+)//) {
            push @$tokens, ['INDENT', $1];
            if ($$yaml =~ s/\A#.*//) {
                last;
            }
        }
        elsif ($$yaml =~ s/\A(#.*)//) {
            push @$tokens, ['COMMENT', $1];
            last;
        }

        if ($$yaml =~ s/\A($RE_LB|\z)//) {
            push @$tokens, ['LB', $1];
            push @multi, '';
        }
        elsif ($$yaml =~ s/\A($plain_word_re)//) {
            my $string = $1;
            push @$tokens, ['PLAIN', $string];
            if ($string =~ m/:$/) {
                die "Unexpected content: '$string'";
            }
            while ($$yaml =~ s/\A($RE_WS+)//) {
                push @$tokens, ['WS', $1];
                my $sp = $1;
                $$yaml =~ s/\A($plain_word_re)// or last;
                push @$tokens, ['PLAIN', $1];
                my $value = $sp . $1;
                if ($value =~ m/:$/) {
                    die "Unexpected content: '$value'";
                }
                $string .= $value;
            }
            push @multi, $string;
            if ($$yaml =~ s/\A(#.*)//) {
                push @$tokens, ['COMMENT', $1];
                last;
            }
            unless ($$yaml =~ s/\A($RE_LB|\z)//) {
                warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
                die "Unexpected content";
            }
            push @$tokens, ['LB', $1];
        }
        else {
            TRACE and $self->debug_yaml;
            die "Unexpected content";
        }
    }
    return {
        eol => 1,
        style => ':',
        value => \@multi,
    };
}

sub parse_empty {
    TRACE and warn "=== parse_empty()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    while (length $$yaml) {
        if ($$yaml =~ s/\A( *#.*)($RE_LB|\z)//) {
            push @{ $self->tokens },
                ['COMMENT', $1],
                ['LB', $2];
        }
        elsif ($$yaml =~ s/\A($RE_WS*)($RE_LB|\z)//) {
            push @{ $self->tokens },
                ['WS', $1],
                ['LB', $2];
        }
        else {
            last;
        }
    }
}

sub parse_block_scalar {
    TRACE and warn "=== parse_block_scalar()\n";
    my ($self, %args) = @_;
    my $yaml = $self->yaml;
    my $tokens = $self->tokens;
    my $indent = $self->offset->[-1] + 1;

    my $block_type = $args{type};
    my $exp_indent;
    my $chomp;
    if ($$yaml =~ s/\A([1-9]\d*)?([+-]?)( +#.*)?($RE_LB|\z)//) {
        $exp_indent = $1;
        push @$tokens, ['BLOCK_SCALAR_INDENT', $1] if $1;
        $chomp = $2;
        push @$tokens, ['BLOCK_SCALAR_CHOMP', $2] if $2;
        push @$tokens, ['COMMENT', $3] if $3;
        push @$tokens, ['LB', $4];
    }
    elsif ($$yaml =~ s/\A([+-]?)([1-9]\d*)?( +#.*)?($RE_LB|\z)//) {
        $chomp = $1;
        push @$tokens, ['BLOCK_SCALAR_CHOMP', $1] if $1;
        $exp_indent = $2;
        push @$tokens, ['BLOCK_SCALAR_INDENT', $2] if $2;
        push @$tokens, ['COMMENT', $3] if $3;
        push @$tokens, ['LB', $4];
    }
    else {
        die "Invalid block scalar";
    }
    if (defined $exp_indent) {
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$exp_indent], ['exp_indent']);
    }
    my @lines;

    my $got_indent = 0;
    if ($exp_indent) {
        $indent = $exp_indent;
        $got_indent = 1;
    }
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$indent], ['indent']);
    my $indent_re = $RE_WS ."{$indent}";
    TRACE and local $Data::Dumper::Useqq = 1;
    my $type;
    while (length $$yaml) {
        TRACE and warn __PACKAGE__.':'.__LINE__.": RE: $indent_re\n";
        TRACE and $self->debug_yaml;
        my $pre;
        my $space;
        my $length;
        last if $$yaml =~ $RE_DOC_START;
        last if $$yaml =~ $RE_DOC_END;
        if ($$yaml =~ s/\A($indent_re)($RE_WS*)//) {
            $pre = $1;
            $space = $2;
            push @$tokens, ['INDENT', $pre];
            push @$tokens, ['WS', $space];
            $length = length $space;
        }
        elsif ($$yaml =~ m/\A$RE_WS*#.*$RE_LB/) {
            last;
        }
        elsif ($$yaml =~ s/\A($RE_WS*)($RE_LB)//) {
            $pre = $1;
            push @$tokens, ['WS', $pre];
            push @$tokens, ['LB', $2];
            $space = '';
            $type = 'EMPTY';
            push @lines, [$type => $pre, $space];
            next;
        }
        else {
            last;
        }
        if ($$yaml =~ s/\A($RE_LB)//) {
            push @$tokens, ['LB', $1];
            $type = 'EMPTY';
            if ($got_indent) {
                push @lines, [$type => $pre, $space];
            }
            else {
                push @lines, [$type => $pre . $space, ''];
            }
            next;
        }
        if ($length and not $got_indent) {
            $indent += $length;
            $indent_re = $RE_WS . "{$indent}";
            $pre = $space;
            $space = '';
            $got_indent = 1;
        }
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
        if ($$yaml =~ s/\A(.*)($RE_LB|\z)//) {
            my $value = $1;
            push @$tokens, ['BLOCK_SCALAR_CONTENT', $value];
            push @$tokens, ['LB', $2];
            $type = length $space ? 'MORE' : 'CONTENT';
            push @lines, [ $type => $pre, $space . $value ];
        }

    }
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@lines], ['lines']);

    my $string = YAML::PP::Render::render_block_scalar(
        block_type => $block_type,
        chomp => $chomp,
        lines => \@lines,
    );

    return { eol => 1, value => $string, style => $block_type };
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

sub event_value {
    my ($self, $args) = @_;

    my $tag = $args->{tag};
    if (defined $tag) {
        my $tag_str = YAML::PP::Render::render_tag($tag, $self->tagmap);
        $args->{tag} = $tag_str;
    }
    $self->event([ VAL => $args]);
}

sub push_events {
    my ($self, $event, $offset) = @_;
    my $level = $self->level;
    $self->set_level( ++$level );
    push @{ $self->events }, $event;
    $self->offset->[ $level ] = $offset;
}

sub pop_events {
    my ($self, $event) = @_;
    $self->set_level($self->level - 1);
    pop @{ $self->offset };

    my $last = pop @{ $self->events };
    return $last unless $event;
    if ($last ne $event) {
        die "pop_events($event): Unexpected event '$last', expected $event";
    }
}

my %event_to_method = (
    MAP => 'mapping',
    SEQ => 'sequence',
    DOC => 'document',
    STR => 'stream',
    VAL => 'scalar',
    ALI => 'alias',
);

sub begin {
    my ($self, $event, $offset, $info) = @_;
    my $content = $info->{content};
    my $event_name = $event;
    $event_name =~ s/^COMPLEX/MAP/;
    my %info = ( type => $event_name );
    if ($event_name eq 'SEQ' or $event_name eq 'MAP') {
        my $anchor = $info->{anchor};
        my $tag = $info->{tag};
        if (defined $tag) {
            my $tag_str = YAML::PP::Render::render_tag($tag, $self->tagmap);
            $info{tag} = $tag_str;
        }
        if (defined $anchor) {
            $info{anchor} = $anchor;
        }
    }
    TRACE and $self->debug_event("------------->> BEGIN $event ($offset) $content");
    $self->callback->($self, $event_to_method{ $event_name } . "_start_event"
        => { %info, content => $content });
    $self->push_events($event, $offset);
    TRACE and $self->debug_events;
}

sub end {
    my ($self, $event, $info) = @_;
    my $content = $info->{content};
    $self->pop_events($event);
    TRACE and $self->debug_event("-------------<< END   $event @{[$content//'']}");
    return if $event eq 'END';
    $self->callback->($self, $event_to_method{ $event } . "_end_event"
        => { type => $event, content => $content });
    if ($event eq 'DOC') {
        $self->set_tagmap({
            '!!' => "tag:yaml.org,2002:",
        });
    }
}

sub event {
    my ($self, $event) = @_;
    TRACE and $self->debug_event("------------- EVENT @{[ $self->event_to_test_suite($event)]}");

    my ($type, $info) = @$event;
    $self->callback->($self, $event_to_method{ $type } . "_event", $info);
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
        if ($ev =~ m/start/) {
            $string = "+$type";
            if (defined $info->{anchor}) {
                $string .= " &$info->{anchor}";
            }
            if (defined $info->{tag}) {
                $string .= " $info->{tag}";
            }
            $string .= " $content" if defined $content;
        }
        elsif ($ev =~ m/end/) {
            $string = "-$type";
            $string .= " $content" if defined $content;
        }
        elsif ($ev eq 'scalar_event') {
            $string = '=VAL';
            if (defined $info->{anchor}) {
                $string .= " &$info->{anchor}";
            }
            if (defined $info->{tag}) {
                $string .= " $info->{tag}";
            }
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
    my $yaml = $self->yaml;
    if (length $$yaml) {
        my $output = $$yaml;
        $output =~ s/( +)$/'·' x length $1/gem;
        $output =~ s/\t/▸/g;
        $self->note("YAML:\n$output\nEOYAML");
    }
    else {
        $self->note("YAML: EMPTY");
    }
}

sub debug_next_line {
    my ($self) = @_;
    my $yaml = $self->yaml;
    my ($line) = $$yaml =~ m/\A(.*)/;
    $self->note("NEXT LINE: $line");
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
    my ($self, $msg) = @_;
    require Term::ANSIColor;
    warn Term::ANSIColor::colored(["magenta"], "============ $msg"), "\n";
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
    for my $rule (@$rules) {
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
            my @keys = sort keys %$rule;
            $self->info("@keys");
        }
    }
}

sub debug_tokens {
    my ($self) = @_;
    my $tokens = $self->tokens;
    require Term::ANSIColor;
    for my $token (@$tokens) {
        my $type = Term::ANSIColor::colored(["green"],
            sprintf "%-20s", $token->[0] . ':'
        );
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Terse = 1;
        require Data::Dumper;
        my $str = Data::Dumper->Dump([$token->[1]], ['str']);
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

sub cb_tag {
    my ($self, $res) = @_;
    my $props = $self->stack->{properties} ||= {};
    $props->{tag} = $self->tokens->[-1]->[1];
}

sub cb_anchor {
    my ($self, $res) = @_;
    my $props = $self->stack->{properties} ||= {};
    my $anchor = $self->tokens->[-1]->[1];
    $anchor = substr($anchor, 1);
    $props->{anchor} = $anchor;
}

sub cb_property_eol {
    my ($self, $res) = @_;
    my $node_props = $self->stack->{node_properties} ||= {};
    my $props = $self->stack->{properties} ||= {};
    if (defined $props->{anchor}) {
        $node_props->{anchor} = delete $props->{anchor};
    }
    if (defined $props->{tag}) {
        $node_props->{tag} = delete $props->{tag};
    }
}

sub cb_ws {
    my ($self, $res, $props) = @_;
    if ($res) {
        $res->{ws} = length $self->tokens->[-1]->[1];
        $res->{eol} = 0;
    }
}

sub cb_eol {
    my ($self, $res) = @_;
    $res->{eol} = 1;
    return;
}

sub cb_mapkey {
    my ($self, $res) = @_;
    my $value = $self->tokens->[-1]->[1];
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ value => undef, {
        style => ':',
        value => $self->tokens->[-1]->[1],
    }];
}

sub cb_empty_mapkey {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ value => undef, {
        style => ':',
        value => undef,
    }];
}

sub cb_mapkeystart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ value => undef, {
            style => ':',
            value => $self->tokens->[-1]->[1],
        }];
    $res->{name} = 'MAPSTART';
}

sub cb_doublequoted_key {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ value => undef, {
        style => '"',
        value => [ $self->tokens->[-1]->[1] ],
    }];
}

sub cb_doublequotedstart {
    my ($self, $res) = @_;
    my $value = $self->tokens->[-1]->[1];
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ value => undef, {
            style => '"',
            value => [ $value ],
        }];
    $res->{name} = 'MAPSTART';
}

sub cb_singlequoted_key {
    my ($self, $res) = @_;
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ value => undef, {
        style => "'",
        value => [ $self->tokens->[-1]->[1] ],
    }];
}

sub cb_singleequotedstart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ value => undef, {
            style => "'",
            value => [ $self->tokens->[-1]->[1] ],
        }];
    $res->{name} = 'MAPSTART';
}

sub cb_mapkey_alias {
    my ($self, $res) = @_;
    my $alias = $self->tokens->[-1]->[1];
    $alias = substr($alias, 1);
    $res->{name} = 'MAPKEY';
    push @{ $self->stack->{events} }, [ alias => undef, {
        alias => $alias,
    }];
}

sub cb_question {
    my ($self, $res) = @_;
    $res->{name} = 'COMPLEX';
}

sub cb_empty_complexvalue {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ value => undef, { style => ':' }];
}

sub cb_questionstart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ begin => 'COMPLEX', { }];
    $res->{name} = 'NOOP';
}

sub cb_complexcolon {
    my ($self, $res) = @_;
    $res->{name} = 'COMPLEXCOLON';
}

sub cb_seqstart {
    my ($self, $res) = @_;
    push @{ $self->stack->{events} }, [ begin => 'SEQ', { }];
    $res->{name} = 'NOOP';
}

sub cb_seqitem {
    my ($self, $res) = @_;
    $res->{name} = 'SEQITEM';
}

sub cb_alias_key_from_stack {
    my ($self, $res) = @_;
    my $stack = delete $self->stack->{res};
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ alias => undef, {
            alias => $stack->{alias},
        }];
    # TODO
    $res->{name} = 'MAPKEY';
}

sub cb_alias_from_stack {
    my ($self, $res) = @_;
    my $stack = delete $self->stack->{res};
    push @{ $self->stack->{events} }, [ alias => undef, {
        alias => $stack->{alias},
    }];
    # TODO
    $res->{name} = 'SCALAR';
    $res->{eol} = 1;
}

sub cb_stack_alias {
    my ($self, $res) = @_;
    my $alias = $self->tokens->[-1]->[1];
    $alias = substr($alias, 1);
    $self->stack->{res} ||= {
        alias => $alias,
    };
}

sub cb_stack_singlequoted_single {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => "'",
        value => [$self->tokens->[-1]->[1]],
    };
}

sub cb_stack_singlequoted {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => "'",
        value => [],
    };
    push @{ $self->stack->{res}->{value} }, $self->tokens->[-1]->[1];
}

sub cb_stack_doublequoted_single {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => '"',
        value => [$self->tokens->[-1]->[1]],
    };
}

sub cb_stack_doublequoted {
    my ($self, $res) = @_;
    $self->stack->{res} ||= {
        style => '"',
        value => [],
    };
    push @{ $self->stack->{res}->{value} }, $self->tokens->[-1]->[1];
}

sub cb_stack_plain {
    my ($self, $res) = @_;
    my $t = $self->tokens->[-1];
    $self->stack->{res} ||= {
        style => ':',
        value => [],
    };
    push @{ $self->stack->{res}->{value} }, $self->tokens->[-1]->[1];
}

sub cb_plain_single {
    my ($self, $res) = @_;
    $res->{name} = 'SCALAR';
    $res->{eol} = 1;
    push @{ $self->stack->{events} }, [ value => undef, {
        style => ':',
        value => $self->stack->{res}->{value},
    }];
    undef $self->stack->{res};
}

sub cb_mapkey_from_stack {
    my ($self, $res) = @_;
    my $stack = $self->stack->{res} || { style => ':', value => undef };
    undef $self->stack->{res};
    push @{ $self->stack->{events} },
        [ begin => 'MAP', { }],
        [ value => undef, {
            %$stack,
        }];
    $res->{name} = 'MAPSTART';

}

sub cb_scalar_from_stack {
    my ($self, $res) = @_;
    my $stack = $self->stack;
    push @{ $self->stack->{events} }, [ value => undef, {
        %{ $self->stack->{res} },
    }];
    undef $self->stack->{res};
    $res->{name} = 'SCALAR';
    $res->{eol} = 1;
}

sub cb_multiscalar_from_stack {
    my ($self, $res) = @_;
    my $stack = $self->stack;
    my $multi = $self->parse_plain_multi;
    my $first = $stack->{res}->{value}->[0];
    $res->{eol} = delete $multi->{eol};
    unshift @{ $multi->{value} }, $first;
    push @{ $stack->{events} }, [ value => undef, {
        %$multi,
    }];
    undef $stack->{res};
    $res->{name} = 'SCALAR';
}

sub cb_block_scalar {
    my ($self, $res) = @_;
    my $type = $self->tokens->[-1]->[1];
    my $block = $self->parse_block_scalar(
        type => $type,
    );
    $res->{eol} = delete $block->{eol};
    push @{ $self->stack->{events} }, [ value => undef, {
        %$block,
    }];
    $res->{name} = 'SCALAR';
}

sub cb_flow_map {
    die "Not Implemented: Flow Style";
}

sub cb_flow_seq {
    die "Not Implemented: Flow Style";
}


1;
