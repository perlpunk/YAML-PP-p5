use strict;
use warnings;
package YAML::PP::Parser;

use Moo;

has cb => ( is => 'rw' );
has yaml => ( is => 'rw' );
has indent => ( is => 'rw', default => 0 );
has level => ( is => 'rw', default => -1 );
has offset => ( is => 'rw', default => sub { [0] } );
has events => ( is => 'rw', default => sub { [] } );
has anchor => ( is => 'rw' );
has tag => ( is => 'rw' );
has tagmap => ( is => 'rw', default => sub { +{
    '!!' => "tag:yaml.org,2002:",
} } );

use constant TRACE => $ENV{YAML_PP_TRACE};

sub parse {
    my ($self, $yaml) = @_;
    $self->yaml(\$yaml);
    $self->parse_stream;
}

sub parse_stream {
    my ($self) = @_;
    my $yaml = $self->yaml;
    $self->begin("STR");


    my $close = 1;
    while (length $$yaml) {
        if ($$yaml =~ s/\A *#[^\n]+\n//) {
            next;
        }
        if ($$yaml =~ s/\A *\n//) {
            next;
        }
        if ($$yaml =~ s/\A\s*%YAML ?1\.2\s*//) {
            next;
        }
        if ($$yaml =~ s/\A\s*%TAG +(![a-z]*!) +(tag:\S+)\s*//) {
            my $tag_alias = $1;
            my $tag_url = $2;
            $self->tagmap->{ $tag_alias } = $tag_url;
        }

        my $doc_end = 0;
        if ($$yaml =~ s/\A--- ?//) {
            if ($self->level > 1) {

                my $off = $self->offset;
                my $i = $#$off;
                while ($i > 1) {
                    my $test_indent = $off->[ $i ];
                    die "Unexpected" unless $self->pop_last_allowed;
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
            $$yaml =~ s/^#.*\n//;
            if ($$yaml =~ m/\A *([^ \n]+)\n/) {
                my $value = $1;
                if ($value =~ m/^[|>]/) {
                    $self->parse_block_scalar;
                    $doc_end = 1;
                }
                else {
                    if ($self->parse_tag) {
                    }
                    else {
                        die "Needed?";
                    }
#                    my $text = $self->parse_multi(folded => 1, trim => 1);
#                    $self->event_value(":$text");
                }
            }
            $$yaml =~ s/\A\n//;
        }
        elsif (not $self->level) {
            $self->begin("DOC");
            $self->offset->[ $self->level ] = 0;
        }

        $self->parse_document unless $doc_end;
        my $doc_end_explicit = 0;

        if ($$yaml =~ s/\A\.\.\. ?//) {
            $doc_end = 1;
            $doc_end_explicit = 1;
#            $$yaml =~ s/^#.*\n//;
#            $$yaml =~ s/^\n//;
        }
        if ($doc_end or not length $$yaml) {
            while (@{ $self->events }) {
                last unless $self->pop_last_allowed;
            }
            if ($doc_end_explicit) {
                $self->end("DOC", "...");
            }
            else {
                $self->end("DOC");
            }
            $close = 0;
        }


    }
    if ($close) {
        while (@{ $self->events }) {
            last unless $self->pop_last_allowed;
        }
        $self->end("DOC") if $self->events->[-1] eq 'DOC';
    }

    $self->end("STR");
}

sub pop_last_allowed {
    my ($self) = @_;
    my $last = $self->events->[-1];
    if ($last eq 'MAP' or $last eq 'SEQ') {
        $self->end($last);
    }
    else {
        return;
    }
    return 1;
}

sub parse_document {
    TRACE and warn "=== parse_document()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;

#        if ($$yaml =~ s/\A *#[^\n]+\n//) {
#            next;
#        }
#        if ($$yaml =~ s/\A *\n//) {
#            next;
#        }

        TRACE and $self->debug_yaml;
        my $content = $self->parse_next;
        TRACE and $self->debug_events;
        TRACE and $self->debug_offset;

}

my $key_start_re = '[a-zA-Z0-9%]';
my $key_content_re = '[a-zA-Z0-9%\]" -]';
my $key_re = qr{(?:$key_start_re$key_content_re*$key_start_re|$key_start_re?)};

sub parse_next {
    TRACE and warn "=== parse_next()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    my $plus_indent = 0;
    my $seq_indent = 0;
    while (length $$yaml) {
        if ($$yaml =~ s/\A *\n//) {
            next;
        }
        if ($$yaml =~ s/\A *# .*\n//) {
            next;
        }

        if ($$yaml =~ m/\A( *)\S/) {
            my $ind = length $1;
            if ($ind < $self->indent) {
                TRACE and warn "### less spaces\n";
                $$yaml =~ s/\A( *)//;
                my $off = $self->offset;
                my $i = $#$off;
                while ($i > 1) {
                    my $test_indent = $off->[ $i ];
                    if ($test_indent <= $ind) {
                        last;
                    }
                    die "Unexpected" unless $self->pop_last_allowed;
                    $i--;
                }
                $self->indent($off->[ $i ]);
                last;
            }
        }

        my $indent_re = '[ ]{' . $self->indent . '}';
        if ($self->indent and $$yaml =~ s/\A$indent_re//) {
            TRACE and warn "### removed $indent_re\n";
        }
        elsif ($self->indent) {
            die "Unexpected indentation";
        }
        if ($$yaml =~ s/\A( +)//) {
            TRACE and warn "### more spaces\n";
            my $spaces = $1;
            $plus_indent = length $spaces;
        }
        elsif ($$yaml =~ m/\A- /) {
            $seq_indent = 2;
        }
        else {
            TRACE and warn "### same indent\n";
            if ($self->in_unindented_seq) {
                # we are at the end of the unindented sequence
                $self->end('SEQ');
            }
        }

        last;
    }
    $self->parse_node($plus_indent, $seq_indent);
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

sub parse_node {
    my ($self, $plus_indent, $seq_indent) = @_;
    TRACE and warn "=== parse_node(+$plus_indent,+$seq_indent)\n";
    my $yaml = $self->yaml;
    {

        if ($self->parse_anchor) {
        }
        if ($self->parse_seq($plus_indent, $seq_indent)) {
            return;
        }
        elsif ($self->parse_map($plus_indent, $seq_indent)) {
            return;
        }
        elsif (defined $self->parse_block_scalar) {
            return;
        }
        else {
            if ($self->parse_tag) {
            }
            my $alias = $self->parse_alias;
            if ($alias) {
                return;
            }
            if ($self->parse_quoted) {
            }
            elsif ($$yaml =~ s/\A(.+)\n//) {
                my $value = $1;
                $value =~ s/ +$//;
                $value =~ s/ #.*$//;
                $self->event_value(":$value");
            }
            else {
                warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
                die "Unexpected";
            }
        }
#        my $value = $self->parse_multi(folded => 1);
#        if ($self->events->[-1] eq 'MAP') {
#            $value =~ s/\n\z//;
#            $self->event("=VAL", ":$value");
#            return $value;
#        }
#        elsif (length $value) {
#            $value =~ s/\\/\\\\/g;
#            $value =~ s/\n/\\n/g;
#            $value =~ s/\t/\\t/g;
#            $self->event("=VAL", ":$value");
#        }
#        else {
##            $self->event("=VAL", ":");
#        }

#            $$yaml =~ s/.*//s;

    }

    return;
}

sub event_value {
    my ($self, $value) = @_;
    my $anchor = $self->anchor;
    my $tag = $self->tag;
    my $event = $value;

    if (defined $tag) {
        my $tag_str = $self->tag_str($tag);
        $event = "$tag_str $event";
        $self->tag(undef);
    }
    if (defined $anchor) {
        $event = "&$anchor $event";
        $self->anchor(undef);
    }
    $self->event("=VAL", "$event");
}

my $tag_re = '[a-zA-Z]+';
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
}

my $anchor_start_re = '[a-zA-Z]';
my $anchor_content_re = '[a-zA-Z:]';
my $anchor_re = qr{(?:$anchor_start_re$anchor_content_re*|$anchor_start_re?)};

sub parse_anchor {
    TRACE and warn "=== parse_anchor()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/\A&($anchor_re) +//) {
        my $anchor = $1;
        $self->anchor($anchor);
        return 1;
    }
    return 0;
}

sub parse_alias {
    TRACE and warn "=== parse_alias()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/\A\*($anchor_re)//m) {
        my $alias = $1;
        my $space = length $2;
        $self->event("=ALI", "*$alias");
        return 1;
    }
    return 0;
}

my $WS = '[\t ]';
sub parse_seq {
    my ($self, $plus_indent, $seq_indent) = @_;
    TRACE and warn "=== parse_seq(+$plus_indent,+$seq_indent)\n";
    my $yaml= $self->yaml;
    if ($$yaml =~ s/\A(-)($WS|$)//m) {
        my $space = length $2;
        TRACE and warn "### SEC item\n";


        if ($plus_indent or ($seq_indent and $self->in('MAP') ) or $self->events->[-1] eq 'DOC') {
            $self->begin("SEQ");
            $self->offset->[ $self->level ] = $self->indent + $plus_indent;
            $self->inc_indent($plus_indent);
        }

        if ($self->parse_alias) {
            $$yaml =~ s/\A +#.*//;
            $$yaml =~ s/\A *\n//;
            return 1;
        }

        if ($space and $self->parse_tag) {
            # space is already used
            $$yaml=~ s/\A *#.*\n//;
        }
        elsif ($space and $$yaml =~ s/\A#.*\n//) {
            $self->event_value(":");
            return 1;
        }
        if ($$yaml =~ s/\A( *)//) {
            my $ind = length $1;
            if ($$yaml =~ m/\A./) {
                if ($self->parse_quoted) {
                }
                elsif (defined $self->parse_block_scalar) {
                }
                else {
                    $self->parse_node($ind + 2, 0);
                }
            }
        }
        return 1;
    }
    return 0;
}

sub parse_tag {
    TRACE and warn "=== parse_tag()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/\A(![a-z]*!$tag_re|!)( |$)//m) {
        my $tag = $1;
        $self->tag($tag);
        return 1;
    }
    return 0;
}

sub in {
    my ($self, $event) = @_;
    return $self->events->[-1] eq $event;
}

sub parse_map {
    my ($self, $plus_indent, $seq_indent) = @_;
    my $yaml = $self->yaml;
    TRACE and warn "=== parse_map(+$plus_indent,+$seq_indent)\n";
    my $key;
    my $alias;
    my $space;

    if ($$yaml =~ s/\A\*($anchor_re) +:($WS|$)//m) {
        $alias = $1;
        $space = length $2;
    }
    elsif ($$yaml =~ s/\A($key_re) *:($WS|$)//m) {
        TRACE and warn "### MAP item\n";
        $key = $1;
        $space = length $2;
    }
    if (defined $alias or defined $key) {
        if ($plus_indent or $self->events->[-1] eq 'DOC') {
            $self->begin("MAP");
            $self->offset->[ $self->level ] = $self->indent + $plus_indent;
            $self->inc_indent($plus_indent);
        }
        if (defined $alias) {
            $self->event("=ALI", "*$alias");
        }
        else {
            $self->event_value(":$key");
        }

        if ($space and $$yaml =~ s/\A *#.*\n//) {
            while ( $$yaml =~ s/\A +#.*\n// ) {
            }
            if ($$yaml =~ s/\A( *)//) {
                my $space = length $1;
                $self->parse_node($space, 0);
            }
        }
        else {
            my $anchor = $self->parse_anchor;

            if ($self->parse_alias) {
            }
            else {
                if ($self->parse_tag) {
                }
                if ($self->parse_quoted) {
                }
                elsif ($$yaml =~ s/\A( *.+)\n//) {
                    my $value = $1;
                    $value =~ s/ +#.*//;
                    $value =~ s/\A *//;
                    if ($value =~ m/^[|>]/) {
                        $self->inc_indent(1);
                        $$yaml = "$value\n$$yaml";
                        $self->parse_block_scalar;
                        $self->dec_indent(1);
                    }
                    else {
                        $self->inc_indent(1);
                        my $text = $self->parse_multi(folded => 1, trim => 1);
                        $value = "$value $text" if length $text;
                        $self->event_value(":$value");
                        $self->dec_indent(1);
                    }
                }
            }

        }
        return 1;
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
            $quoted =~ s/\\u([A-Fa-f0-9]+)/chr(oct("x$1"))/eg;
            $quoted =~ s/\\"/"/g;
            $quoted =~ s/\t/\\t/g;
            my $indent = $self->indent;
            $quoted =~ s/^ +//gm;
            $quoted =~ s/\n+/ /g;
            $self->event_value('"' . $quoted);
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
            return 1;
        }
        else {
            die "Couldn't parse quoted string";
        }
    }
    return 0;
}

sub parse_block_scalar {
    TRACE and warn "=== parse_block_scalar()\n";
    my ($self) = @_;
    my $yaml = $self->yaml;
    if ($$yaml =~ s/\A([|>])([+-]?)\n//) {
        my $type = $1;
        my $chomp = $2;
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
        return $content;
    }
    return;
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
        my $tag = $self->tag;
        if (defined $tag) {
            $self->tag(undef);
            my $tag_str = $self->tag_str($tag);
            unshift @content, $tag_str;
        }
    }
    $self->push_events($event);
    TRACE and warn "---------------------------> BEGIN $event @content\n";
    $self->cb->($self, "+$event", @content);
}

sub end {
    my ($self, $event, @content) = @_;
    $self->pop_events($event);
    TRACE and warn "---------------------------> END   $event @content\n";
    $self->cb->($self, "-$event", @content);
    if ($event eq 'DOC') {
        $self->tagmap({
            '!!' => "tag:yaml.org,2002:",
        });
    }
}

sub event {
    my ($self, $event, @content) = @_;
    TRACE and warn "---------------------------> EVENT $event @content\n";
    $self->cb->($self, $event, @content);
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
