# ABSTRACT: YAML Parser
use strict;
use warnings;
package YAML::PP::Parser;

use YAML::PP::Render;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        receiver => $args{receiver},
    }, $class;
    return $self;
}
sub receiver { return $_[0]->{receiver} }
sub set_receiver { $_[0]->{receiver} = $_[1] }
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

my $WS = '[\t ]';

my $RE_URI_CHAR = '%[0-9a-fA-F]{2}' .'|'. q{[0-9A-Za-z#;/?:@&=+$,_.!*'\(\)\[\]]};

my $key_start_re = '[a-zA-Z0-9%.]';
my $key_content_re = '[a-zA-Z0-9%.\\]"\\\\ -]';
my $key_content_re_dq = '[^"\n\\\\]';
my $key_content_re_sq = q{[^'\n]};
my $key_re = qr{(?:$key_start_re$key_content_re*$key_start_re|$key_start_re?)};
my $key_re_double_quotes = qr{"(?:\\\\|\\[^\n]|$key_content_re_dq)*"};
my $key_re_single_quotes = qr{'(?:\\\\|''|$key_content_re_sq)*'};
my $key_full_re = qr{(?:$key_re_double_quotes|$key_re_single_quotes|$key_re)};

my $plain_start_word_re = '[^*!&\s#][^\n\s]*';
my $plain_word_re = '[^#\n\s][^\n\s]*';

my $tag_re = '(?:[a-zA-Z]|%[0-9a-fA-F]{2})+';
my $full_tag_re = "![a-z]*!$tag_re|!$tag_re|!<(?:$RE_URI_CHAR)+>|!";

my $anchor_start_re = '[a-zA-Z0-9]';
my $anchor_content_re = '[a-zA-Z0-9:]';
my $anchor_re = qr{(?:$anchor_start_re$anchor_content_re*|$anchor_start_re?)};

sub parse {
    my ($self, $yaml) = @_;
    $self->set_yaml(\$yaml);
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

        if ($self->parse_document(start_line => $start_line)) {
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
    if ($$yaml =~ s/\A---(?=$WS|$)//m) {
        $start = 1;
        my $eol = $self->parse_eol;
        unless ($eol) {
            if ($$yaml =~ s/\A$WS+//) {
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
        if ($$yaml =~ s/\A\s*%YAML ?1\.2\s*//) {
            $head = 1;
            next;
        }
        if ($$yaml =~ s/\A\s*%TAG +(![a-z]*!|!) +(tag:\S+|![a-z][a-z-]*)\s*//) {
            $head = 1;
            my $tag_alias = $1;
            my $tag_url = $2;
            $self->tagmap->{ $tag_alias } = $tag_url;
            next;
        }
        last;
    }
    return $head;
}

sub parse_document_end {
    TRACE and warn "=== parse_document_end()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/\A\.\.\.(?= |$)//m) {
        $self->parse_eol or die "Unexpected";
        return 1;
    }
    return 0;
}

use constant GOT_TAG => 1;
use constant GOT_ANCHOR => 2;
sub parse_document {
    TRACE and warn "=== parse_document()\n";
    my ($self, %args) = @_;
    my $yaml = $self->yaml;

    my $start_line = $args{start_line};

    my $next_full_line = 1;
    my $got_tag_anchor = 0;
    my $new_node = [ 'NODE' => 0 ];
    while (1) {
        if ($ENV{YAML_PP_DELAY}) {
            select undef, undef, undef, $ENV{YAML_PP_DELAY};
        }

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

            my $level = $self->level;
            my $eoyaml = not length $$yaml;
            my $end = $eoyaml ? 0 : $self->parse_document_end;
            my $start = ($eoyaml or $end) ? 0 : $$yaml =~ m/\A---(?= |$)/m;
            if ($eoyaml or $end or $start or ($level < 2 and not $new_node)) {
                if ($new_node) {
                    undef $new_node;
                    $self->event_value(':');
                }
                $self->remove_nodes($self->level);
                return $end ? 1 : 0;
            }

            my $space = 0;
            if ($$yaml =~ s/\A( +)//) {
                $space = length $1;
            }

            my $indent = $self->offset->[ -1 ];

            TRACE and $self->info("INDENT: space=$space indent=$indent");

            if ($space > $indent) {
                unless ($new_node) {
                    die "Bad indendation in $exp";
                }
            }
            else {
                my $seq_start = 0;
                if ($$yaml =~ m/\A-($WS|$)/m) {
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
                        $self->event_value(':');
                        $got_tag_anchor = 0;
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
                            die "Expected sequence item";
                        }
                    }


                    if ($self->offset->[-1] != $space) {
                        die "Expected $exp";
                    }
                }
            }

            $offset = $space;
        }
        else {
            TRACE and $self->info("ON SAME LINE: INDENT");
            unless ($new_node) {
                die "Unexpected $new_node is undef";
            }
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
                if ($self->parse_eol) {
                    $start_line = 0;
                    next;
                }
                elsif ($$yaml =~ s/\A$WS+//) {
                    # expect map key or scalar on same line
                    $found_tag_anchor = 1;
                }
            }
        }

        my $res = $self->parse_next(
            start_line => $start_line,
            tag_anchor => $found_tag_anchor,
#            map => ($full_line or $self->events->[-2] ne 'MAP'),
            expected => $exp,
            new_node => $new_node,
        );

        $next_full_line = $res->{eol} ? 1 : 0;

        my $got = $res->{name};
        TRACE and $self->got("GOT $got");

        my $new_offset = $offset + 1 + ($res->{ws} || 0);
        if ($got eq "MAPKEY") {
            if ($new_node) {
                $self->begin('MAP', $offset);
            }
            elsif ($exp eq 'COMPLEX') {
                $self->events->[-1] = 'MAP';
                $self->event_value(':');
            }
            $self->res_to_event($res);
            $new_node = [ 'NODE' => $new_offset ];
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
                $self->event_value(':');
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
        }
        else {
            die "Unexpected res $got";
        }
        $got_tag_anchor = 0;

    }

    TRACE and $self->debug_events;

    return 0;
}

sub parse_next {
    my ($self, %args) = @_;
    my $new_node = $args{new_node};
    my $exp = $args{expected};
    my $res;
    if ($new_node) {
        $res = $self->parse_node(
            %args,
        );
    }
    elsif ($exp eq 'MAP') {
        $res = $self->parse_map()
            || $self->parse_complex();
        $res or die "Expected map item";
    }
    elsif ($exp eq 'SEQ') {
        $res = $self->parse_seq()
            or die "Expected sequence item";
    }
    elsif ($exp eq 'COMPLEX') {
        $res = $self->parse_complex_colon()
            || $self->parse_complex()
            || $self->parse_map();
        $res or die "Expected : or ? or map item";
    }
    else {
        die "Unexpected exp $exp";
    }

    unless (exists $res->{eol}) {
        my $eol = $self->parse_eol;
        $res->{eol} = $eol;
        unless ($eol) {
            my $yaml = $self->yaml;
            $$yaml =~ s/\A($WS+)//
                and $res->{ws} = length $1;
        }
    }
    return $res;
}

sub res_to_event {
    my ($self, $res) = @_;
    if (defined(my $alias = $res->{alias})) {
        $self->event('=ALI', "*$alias");
    }
    elsif (defined(my $value = $res->{value})) {
        my $style = $res->{style} // ':';
        $self->event_value($style . $value,
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
            $self->event_value(':');
            $self->events->[-1] = 'MAP';
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

sub parse_node {
    TRACE and warn "=== parse_node()\n";
    my ($self, %args) = @_;
    my $start_line = $args{start_line};
    $args{map} //= 1;
    my $res;
    if (not $args{start_line} and $res = $self->parse_complex) {
        return $res;
    }
    if (not $args{start_line} and $res = $self->parse_seq) {
        return $res;
    }
    if (not $args{start_line} and $args{map} and $res = $self->parse_map(%args)) {
        return $res;
    }
    if (not $args{tag_anchor} and $res = $self->parse_alias) {
        return $res;
    }
    if ($res = $self->parse_scalar) {
        return $res;
    }
    TRACE and $self->debug_yaml;
    die "Unexpected";
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
        if ($$yaml =~ s/\A($full_tag_re)(?:$WS+&($anchor_re))?(?=$WS|\n)//) {
            $tag = $1;
            $anchor = $2;
        }
        elsif ($$yaml =~ s/\A&($anchor_re)(?:$WS+($full_tag_re))?(?=$WS|\n)//) {
            $anchor = $1;
            $tag = $2;
        }
    }
    elsif ($check_tag) {
        if ($$yaml =~ s/\A($full_tag_re)(?=$WS|\n)//) {
            $tag = $1;
        }
    }
    elsif ($check_anchor) {
        if ($$yaml =~ s/\A&($anchor_re)(?=$WS|\n)//) {
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
    if ($$yaml =~ s/\A\*($anchor_re)//m) {
        my $alias = $1;
        my $space = length $2;
        return { name => 'NODE', alias => $alias };
    }
    return 0;
}

sub parse_seq {
    TRACE and warn "=== parse_seq()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    return unless $$yaml =~ s/\A(-)(?=$WS|$)//m;
    my $res = {
        name => "SEQSTART",
    };
    return $res;

}

sub parse_complex {
    TRACE and warn "=== parse_complex()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    return unless $$yaml =~ s/\A(\?)(?=$WS|$)//m;
    my $res = {
        name => "COMPLEX",
    };
    return $res;

}

sub parse_complex_colon {
    TRACE and warn "=== parse_complex_colon()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    return unless $$yaml =~ s/\A(:)(?=$WS|$)//m;
    my $res = {
        name => "COMPLEXCOLON",
    };
    return $res;

}

sub parse_plain_multi {
    TRACE and warn "=== parse_plain_multi()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    my @multi;
    my $indent = $self->offset->[ -1 ] + 1;
    my $start_space = $indent;

    my $indent_re = $WS . '{' . $indent . '}';
    my $re = $plain_start_word_re;
    while (1) {
        my $space = $start_space;
        $start_space = 0;
        last if not length $$yaml;
        if ($space == 0) {
            unless ($$yaml =~ s/\A$indent_re//) {
                last;
            }
        }
        last if $$yaml =~ m/\A\.\.\.(?= |$)/m;
        last if $$yaml =~ m/\A---(?= |$)/m;
        if ($$yaml =~ s/\A$WS*#.*//) {
            last;
        }

        if ($$yaml =~ s/\A$WS*\n//) {
            push @multi, '';
        }
        elsif ($$yaml =~ s/\A$WS*($re)//) {
            my $string = $1;
            if ($string =~ m/:$/) {
                die "Unexpected content: '$string'";
            }
            $re = $plain_word_re;
            while ($$yaml =~ s/\A($WS+$re)//) {
                my $value = $1;
                if ($value =~ m/:$/) {
                    die "Unexpected content: '$value'";
                }
                $string .= $value;
            }
            push @multi, $string;
            if ($$yaml =~ s/\A$WS+(#.*)//) {
                last;
            }
            unless ($$yaml =~ s/\A$WS*\n//) {
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

    if ($$yaml =~ s/\A\*($anchor_re) +:(?=$WS|$)//m) {
        if (defined $self->anchor or defined $self->tag) {
            die "TODO";
        }
        $alias = $1;
    }
    elsif (not $tag_anchor and
        $$yaml =~ s/\A&($anchor_re)(?: +($full_tag_re))? +($key_full_re) *:(?=$WS|$)//) {
        $anchor = $1;
        $tag = $2;
        $key = $3;
    }
    elsif (not $tag_anchor and
        $$yaml =~ s/\A($full_tag_re)(?: +&($anchor_re))? +($key_full_re) *:(?=$WS|$)//) {
        $tag = $1;
        $anchor = $2;
        $key = $3;
    }
    elsif ($$yaml =~ s/\A($key_full_re) *:(?=$WS|$)//m) {
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
                last unless $$yaml =~ s/\A((?:\\"|[^"\n])*)//;
                $line = $1;
            }
            else {
                last unless $$yaml =~ s/\A((?:''|[^'\n])*)//;
                $line = $1;
            }
            if ($$yaml =~ s/\A\n//) {
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
        last unless $$yaml =~ s/\A *\n//;
    }
}

sub parse_block_scalar {
    TRACE and warn "=== parse_block_scalar()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    unless ($$yaml =~ s/\A([|>])([1-9]\d*)?([+-]?)( +#.*)?\n//) {
        return 0;
    }
    my $block_type = $1;
    my $exp_indent = $2;
    my $chomp = $3;
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
    my $indent_re = $WS ."{$indent}";
    TRACE and local $Data::Dumper::Useqq = 1;
    my $type;
    while (length $$yaml) {
        TRACE and warn __PACKAGE__.':'.__LINE__.": RE: $indent_re\n";
        TRACE and $self->debug_yaml;
        my $pre;
        my $space;
        my $length;
        last if $$yaml =~ m/\A---(?= |$)/m;
        last if $$yaml =~ m/\A\.\.\.(?= |$)/m;
        if ($$yaml =~ s/\A($indent_re)($WS*)//) {
            $pre = $1;
            $space = $2;
            $length = length $space;
        }
        elsif ($$yaml =~ m/\A$WS*#.*\n/) {
            last;
        }
        elsif ($$yaml =~ s/\A($WS*)\n//) {
            $pre = $1;
            $space = '';
            $type = 'EMPTY';
            push @lines, [$type => $pre, $space];
            next;
        }
        else {
            last;
        }
        if ($$yaml =~ s/\A\n//) {
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
            $indent_re = $WS . "{$indent}";
            $pre = $space;
            $space = '';
            $got_indent = 1;
        }
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
        if ($$yaml =~ s/\A(.*)\n//) {
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


sub parse_eol {
    my ($self) = @_;
    my $yaml = $self->yaml;
    $$yaml =~ s/\A$WS+#.*//;
    return $$yaml =~ s/\A$WS*\n// ? 1 : 0;
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
    my ($self, $value, %args) = @_;
    my $anchor = $self->anchor // $args{anchor};
    my $tag = $self->tag // $args{tag};
    my $event = $value;

    if (defined $tag) {
        my $tag_str = YAML::PP::Render::render_tag($tag, $self->tagmap);
        $event = "$tag_str $event";
        $self->set_tag(undef);
    }
    if (defined $anchor) {
        $self->set_anchor(undef);
        $event = "&$anchor $event";
    }
    $self->event("=VAL", "$event");
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
    if ($event_name eq 'SEQ' or $event_name eq 'MAP') {
        my $anchor = $self->anchor;
        my $tag = $self->tag;
        if (defined $tag) {
            $self->set_tag(undef);
            my $tag_str = YAML::PP::Render::render_tag($tag, $self->tagmap);
            unshift @content, $tag_str;
        }
        if (defined $anchor) {
            $self->set_anchor(undef);
            unshift @content, "&$anchor";
        }
    }
    TRACE and $self->debug_event("------------->> BEGIN $event ($offset) @content");
    $self->receiver->($self, "+$event_name", @content ? "@content" : undef);
    $self->push_events($event, $offset);
    TRACE and $self->debug_events;
}

sub end {
    my ($self, $event, @content) = @_;
    $self->pop_events($event);
    TRACE and $self->debug_event("-------------<< END   $event @content");
    return if $event eq 'END';
    $self->receiver->($self, "-$event", @content);
    if ($event eq 'DOC') {
        $self->set_tagmap({
            '!!' => "tag:yaml.org,2002:",
        });
    }
}

sub event {
    my ($self, $event, @content) = @_;
    TRACE and $self->debug_event("------------- EVENT $event @content");

    $self->receiver->($self, $event, @content);
}

sub event_to_test_suite {
    my ($self, $event, $content) = @_;
    return defined $content ? "$event $content" : $event;
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
        . join (' | ', map { defined ? sprintf "%-3d", $_ : '?' } @{ $_[0]->offset })
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
