# ABSTRACT: YAML Parser
use strict;
use warnings;
package YAML::PP::Parser;

use Moo;

has receiver => ( is => 'rw' );
has yaml => ( is => 'rw' );
has indent => ( is => 'rw', default => 0 );
has level => ( is => 'rw', default => -1 );
has offset => ( is => 'rw', default => sub { [0] } );
has events => ( is => 'rw', default => sub { [] } );
has anchor => ( is => 'rw' );
has node_anchor => ( is => 'rw' );
has tag => ( is => 'rw' );
has node_tag => ( is => 'rw' );
has value => ( is => 'rw' );
has tagmap => ( is => 'rw', default => sub { +{
    '!!' => "tag:yaml.org,2002:",
} } );

use constant TRACE => $ENV{YAML_PP_TRACE};

my $WS = '[\t ]';

my $key_start_re = '[a-zA-Z0-9%]';
my $key_content_re = '[a-zA-Z0-9%\]" -]';
my $key_content_re_dq = '[^"\n\\\\]';
my $key_content_re_sq = q{[^'\n]};
my $key_re = qr{(?:$key_start_re$key_content_re*$key_start_re|$key_start_re?)};
my $key_re_double_quotes = qr{"(?:\\\\|\\[^\n]|$key_content_re_dq)*"};
my $key_re_single_quotes = qr{'(?:\\\\|''|$key_content_re_sq)*'};
my $key_full_re = qr{(?:$key_re_double_quotes|$key_re_single_quotes|$key_re)};

my $plain_value_start_re = '[^\s*!&]';

my $tag_re = '[a-zA-Z]+';
my $full_tag_re = "![a-z]*!$tag_re|!$tag_re|!";

my $anchor_start_re = '[a-zA-Z0-9]';
my $anchor_content_re = '[a-zA-Z0-9:]';
my $anchor_re = qr{(?:$anchor_start_re$anchor_content_re*|$anchor_start_re?)};

sub parse {
    my ($self, $yaml) = @_;
    $self->yaml(\$yaml);
    $self->level(-1);
    $self->offset([0]);
    $self->events([]);
    $self->anchor(undef);
    $self->node_anchor(undef);
    $self->tag(undef);
    $self->node_tag(undef);
    $self->value(undef);
    $self->tagmap({
        '!!' => "tag:yaml.org,2002:",
    });
    $self->parse_stream;
}

sub parse_stream {
    TRACE and warn "=== parse_stream()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    $self->begin("STR");

    my $close = 1;
    my $need_explicit_start = 0;
    while (length $$yaml) {
        my $head = $self->parse_document_head(explicit => $need_explicit_start);
        $need_explicit_start = 0;
        last unless length $$yaml;

        my $parse_end = 0;
        if ($head) {
            $parse_end = $self->parse_document_start;
        }
        elsif (not $self->level) {
            $self->begin("DOC");
            $self->offset->[ $self->level ] = 0;
        }

        if ($parse_end) {
            # we found a node on the --- line
            my $end = $self->parse_document_end;
            if ($end) {
                $self->end_document(explicit => 1);
            }
            else {
                $need_explicit_start = 1;
            }
            next;
        }

        my ($end, $need_end) = $self->parse_document;
        if ($end) {
            $self->end_document(explicit => 1);
            next;
        }
        if ($self->in('DOC')) {

            if (length $$yaml) {
                $need_explicit_start = 1;
                unless ($need_end) {
                    $self->end_document(explicit => 0);
                    $self->parse_empty;
                }
                next;
            }
            $self->end_document(explicit => 0);
            last;
        }

        if (not length $$yaml) {
            $self->end_document(explicit => 0);
            last;
        }

    }
    if (length $$yaml) {
        die "Unexpected";
    }
    $self->end_document( explicit => 0, empty => 1 );

    $self->end("STR");
}

sub parse_document_start {
    TRACE and warn "=== parse_document_start()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;

    if ($$yaml =~ s/\A---(?= |$)//m) {
        my $eol = $self->parse_eol;
        if ($self->level > 1) {

            my $off = $self->offset;
            my $i = $#$off;
            while ($i > 1) {
                my $test_indent = $off->[ $i ];
                die "Unexpected" unless $self->end_node;
                $i--;
            }
            $self->indent($off->[ $i ]);

            $self->end("DOC");
        }
        elsif ($self->level) {
            $self->end("DOC");
        }
        $self->begin("DOC", "---");
        $self->offset->[ $self->level ] = 0;
        unless ($eol) {
            if ($$yaml =~ s/\A +//) {
                return 1 if $self->parse_flow;
                return 1 if $self->parse_block_scalar;
                my $node = $self->parse_node_tag_anchor(chomp => 1);
                return;
            }
            warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
            die "Unexpected";
        }
    }
    return;
}

sub parse_document_head {
    TRACE and warn "=== parse_document_head()\n";
    my ($self, %args) = @_;
    my $yaml = $self->yaml;
    my $head;
    my $need_explicit = $args{explicit};
    while (length $$yaml) {
        if ($$yaml =~ s/\A *#[^\n]+\n//) {
            next;
        }
        if ($$yaml =~ s/\A *\n//) {
            next;
        }
        if ($$yaml =~ s/\A\s*%YAML ?1\.2\s*//) {
            $need_explicit = 1;
            next;
        }
        if ($$yaml =~ s/\A\s*%TAG +(![a-z]*!|!) +(tag:\S+|![a-z][a-z-]*)\s*//) {
            $need_explicit = 1;
            my $tag_alias = $1;
            my $tag_url = $2;
            $self->tagmap->{ $tag_alias } = $tag_url;
            next;
        }
        if ($$yaml =~ m/\A---(?= |$)/m) {
            $head = "---";
            last;
        }
        last;
    }
    if ($need_explicit and not $head) {
        die "Expected ---";
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

sub parse_document {
    TRACE and warn "=== parse_document()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    $self->parse_empty;
    if ($self->parse_document_end) {
        $self->event_value(':');
        return (1,0);
    }

    TRACE and $self->debug_yaml;
    my $res = $self->next_line;
    TRACE and warn "---------- GOT $res";
    if ($res !~ m/NODE|SEQITEM|MAPKEY|SEQSTART|MAPVAL/) {
        warn __PACKAGE__.':'.__LINE__.": !!!!!!!!!!! $res\n";
    }
    TRACE and $self->debug_events;
    TRACE and $self->debug_offset;

    my $end = 0;
    my $need_end = 0;
    if ($res eq "NODE") {
        $need_end = 1;
    }
    if ($self->parse_document_end) {
        $end = 1;
    }
    return ($end, $need_end);

}

sub next_line {
    TRACE and warn "=== next_line()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    my $plus_indent = 0;
    my $seq_indent = 0;
    $self->parse_empty;

    return unless length $$yaml;
    my $indent = $self->indent;

    my $space = 0;
    if ($$yaml =~ s/\A( *)//m) {
        $space = length $1;
    }
    if ($indent and $space < $indent) {

        $plus_indent = $space - $indent;
        TRACE and warn "### INDENT CHANGE: $plus_indent\n";

        my $off = $self->offset;
        my $i = $#$off;
        while ($i > 1) {
            my $test_indent = $off->[ $i ];
            if ($test_indent <= $space) {
                last;
            }
            die "Unexpected" unless $self->end_node;
            $i--;
        }
        $self->indent($off->[ $i ]);

    }
    elsif ($space > $indent) {
        $plus_indent = $space - $indent;
        TRACE and warn "### INDENT CHANGE: $plus_indent\n";
    }
    else {
        TRACE and warn "### INDENT CHANGE: $plus_indent\n";
    }

    if ($$yaml =~ m/\A-(?: |$)/m) {
        $seq_indent = 2;
    }
    elsif ($plus_indent <= 0 and $self->in_unindented_seq) {
        $seq_indent = -2;
        # we are at the end of the unindented sequence
        $self->end('SEQ');
        return "NODE";
    }

    if (($plus_indent < 0 or $seq_indent < 0) and $self->in('DOC')) {
        die "Expected ---";
    }

    my $exp = "ANY";
    if ($plus_indent == 0 and $seq_indent == 0) {
        if ($self->in('MAP')) {
            $exp = "KEY";
        }
    }
    elsif ($plus_indent == 0 and $seq_indent == -2) {
        if ($self->in('MAP')) {
            $exp = "KEY";
        }
    }
    elsif ($plus_indent < 0) {
        if ($self->in('MAP')) {
            $exp = "KEY";
        }
    }

    my $node_anchor = $self->parse_node_tag_anchor(chomp => 1);
    if ($node_anchor) {
        my $node = $self->next_line;
        return $node;
    }
    if ($exp ne "ANY") {
        if (my $res = $self->parse_map($plus_indent)) {
            return $res;
        }
        else {
            die "Expected Mapping Key";
        }
    }
    my $res = $self->parse_node($plus_indent, $seq_indent);
    return $res;
}

sub parse_node {
    my ($self, $plus_indent, $seq_indent) = @_;
    TRACE and warn "=== parse_node(+$plus_indent,+$seq_indent)\n";
    my $yaml = $self->yaml;
    {

        my $res;
        if ($res = $self->parse_seq($plus_indent, $seq_indent)) {
            return $res;
        }
        elsif ($res = $self->parse_map($plus_indent)) {
            return $res;
        }
        elsif ($res = $self->parse_flow) {
            return $res;
        }
        elsif ($self->parse_block_scalar) {
            return "NODE";
        }
        else {
            if ($self->parse_alias) {
                $self->parse_eol;
                return "NODE";
            }
            if ($self->parse_quoted) {
                return "NODE";
            }
            elsif ($$yaml =~ s/\A(.+)\n//) {
                my $value = $1;

                $self->inc_indent(1);
                my $text = $self->parse_multi(folded => 1, trim => 1);
                $value = "$value $text" if length $text;
                $value =~ s/ #.*$//mg;
                $self->event_value(":$value");
                $self->dec_indent(1);
                return "NODE";
            }
            else {
                warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
                die "Unexpected";
            }
        }

    }

    return;
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

sub parse_node_tag_anchor {
    TRACE and warn "=== parse_node_tag_anchor()\n";
    my ($self, %args) = @_;
    my $yaml = $self->yaml;
    my ($tag, $anchor);
    if ($$yaml =~ s/\A&($anchor_re)(?: +($full_tag_re))?(?= |\n)//) {
        $anchor = $1;
        $tag = $2;
    }
    elsif ($$yaml =~ s/\A($full_tag_re)(?: +&($anchor_re))?(?= |\n)//) {
        $tag = $1;
        $anchor = $2;
    }
    else {
        return;
    }
    $$yaml =~ s/\A +(?:#.*)?//;
    my $node = 0;
    if ($$yaml =~ m/\A\n/) {
        $node = 1;
    }
    if ($args{chomp}) {
        $$yaml =~ s/\A\n//;
    }
    if (defined $anchor) {
        TRACE and warn "ANCHOR $anchor (node $node)\n";
        if ($node) {
            $self->node_anchor($anchor);
        }
        else {
            $self->anchor($anchor);
        }
    }
    if (defined $tag) {
        TRACE and warn "TAG $tag (node $node)\n";
        if ($node) {
            $self->node_tag($tag);
        }
        else {
            $self->tag($tag);
        }
    }
    return $node;
}

sub parse_alias {
    TRACE and warn "=== parse_alias()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/\A\*($anchor_re)//m) {
        my $alias = $1;
        TRACE and warn "ALIAS $alias\n";
        my $space = length $2;
        $self->event("=ALI", "*$alias");
        return 1;
    }
    return 0;
}

sub parse_seq {
    my ($self, $plus_indent, $seq_indent) = @_;
    TRACE and warn "=== parse_seq(+$plus_indent,+$seq_indent)\n";
    my $yaml= $self->yaml;
    if ($$yaml =~ s/\A(-)($WS|$)//m) {
        my $space = length $2;
        TRACE and warn "### SEQ item\n";


        if ($plus_indent > 0 or ($seq_indent > 0 and $self->in('MAP') ) or $self->events->[-1] eq 'DOC') {
            $self->begin("SEQ");
            $self->offset->[ $self->level ] = $self->indent + $plus_indent;
            $self->inc_indent($plus_indent);
        }
        else {
            $self->empty_event(1);
        }

        if ($self->parse_alias) {
            $$yaml =~ s/\A +#.*//;
            $$yaml =~ s/\A *\n//;
            return "SEQITEM";
        }

        $space and $$yaml =~ s/\A#.*//;
        my $node = $self->parse_node_tag_anchor(chomp => 1);
        if ($node or $$yaml =~ s/\A\n//) {
            $self->value('SEQ');
            return "SEQSTART";
        }

        if ($$yaml =~ s/\A( *)//) {
            my $ind = length $1;
            if ($$yaml =~ m/\A./) {
                if ($self->parse_quoted) {
                    return "SEQITEM";
                }
                if ($self->parse_flow) {
                    return "SEQITEM";
                }
                if ($self->parse_block_scalar) {
                    return "SEQITEM";
                }

                my $node = $self->parse_node($ind + 2, 0);
                if ($node) {
                    return "SEQITEM";
                }
                die "Unexpected";
            }
        }
        die "Unexpected";
    }
    return 0;
}


sub parse_map {
    my ($self, $plus_indent) = @_;
    my $yaml = $self->yaml;
    TRACE and warn "=== parse_map(+$plus_indent)\n";
    my $key;
    my $key_style = ':';
    my $alias;

    if ($$yaml =~ m/\A\?/) {
        die "Not Implemented: Explicit Key ?";
    }

    $self->parse_node_tag_anchor;
    if ($$yaml =~ s/\A\*($anchor_re) +:(?=$WS|$)//m) {
        if (defined $self->anchor or defined $self->tag) {
            die "TODO";
        }
        $alias = $1;
    }
    elsif ($$yaml =~ s/\A($key_full_re) *:(?=$WS|$)//m) {
        TRACE and warn "### MAP item\n";
        $key = $1;
        if ($key =~ s/^(["'])(.*)\1$/$2/) {
            $key_style = $1;
        }
        if ($key_style eq "'") {
            $key =~ s/\\/\\\\/g;
        }
    }
    if (defined $alias or defined $key) {
        if ($plus_indent > 0 or $self->events->[-1] eq 'DOC') {
            $self->begin("MAP");
            $self->offset->[ $self->level ] = $self->indent + $plus_indent;
            $self->inc_indent($plus_indent);
        }
        if (defined $alias) {
            $self->event("=ALI", "*$alias");
        }
        else {
            $self->event_value("$key_style$key");
        }

        if ($self->parse_eol) {
            return "MAPKEY";
        }

        $$yaml =~ s/\A$WS+//;

        if ($self->parse_alias) {
            return "MAPVAL";
        }
        my $node = $self->parse_node_tag_anchor(chomp => 1);
        if ($node) {
            $self->value('MAPVAL');
            return "MAPKEY";
        }

        if ($self->parse_quoted) {
            return "MAPVAL";
        }
        if ($self->parse_flow) {
            return "MAPVAL";
        }
        if ($self->parse_block_scalar) {
            return "MAPVAL";
        }

        if ($$yaml =~ s/\A($plain_value_start_re.*)\n//) {
            my $value = $1;
            $value =~ s/ +#.*//;
            $value =~ s/\A *//;
            $self->inc_indent(1);
            my $text = $self->parse_multi(folded => 1, trim => 1);
            $value = "$value $text" if length $text;
            $self->event_value(":$value");
            $self->dec_indent(1);
            return "MAPVAL";
        }
        $self->event_value(":");
        return "MAPVAL";

    }
    return 0;

}

sub parse_quoted {
    TRACE and warn "=== parse_quoted()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/\A"//) {
        if ($$yaml =~ s/\A((?:\\"|[^"])*?)"//) {
            my $quoted = $1;
            $quoted =~ s/\\\n +//g;
            $quoted =~ s/\\u([A-Fa-f0-9]+)/chr(oct("x$1"))/eg;
            $quoted =~ s/\\"/"/g;
            $quoted =~ s/\t/\\t/g;
            my $indent = $self->indent;
            $quoted =~ s/^ +//gm;
            $quoted =~ s/\n+/ /g;
            $self->event_value('"' . $quoted);
            $self->parse_eol;
            return 1;
        }
        else {
            die "Couldn't parse quoted string";
        }
    }
    elsif ($$yaml =~ s/\A'//) {
        if ($$yaml =~ s/\A((?:''|[^'])*)'//) {
            my $quoted = $1;
            $quoted =~ s/''/'/g;
            $quoted =~ s/\\/\\\\/g;
            $quoted =~ s/\n/\\n/g;
            $quoted =~ s/\t/\\t/g;
            $self->event_value("'" . $quoted);
            $self->parse_eol;
            return 1;
        }
        else {
            die "Couldn't parse quoted string";
        }
    }
    return 0;
}

sub parse_empty {
    TRACE and warn "=== parse_empty()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    while (length $$yaml) {
        $$yaml =~ s/\A *#.*//;
        last unless $$yaml =~ s/\A\n//;
    }
}

sub parse_block_scalar {
    TRACE and warn "=== parse_block_scalar()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/\A([|>])([1-9]\d*)?([+-]?)\n//) {
        my $type = $1;
        my $indent = $2;
        if (defined $indent) {
            die "Not Implemented: Block Scalar Explicit Indent";
        }
        my $chomp = $3;
        my %args = (block=> 1);
        if ($type eq '>') {
            $args{block}= 0;
            $args{folded}= 1;
        }
        if ($chomp eq '+') {
            $args{keep} = 1;
        }
        elsif ($chomp eq '-') {
            $args{trim} = 1;
        }
        my $content = $self->parse_multi(%args);
        $content =~ s/\\/\\\\/g;
        $content =~ s/\n/\\n/g;
        $content =~ s/\t/\\t/g;
        $self->event_value($type . $content);
        return 1;
    }
    return 0;
}

sub parse_multi {
    TRACE and warn "=== parse_multi()\n";
    my ($self, %args) = @_;
    my $trim = $args{trim};
    my $block = $args{block};
    my $folded = $args{folded};
    my $keep = $args{keep};
    my $yaml = $self->yaml;
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
    my $indent = $self->indent;
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$indent], ['indent']);
    TRACE and $self->debug_offset;
    my $content = '';
    my $fold_indent = 0;
    my $fold_indent_str = '';
    my $got_indent = 0;
    my $trailing_comment = 0;
    while (length $$yaml) {

#        last if $$yaml =~ m/\A--- /;
        last if $$yaml =~ m/\A\.\.\. ?/;
        my $indent_re = "[ ]{$indent}";
        my $fold_indent_re = "[ ]{$fold_indent}";
        my $less_indent = $indent + $fold_indent - 1;

        unless ($got_indent) {
            $$yaml =~ s/\A +$//m;
            if ($$yaml =~ m/\A$indent_re( *)\S/) {
                $fold_indent += length $1;
                $got_indent = 1;
                $fold_indent_re = "[ ]{$fold_indent}";
                $less_indent = $indent + $fold_indent - 1;
            }
        }
        elsif ($less_indent > 0) {
#            warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$less_indent], ['less_indent']);
#            if ($$yaml =~ s/\A {1,$less_indent}#.*$//m) {
#                warn __PACKAGE__.':'.__LINE__.": !!!!!!!!!!!!!!! COMMENT\n";
#                $trailing_comment = 1;
#            }
            # strip less indented comments
            # might need more work
            if ($$yaml =~ s/\A {1,$less_indent}#.*\n//) {
                next;
            }
            $$yaml =~ s/\A {1,$less_indent}$//m;
        }
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$indent_re], ['indent_re']);
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$fold_indent_re], ['fold_indent_re']);
        unless ($$yaml =~ s/\A$indent_re$fold_indent_re//) {
            unless ($$yaml =~ m/\A *$/m) {
#                warn __PACKAGE__.':'.__LINE__.": !!! END\n";
                last;
            }
        }


        $$yaml =~ s/^(.*)(\n|\z)//;
        my $line = $1;
#        $line =~ s/ # .*\z//;

        my $end = $2;
        TRACE and warn __PACKAGE__.':'.__LINE__.": =============== LINE: '$line' ('$fold_indent')\n";
        if (not length $line) {
            $content .= "\n";
        }
        elsif ($line =~ m/^ +\z/ and not $block) {
            $content .= "\n";
        }
        else {

            my $change = 0;
            my $local_indent;
            if ($line =~ m/^( +)/) {
                $local_indent = length $1;
            }

            if ($block) {
                $content .= $line . $end;
            }
            else {
                if ($local_indent) {
                    $content .= "\n";
                }
                elsif (length $content and $content !~ m/\n\z/) {
                    $content .= ' ';
                }
                $content .= $line;
            }
        }
        if ($indent == 0 and $$yaml =~ m/\A\S/) {
            last;
        }
    }
    return $content unless (length $content);
#    unless ($trailing_comment) {
#    }
    if ($block) {
        $content =~ s/\n+\z//;
    }
    elsif ($trim) {
        $content =~ s/\n+\z//;
    }
    elsif ($folded) {
        $content =~ s/\n\z//;
    }
    unless ($trim) {
        $content .= "\n" if $content !~ m/\n\z/;
    }
    return $content;
}

sub parse_eol {
    my ($self) = @_;
    my $yaml = $self->yaml;
    $$yaml =~ s/\A +#.*//;
    return $$yaml =~ s/\A\n// ? 1 : 0;
}

sub in_unindented_seq {
    my ($self) = @_;
    if ($self->in('SEQ')) {
        my $indent = $self->indent;
        my $level = $self->level;
        my $seq_indent = $self->offset->[ $level ];
        my $prev_indent = $self->offset->[ $level - 1];
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

sub tag_str {
    my ($self, $tag) = @_;
    if ($tag eq '!') {
        return "<!>";
    }
    elsif ($tag =~ m/^(![a-z]*!)($tag_re)/) {
        my $alias = $1;
        my $name = $2;
        my $map = $self->tagmap;
        if (exists $map->{ $alias }) {
            $tag = "<" . $map->{ $alias }. $name . ">";
        }
    }
    elsif ($tag =~ m/^(!)($tag_re)/) {
        my $alias = $1;
        my $name = $2;
        my $map = $self->tagmap;
        if (exists $map->{ $alias }) {
            $tag = "<" . $map->{ $alias }. $name . ">";
        }
        else {
            $tag = "<!$name>";
        }
    }
    else {
        die "Invalid tag";
    }
    return $tag;
}

sub event_value {
    my ($self, $value) = @_;
    my $anchor = $self->anchor;
    my $node_anchor = $self->node_anchor;
    my $tag = $self->tag;
    my $node_tag = $self->node_tag;
    my $event = $value;

    if (defined $node_tag) {
        my $tag_str = $self->tag_str($node_tag);
        $event = "$tag_str $event";
        $self->node_tag(undef);
    }
    elsif (defined $tag) {
        my $tag_str = $self->tag_str($tag);
        $event = "$tag_str $event";
        $self->tag(undef);
    }
    if (defined $node_anchor) {
        $self->node_anchor(undef);
        $event = "&$node_anchor $event";
    }
    elsif (defined $anchor) {
        $self->anchor(undef);
        $event = "&$anchor $event";
    }
    $self->event("=VAL", "$event");
}

sub end_node {
    my ($self) = @_;
    my $last = $self->events->[-1];
    if ($last eq 'MAP' or $last eq 'SEQ') {
        $self->end($last);
        return $last;
    }
    return;
}

sub end_document {
    my ($self, %args) = @_;
    my $explicit = $args{explicit};
    my $empty = $args{empty};
    while (@{ $self->events }) {
        last unless $self->end_node;
    }
    if ($empty and not $self->in('DOC')) {
        return;
    }
    if ($explicit) {
        $self->end("DOC", "...");
    }
    else {
        $self->end("DOC");
    }
}

sub push_events {
    $_[0]->inc_level;
    push @{ $_[0]->events }, $_[1];
}

sub pop_events {
    $_[0]->dec_level;
    my $last = pop @{ $_[0]->events };
    return $last unless $_[1];
    if ($last ne $_[1]) {
        die "pop_events($_[1]): Unexpected event '$last', expected $_[1]";
    }
}

sub begin {
    my ($self, $event, @content) = @_;
    if ($event eq 'SEQ' or $event eq 'MAP') {
        my $anchor = $self->anchor;
        my $node_anchor = $self->node_anchor;
        my $tag = $self->tag;
        my $node_tag = $self->node_tag;
        if (defined $node_tag) {
            $self->node_tag(undef);
            my $tag_str = $self->tag_str($node_tag);
            unshift @content, $tag_str;
        }
        if (defined $node_anchor) {
            $self->node_anchor(undef);
            unshift @content, "&$node_anchor";
        }
    }
    $self->push_events($event);
    TRACE and warn "---------------------------> BEGIN $event @content\n";
    $self->receiver->($self, "+$event", @content);
}

sub end {
    my ($self, $event, @content) = @_;
    $self->empty_event(1);
    $self->pop_events($event);
    TRACE and warn "---------------------------> END   $event @content\n";
    $self->receiver->($self, "-$event", @content);
    if ($event eq 'DOC') {
        $self->tagmap({
            '!!' => "tag:yaml.org,2002:",
        });
    }
}

sub empty_event {
    my ($self, $output) = @_;
    if (defined(my $value = $self->value)) {
        $self->value(undef);
        if ($self->in('MAP')) {
        }
        elsif ($self->in('SEQ')) {
            if ($value ne 'SEQ') {
                $output &&= 0;
            }
        }
        $self->event_value(':') if $output;
    }
}

sub event {
    my ($self, $event, @content) = @_;
    $self->empty_event;
    TRACE and warn "---------------------------> EVENT $event @content\n";
    $self->receiver->($self, $event, @content);
}

sub inc_indent {
    $_[0]->indent($_[0]->indent + $_[1]);
}

sub dec_indent {
    $_[0]->indent($_[0]->indent - $_[1]);
}

sub inc_level {
    $_[0]->level($_[0]->level + 1);
}

sub dec_level {
    $_[0]->level($_[0]->level - 1);
    $_[0]->indent( $_[0]->offset->[ $_[0]->level ] );
    pop @{ $_[0]->offset };
}

sub debug_events {
    warn "EVENTS: (@{ $_[0]->events })\n";
}

sub debug_offset {
    warn "OFFSET: (@{ $_[0]->offset }) (level=@{[ $_[0]->level ]}) (:@{[ $_[0]->indent ]})\n";
}

sub debug_yaml {
    my ($self) = @_;
    my $yaml = $self->yaml;
    warn "YAML:\n$$yaml\nEOYAML\n";
}

1;
