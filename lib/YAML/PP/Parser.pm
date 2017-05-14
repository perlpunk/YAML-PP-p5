# ABSTRACT: YAML Parser
use strict;
use warnings;
package YAML::PP::Parser;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Render;

sub new {
    my ($class, %args) = @_;
    my $reader = delete $args{reader};
    my $self = bless {
        reader => $reader,
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
            $event = lc $event;
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

    {
        package
         Reader;
        sub read {
            $_[0]->{input};
        }
        sub new {
            my ($class, %args) = @_;
            return bless { %args }, $class;
        }
    }

    my $input = $self->{input} // die;

    return Reader->new(input => $input);
}
sub input { return($_[0]->{receiver} // die "No input") }
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
sub anchor { return $_[0]->{anchor} }
sub set_anchor { $_[0]->{anchor} = $_[1] }
sub tag { return $_[0]->{tag} }
sub set_tag { $_[0]->{tag} = $_[1] }
sub tagmap { return $_[0]->{tagmap} }
sub set_tagmap { $_[0]->{tagmap} = $_[1] }

use constant TRACE => $ENV{YAML_PP_TRACE};

my $RE_WS = '[\t ]';
my $RE_LB = '[\r\n]';
my $RE_DOC_END = qr/\A\.\.\.(?=$RE_WS|$)/m;
my $RE_DOC_START = qr/\A---(?=$RE_WS|$)/m;
my $RE_EOL = qr/\A($RE_WS+#.*|$RE_WS+)?$RE_LB/;

#ns-word-char    ::= ns-dec-digit | ns-ascii-letter | “-”
my $RE_NS_WORD_CHAR = '[0-9A-Za-z-]';
my $RE_URI_CHAR = '(?:' . '%[0-9a-fA-F]{2}' .'|'.  q{[0-9A-Za-z#;/?:@&=+$,_.!*'\(\)\[\]-]} . ')';
my $RE_NS_TAG_CHAR = '(?:' . '%[0-9a-fA-F]{2}' .'|'.  q{[0-9A-Za-z#;/?:@&=+$_.*'\(\)-]} . ')';

#  [#x21-#x7E]          /* 8 bit */
# | #x85 | [#xA0-#xD7FF] | [#xE000-#xFFFD] /* 16 bit */
# | [#x10000-#x10FFFF]                     /* 32 bit */

#nb-char ::= c-printable - b-char - c-byte-order-mark
#my $RE_NB_CHAR = '[\x21-\x7E]';
my $RE_ANCHOR_CAR = '[\x21-\x2B\x2D-\x5A\x5C\x5E-\x7A\x7C\x7E]';

my $RE_PLAIN_START = '[\x21\x22\x24-\x7E]';
my $RE_PLAIN = '[\x21-\x7E]';
my $RE_PLAIN_END = '[\x21-\x39\x3B-\x7E]';
my $RE_PLAIN_FIRST = '[\x24\x28-\x29\x2B\x2E-\x3D\x41-\x5A\x5C\x5E-\x5F\x61-\x7A\x7E]';
# c-indicators
#! 21
#" 22
## 23
#% 25
#& 26
#' 27
#* 2A
#, 2C FLOW
#- 2D XX
#: 3A XX
#> 3E
#? 3F XX
#@ 40
#[ 5B FLOW
#] 5D FLOW
#` 60
#{ 7B FLOW
#| 7C
#} 7D FLOW


our $RE_INT = '[+-]?[1-9]\d*';
our $RE_OCT = '0o[1-7][0-7]*';
our $RE_HEX = '0x[1-9a-fA-F][0-9a-fA-F]*';
our $RE_FLOAT = '[+-]?(?:\.\d+|\d+\.\d*)(?:[eE][+-]?\d+)?';
our $RE_NUMBER ="'(?:$RE_INT|$RE_OCT|$RE_HEX|$RE_FLOAT)";

my $RE_PLAIN_WORD = "$RE_PLAIN_START(?:$RE_PLAIN_END|$RE_PLAIN*$RE_PLAIN_END)?";
my $RE_PLAIN_FIRST_WORD1 = "(?:[:?-]$RE_PLAIN*$RE_PLAIN_END)";
my $RE_PLAIN_FIRST_WORD2 = "(?:$RE_PLAIN_FIRST$RE_PLAIN*$RE_PLAIN_END)";
my $RE_PLAIN_FIRST_WORD3 = "(?:$RE_PLAIN_FIRST$RE_PLAIN_END?)";
my $RE_PLAIN_FIRST_WORD = "(?:$RE_PLAIN_FIRST_WORD1|$RE_PLAIN_FIRST_WORD2|$RE_PLAIN_FIRST_WORD3)";
my $RE_PLAIN_KEY = "(?:$RE_PLAIN_FIRST_WORD(?:$RE_WS+$RE_PLAIN_WORD)*|)";
my $key_content_re_dq = '[^"\r\n\\\\]';
my $key_content_re_sq = q{[^'\r\n]};
my $key_re_double_quotes = qr{"(?:\\\\|\\[^\r\n]|$key_content_re_dq)*"};
my $key_re_single_quotes = qr{'(?:\\\\|''|$key_content_re_sq)*'};
my $key_full_re = qr{(?:$key_re_double_quotes|$key_re_single_quotes|$RE_PLAIN_KEY)};

my $plain_start_word_re = '[^*!&\s#][^\r\n\s]*';
my $plain_word_re = '[^#\r\n\s][^\r\n\s]*';


#c-secondary-tag-handle  ::= “!” “!”
#c-named-tag-handle  ::= “!” ns-word-char+ “!”
#ns-tag-char ::= ns-uri-char - “!” - c-flow-indicator
#ns-global-tag-prefix    ::= ns-tag-char ns-uri-char*
#c-ns-local-tag-prefix   ::= “!” ns-uri-char*
my $RE_TAG = "!(?:$RE_NS_WORD_CHAR*!$RE_NS_TAG_CHAR+|$RE_NS_TAG_CHAR+|<$RE_URI_CHAR+>|)";

#c-ns-anchor-property    ::= “&” ns-anchor-name
#ns-char ::= nb-char - s-white
#ns-anchor-char  ::= ns-char - c-flow-indicator
#ns-anchor-name  ::= ns-anchor-char+
my $RE_ANCHOR = "$RE_ANCHOR_CAR+";

my $RE_SEQSTART = qr/\A(-)(?=$RE_WS|$)/m;
my $RE_COMPLEX = qr/\A(\?)(?=$RE_WS|$)/m;
my $RE_COMPLEXCOLON = qr/\A(:)(?=$RE_WS|$)/m;
my $RE_ALIAS = qr/\A\*($RE_ANCHOR)/m;

sub parse {
    my ($self, $yaml) = @_;
    if (defined $yaml) {
        $self->{input} = $yaml;
    }
    $self->set_yaml(\$self->reader->read);
    $self->set_level(-1);
    $self->set_offset([0]);
    $self->set_events([]);
    $self->set_anchor(undef);
    $self->set_tag(undef);
    $self->set_tagmap({
        '!!' => "tag:yaml.org,2002:",
    });
    $self->parse_stream;
}

sub parse_stream {
    TRACE and warn "=== parse_stream()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    $self->begin('STR', -1);

    TRACE and $self->debug_yaml;

    my $exp_start = 0;
    while (length $$yaml) {
        $self->parse_empty;
        my $head = $self->parse_document_head();
        my ($start, $start_line) = $self->parse_document_start;
        if (($head or $exp_start) and not $start) {
            die "Expected ---";
        }
        $exp_start = 0;
        $self->parse_empty;
        last unless length $$yaml;

        if ($start) {
            $self->begin('DOC', -1, "---");
        }
        else {
            $self->begin('DOC', -1);
        }

        my $new_node = [ ($start_line ? 'STARTNODE' : 'NODE') => 0 ];
        my ($end) = $self->parse_document($new_node);
        if ($end) {
            $self->end('DOC', "...");
        }
        else {
            $exp_start = 1;
            $self->end('DOC');
        }

    }
    $self->parse_empty;

    $self->end('STR');
}

sub parse_document_start {
    TRACE and warn "=== parse_document_start()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;

    my ($start, $start_line) = (0, 0);
    if ($$yaml =~ s/$RE_DOC_START//) {
        $start = 1;
        my $eol = $$yaml =~ s/\A($RE_EOL|\z)//;
        unless ($eol) {
            if ($$yaml =~ s/\A$RE_WS+//) {
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
    my $head;
    while (length $$yaml) {
        $self->parse_empty;
        if ($$yaml =~ s/\A\s*%YAML ?1\.2$RE_WS*//) {
            $head = 1;
            next;
        }
        if ($$yaml =~ s/\A\s*%TAG +(!$RE_NS_WORD_CHAR*!|!) +(tag:\S+|!$RE_URI_CHAR+)$RE_WS*//) {
            $head = 1;
            my $tag_alias = $1;
            my $tag_url = $2;
            $self->tagmap->{ $tag_alias } = $tag_url;
            next;
        }
        if ($$yaml =~ s/\s*\A%(\w+).*//) {
            warn "Found reserved directive '$1'";
            $head = 1;
            next;
        }
        last;
    }
    return $head;
}

use constant GOT_TAG => 1;
use constant GOT_ANCHOR => 2;
sub parse_document {
    TRACE and warn "=== parse_document()\n";
    my ($self, $new_node) = @_;

    my $next_full_line = 1;
    my $got_tag_anchor = 0;
    while (1) {

        TRACE and $self->info("----------------------- LOOP");
        TRACE and $self->info("EXPECTED: (@$new_node)") if $new_node;
        TRACE and $self->debug_yaml;
        TRACE and $self->debug_events;

        my $exp = $self->events->[-1];
        my $offset;
        my $full_line = $next_full_line;
        $next_full_line = 1;
        if ($full_line) {
            $self->parse_empty;

            my $end;
            my $explicit_end;
            ($exp, $new_node, $offset, $end, $explicit_end) = $self->check_indent(
                expected => $exp,
                new_node => $new_node,
            );
            if ($explicit_end) {
                return 1;
            }
            if ($end) {
                return;
            }
            unless ($new_node) {
                $got_tag_anchor = 0;
            }

        }
        else {
            TRACE and $self->info("ON SAME LINE: INDENT");
            $offset = $new_node->[1];
        }

        TRACE and $self->info("Expecting $exp");

        my $found_tag_anchor;
        if ($new_node and $got_tag_anchor < 3) {
            my ($tag, $anchor) = $self->parse_tag_anchor(
                tag => (not defined $self->tag),
                anchor => (not defined $self->anchor),
            );
            if ($tag or $anchor) {
                $got_tag_anchor += GOT_TAG if $tag;
                $got_tag_anchor += GOT_ANCHOR if $anchor;
                my $yaml = $self->yaml;
                if ($$yaml =~ s/$RE_EOL//) {
                    if ($new_node->[0] eq 'STARTNODE') {
                        $new_node->[0] = 'NODE';
                    }
                    next;
                }
                elsif ($$yaml =~ s/\A$RE_WS+//) {
                    # expect map key or scalar on same line
                    $found_tag_anchor = 1;
                }
            }
        }

        my $res = $self->parse_next(
            tag_anchor => $found_tag_anchor,
            expected => $exp,
            new_node => $new_node,
        );

        ($new_node) = $self->process_result(
            result => $res,
            offset => $offset,
            new_node => $new_node,
            expected => $exp,
        );

        $next_full_line = $res->{eol} ? 1 : 0;
        $got_tag_anchor = 0;
    }

    TRACE and $self->debug_events;

    return 0;
}

sub check_indent {
    my ($self, %args) = @_;
    my $exp = $args{expected};
    my $new_node = $args{new_node};
    my $yaml = $self->yaml;
    my $end = 0;
    my $explicit_end = 0;
    my $offset;
    my $space = 0;
    my $indent = 0;

    my $eoyaml = not length $$yaml;
    if ($eoyaml) {
        $end = 1;
    }
    else {
        if ($$yaml =~ s/\A( +)//) {
            $space = length $1;
        }

        $indent = $self->offset->[ -1 ];
        if ($indent == -1 and $space == 0 and not $new_node) {
            $space = -1;
        }
    }

    TRACE and $self->info("INDENT: space=$space indent=$indent");

    if ($space > $indent) {
        unless ($new_node) {
            die "Bad indendation in $exp";
        }
    }
    else {

        if ($space <= 0) {
            unless ($end) {
                if ($$yaml =~ s/$RE_DOC_END//) {
                    $$yaml =~ s/$RE_EOL|\z// or die "Unexpected";
                    $end = 1;
                    $explicit_end = 1;
                }
                elsif ($$yaml =~ $RE_DOC_START) {
                    $end = 1;
                }
                elsif ($self->level < 2 and not $new_node) {
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
                undef $new_node;
                $self->event_value(style => ':');
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

    $offset = $space;
    if ($new_node) {
        if ($new_node->[0] eq 'MAPVALUE') {
            $new_node->[0] = 'NODE';
        }
    }

    return ($exp, $new_node, $offset, $end, $explicit_end);
}

sub process_result {
    my ($self, %args) = @_;
    my $res = $args{result};
    my $offset = $args{offset};
    my $new_node = $args{new_node};
    my $exp = $args{expected};

    my $got = $res->{name};
    TRACE and $self->got("GOT $got");

    my $new_offset = $offset + 1 + ($res->{ws} || 0);
    if ($got eq "MAPKEY") {
        if ($new_node) {
            $self->begin('MAP', $offset);
        }
        elsif ($exp eq 'COMPLEX') {
            $self->events->[-1] = 'MAP';
            $self->event_value(style => ':');
        }
        $self->res_to_event($res);
        $new_node = [ 'MAPVALUE' => $new_offset ];
    }
    elsif ($got eq 'SEQSTART') {
        if ($new_node) {
            $self->begin('SEQ', $offset);
        }
        $new_node = [ 'NODE' => $new_offset ];
    }
    elsif ($got eq 'COMPLEX') {
        if ($new_node) {
            $self->begin('COMPLEX', $offset);
        }
        elsif ($exp eq 'MAP') {
            $self->events->[-1] = 'COMPLEX';
        }
        elsif ($exp eq 'COMPLEX') {
            $self->event_value(style => ':');
        }
        $new_node = [ 'NODE' => $new_offset ];
    }
    elsif ($got eq 'COMPLEXCOLON') {
        $self->events->[-1] = 'MAP';
        $new_node = [ 'NODE' => $new_offset ];
    }
    elsif ($got eq 'NODE') {
        $self->res_to_event($res);
        undef $new_node;
        if (not $res->{eol}) {
            die "Expected EOL";
        }
    }
    else {
        die "Unexpected res $got";
    }
    return $new_node;
}

sub parse_next {
    TRACE and warn "=== parse_next()\n";
    my ($self, %args) = @_;
    my $new_node = delete $args{new_node};
    my $exp = delete $args{expected};
    my $res;
    my @possible;
    my $in_map;
    if ($new_node) {
        $in_map = $new_node->[0] eq 'MAPVALUE' ? 1 : 0;
        if ($new_node->[0] ne 'STARTNODE') {
            push @possible, [$RE_SEQSTART, 'SEQSTART'];
            push @possible, [$RE_COMPLEX, 'COMPLEX'];
            push @possible, 'parse_map';
        }
        if (not $args{tag_anchor}) {
            push @possible, 'parse_alias';
        }
        push @possible, 'parse_scalar';
    }
    elsif ($exp eq 'MAP') {
        push @possible, [$RE_COMPLEX, 'COMPLEX'];
        push @possible, 'parse_map';
    }
    elsif ($exp eq 'SEQ') {
        push @possible, [$RE_SEQSTART, 'SEQSTART'];
    }
    elsif ($exp eq 'COMPLEX') {
        push @possible, [$RE_COMPLEXCOLON, 'COMPLEXCOLON'];
        push @possible, [$RE_COMPLEX, 'COMPLEX'];
        push @possible, 'parse_map';
    }
    else {
        die "Unexpected exp $exp";
    }

    my $yaml = $self->yaml;
    for my $method (@possible) {
        if (ref $method eq 'ARRAY') {
            my ($re, $name) = @$method;
            if ($$yaml =~ s/$re//) {
                $res = { name => $name };
                last;
            }
        }
        else {
            $res = $self->$method(%args) and last;
        }
    }
    unless ($res) {
        TRACE and $self->debug_yaml;
        die "Expected " . ($new_node ? "new node" : $exp);
    }
    if ($in_map and $res->{name} =~ m/MAP|SEQ|COMPLEX/) {
        die "Parse error: $res->{name} not allowed in this context";
    }

    unless (exists $res->{eol}) {
        my $yaml = $self->yaml;
        my $eol = $$yaml =~ s/\A($RE_EOL|$RE_WS*\z)//;
        $res->{eol} = $eol;
        unless ($eol) {
            $$yaml =~ s/\A($RE_WS+)//
                and $res->{ws} = length $1;
        }
    }
    return $res;
}

sub res_to_event {
    my ($self, $res) = @_;
    if (defined(my $alias = $res->{alias})) {
        $self->event([ alias => { content => $alias }]);
    }
    elsif (defined(my $value = $res->{value})) {
        my $style = $res->{style} // ':';
        $self->event_value(
            content => $value,
            style => $style,
            tag => $res->{tag},
            anchor => $res->{anchor},
        );
    }
}

sub remove_nodes {
    my ($self, $count) = @_;
    my $exp = $self->events->[-1];
    for (1 .. $count) {
        if ($exp eq 'COMPLEX') {
            $self->event_value(style => ':');
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
    my $count = 0;
    while ($i > 1) {
        my $test_indent = $off->[ $i ];
        if ($test_indent == $space) {
            last;
        }
        elsif ($test_indent <= $space) {
            last;
        }
        $count++;
        $i--;
    }
    return $count;
}

my %scalar_methods = (
    '[' => \&parse_flow,
    '{' => \&parse_flow,
    '|' => \&parse_block_scalar,
    '>' => \&parse_block_scalar,
    '"' => \&parse_quoted,
    "'" => \&parse_quoted,
);
sub parse_scalar {
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ m/\A([\[\{>|'"])/) {
        my $method = $scalar_methods{ $1 };
        my $res = $self->$method;
        return $res;
    }
    elsif (my $res = $self->parse_plain_multi) {
        return $res;
    }
    return 0;
}

sub parse_flow {
    my ($self) = @_;
    my $yaml= $self->yaml;
    TRACE and warn "=== parse_flow()\n";
    if ($$yaml =~ m/\A[\{\[]/) {
        die "Not Implemented: Flow Style";
    }
    return 0;
}

sub parse_tag_anchor {
    TRACE and warn "=== parse_tag_anchor()\n";
    my ($self, %args) = @_;
    my $yaml = $self->yaml;
    my $check_anchor = $args{anchor} // 1;
    my $check_tag = $args{tag} // 1;
    my ($tag, $anchor);
    if ($check_anchor and $check_tag) {
        if ($$yaml =~
        s/\A($RE_TAG)(?:$RE_WS+&($RE_ANCHOR))?(?=$RE_WS|$RE_LB|\z)//) {
            $tag = $1;
            $anchor = $2;
        }
        elsif ($$yaml =~
        s/\A&($RE_ANCHOR)(?:$RE_WS+($RE_TAG))?(?=$RE_WS|$RE_LB|\z)//) {
            $anchor = $1;
            $tag = $2;
        }
    }
    elsif ($check_tag) {
        if ($$yaml =~ s/\A($RE_TAG)(?=$RE_WS|$RE_LB|\z)//) {
            $tag = $1;
        }
    }
    elsif ($check_anchor) {
        if ($$yaml =~ s/\A&($RE_ANCHOR)(?=$RE_WS|$RE_LB|\z)//) {
            $anchor = $1;
        }
    }
    if (defined $tag) {
        TRACE and $self->got("GOT TAG $tag");
        $self->set_tag($tag);
    }
    if (defined $anchor) {
        TRACE and $self->got("GOT ANCHOR $anchor");
        $self->set_anchor($anchor);
    }
    return (defined $tag, defined $anchor);

}

sub parse_alias {
    TRACE and warn "=== parse_alias()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/$RE_ALIAS//m) {
        my $alias = $1;
        return { name => 'NODE', alias => $alias };
    }
    return 0;
}

sub parse_plain_multi {
    TRACE and warn "=== parse_plain_multi()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    my @multi;
    my $indent = $self->offset->[ -1 ] + 1;
    my $start_space = $indent;

    my $indent_re = $RE_WS . '{' . $indent . '}';
    my $re = $plain_start_word_re;
    while (1) {
        my $space = $start_space;
        $start_space = 0;
        last if not length $$yaml;
        if ($space == 0) {
            unless ($$yaml =~ s/\A$indent_re//) {
                last;
            }
            last if $$yaml =~ $RE_DOC_END;
            last if $$yaml =~ $RE_DOC_START;
        }
        if ($$yaml =~ s/\A$RE_WS+//) {
            if ($$yaml =~ s/\A#.*//) {
                last;
            }
        }

        if ($$yaml =~ s/\A($RE_LB|\z)//) {
            push @multi, '';
        }
        elsif ($$yaml =~ s/\A($re)//) {
            my $string = $1;
            if ($string =~ m/:$/) {
                die "Unexpected content: '$string'";
            }
            $re = $plain_word_re;
            while ($$yaml =~ s/\A($RE_WS+)//) {
                my $sp = $1;
                $$yaml =~ s/\A($re)// or last;
                my $value = $sp . $1;
                if ($value =~ m/:$/) {
                    die "Unexpected content: '$value'";
                }
                $string .= $value;
            }
            push @multi, $string;
            if ($$yaml =~ s/\A(#.*)//) {
                last;
            }
            unless ($$yaml =~ s/\A($RE_LB|\z)//) {
                warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
                die "Unexpected content";
            }
        }
        else {
            die "Unexpected content";
        }
    }
    my $string = YAML::PP::Render::render_multi_val(\@multi);
    return {
        name => 'NODE',
        eol => 1,
        style => ':',
        value => $string,
    };
}

sub parse_map {
    my ($self, %args) = @_;
    my $yaml = $self->yaml;
    TRACE and warn "=== parse_map()\n";
    my $tag_anchor = $args{tag_anchor};

    my $key;
    my $key_style = ':';
    my $alias;

    my ($tag, $anchor);

    if ($$yaml =~ s/\A\*($RE_ANCHOR) +:(?=$RE_WS|$)//m) {
        if (defined $self->anchor or defined $self->tag) {
            die "TODO";
        }
        $alias = $1;
    }
    elsif (not $tag_anchor and
        $$yaml =~ s/\A&($RE_ANCHOR)(?: +($RE_TAG))? +($key_full_re) *:(?=$RE_WS|$)//) {
        $anchor = $1;
        $tag = $2;
        $key = $3;
    }
    elsif (not $tag_anchor and
        $$yaml =~ s/\A($RE_TAG)(?: +&($RE_ANCHOR))? +($key_full_re) *:(?=$RE_WS|$)//) {
        $tag = $1;
        $anchor = $2;
        $key = $3;
    }
    elsif ($$yaml =~ s/\A($key_full_re) *:(?=$RE_WS|$)//m) {
        $key = $1;
    }
    else {
        return 0;
    }

    my $res = {
        name => "MAPKEY",
    };
    if ($alias) {
        $res->{alias} = $alias;
    }
    else {
        if ($key =~ s/^(["'])(.*)\1$/$2/) {
            $key_style = $1;
        }
        if ($key_style ne '"') {
            $key =~ s/\\/\\\\/g;
        }
        if ($tag_anchor) {
            $anchor = $self->anchor and $self->set_anchor(undef);
            $tag = $self->tag and $self->set_tag(undef);
        }
        $res->{value} = $key;
        $res->{style} = $key_style;
        $res->{tag} = $tag,
        $res->{anchor} = $anchor;
    }
    return $res;
}

sub parse_quoted {
    TRACE and warn "=== parse_quoted()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/\A(["'])//) {
        my $quote = $1;
        my $double = $quote eq '"';
        my $last = 0;
        my @lines;
        while (1) {
            my $line;
            if ($double) {
                last unless $$yaml =~ s/\A((?:\\"|[^"\r\n])*)//;
                $line = $1;
            }
            else {
                last unless $$yaml =~ s/\A((?:''|[^'\r\n])*)//;
                $line = $1;
            }
            if ($$yaml =~ s/\A$RE_LB//) {
                # next line
            }
            elsif ($$yaml =~ s/\A$quote//) {
                $last = 1;
            }
            else {
                die "Couldn't parse $quote quoted string";
            }
            push @lines, $line;
            last if $last;
        }

        my $quoted = YAML::PP::Render::render_quoted(
            double => $double,
            lines => \@lines,
        );

        return { name => 'NODE', style => $quote, value => $quoted };
    }
    return 0;
}

sub parse_empty {
    TRACE and warn "=== parse_empty()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    while (length $$yaml) {
        $$yaml =~ s/\A *#.*//;
        last unless $$yaml =~ s/\A$RE_WS*(?:$RE_LB|\z)//;
    }
}

sub parse_block_scalar {
    TRACE and warn "=== parse_block_scalar()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;

    my $block_type;
    my $exp_indent;
    my $chomp;
    if ($$yaml =~ s/\A([|>])([1-9]\d*)?([+-]?)( +#.*)?($RE_LB|\z)//) {
        $block_type = $1;
        $exp_indent = $2;
        $chomp = $3;
    }
    elsif ($$yaml =~ s/\A([|>])([+-]?)([1-9]\d*)?( +#.*)?($RE_LB|\z)//) {
        $block_type = $1;
        $chomp = $2;
        $exp_indent = $3;
    }
    else {
        return 0;
    }
    if (defined $exp_indent) {
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$exp_indent], ['exp_indent']);
    }
    my @lines;

    my $indent = $self->offset->[-1] + 1;
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
            $length = length $space;
        }
        elsif ($$yaml =~ m/\A$RE_WS*#.*$RE_LB/) {
            last;
        }
        elsif ($$yaml =~ s/\A($RE_WS*)$RE_LB//) {
            $pre = $1;
            $space = '';
            $type = 'EMPTY';
            push @lines, [$type => $pre, $space];
            next;
        }
        else {
            last;
        }
        if ($$yaml =~ s/\A$RE_LB//) {
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

    return { name => 'NODE', eol => 1, value => $string, style => $block_type };
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
    my ($self, %args) = @_;
    my $value = $args{content};
    my $anchor = $self->anchor // $args{anchor};
    my $tag = $self->tag // $args{tag};
    my $style = $args{style};

    my %info = ( style => $style );
    if (defined $tag) {
        my $tag_str = YAML::PP::Render::render_tag($tag, $self->tagmap);
        $info{tag} = $tag_str;
        $self->set_tag(undef);
    }
    if (defined $anchor) {
        $self->set_anchor(undef);
        $info{anchor} = $anchor;
    }
    $self->event([ value => { content => $value, %info, }]);
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

sub begin {
    my ($self, $event, $offset, @content) = @_;
    my $event_name = $event;
    $event_name =~ s/^COMPLEX/MAP/;
    my %info = ( type => $event_name );
    if ($event_name eq 'SEQ' or $event_name eq 'MAP') {
        my $anchor = $self->anchor;
        my $tag = $self->tag;
        if (defined $tag) {
            $self->set_tag(undef);
            my $tag_str = YAML::PP::Render::render_tag($tag, $self->tagmap);
            $info{tag} = $tag_str;
        }
        if (defined $anchor) {
            $self->set_anchor(undef);
            $info{anchor} = $anchor;
        }
    }
    TRACE and $self->debug_event("------------->> BEGIN $event ($offset) @content");
    $self->callback->($self, "begin_" . (lc $event_name) => { %info, content => $content[0] });
    $self->push_events($event, $offset);
    TRACE and $self->debug_events;
}

sub end {
    my ($self, $event, $content) = @_;
    $self->pop_events($event);
    TRACE and $self->debug_event("-------------<< END   $event @{[$content//'']}");
    return if $event eq 'END';
    $self->callback->($self, "end_" . (lc $event), => { type => $event, content => $content });
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
    $self->callback->($self, lc $type, $info);
}

sub event_to_test_suite {
    my ($self, $event) = @_;
    if (ref $event) {
        my ($ev, $info) = @$event;
        my $string;
        my $type = $info->{type};
        my $content = $info->{content};
        if ($ev =~ m/^begin/) {
            $string = "+$type";
            if (defined $info->{anchor}) {
                $string .= " &$info->{anchor}";
            }
            if (defined $info->{tag}) {
                $string .= " $info->{tag}";
            }
            $string .= " $content" if defined $content;
        }
        elsif ($ev =~ m/^end_/) {
            $string = "-$type";
            $string .= " $content" if defined $content;
        }
        elsif ($ev eq 'value') {
            $string = '=VAL';
            if (defined $info->{anchor}) {
                $string .= " &$info->{anchor}";
            }
            if (defined $info->{tag}) {
                $string .= " $info->{tag}";
            }
            $string .= ' ' . $info->{style} . ($content // '');
        }
        elsif ($ev eq 'alias') {
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

1;
