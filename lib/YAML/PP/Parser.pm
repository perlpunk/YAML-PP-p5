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
                    my $text = $self->parse_multi(folded => 1, trim => 1);
                    $self->event("=VAL", ":$text");
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
        if ($$yaml =~ s/\A( +)//) {
            TRACE and warn "### more spaces\n";
            my $spaces = $1;
            $plus_indent = length $spaces;
        }

        last;
    }
    $self->parse_node($plus_indent);
}

sub parse_node {
    my ($self, $plus_indent) = @_;
    TRACE and warn "=== parse_node(+$plus_indent)\n";
    my $yaml = $self->yaml;
    {

        if ($self->parse_seq($plus_indent)) {
            return;
        }
        elsif ($self->parse_map($plus_indent)) {
            return;
        }
        elsif (defined $self->parse_block_scalar) {
            return;
        }
        else {
            if ($$yaml =~ s/\A(.+)\n//) {
                my $value = $1;
                $value =~ s/ +$//;
                $value =~ s/ #.*$//;
                $self->event("=VAL", ":$value");
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

my $WS = '[\t ]';
sub parse_seq {
    my ($self, $plus_indent) = @_;
    TRACE and warn "=== parse_seq(+$plus_indent)\n";
    my $yaml= $self->yaml;
    if ($$yaml =~ s/\A(-)($WS|$)//m) {
        my $space = length $2;
        TRACE and warn "### SEC item\n";
        if ($plus_indent or $self->events->[-1] eq 'DOC') {
            $self->begin("SEQ");
            $self->offset->[ $self->level ] = $self->indent + $plus_indent;
            $self->inc_indent($plus_indent);
        }
        if ($space and $$yaml =~ s/\A#.*\n//) {
            $self->event("=VAL", ":");
        }
        elsif ($$yaml =~ s/\A( *)//) {
            my $ind = length $1;
            if ($$yaml =~ m/\A./) {
                if (defined $self->parse_block_scalar) {
                }
                else {
                    $self->parse_node($ind + 2);
                }
            }
        }
        return 1;
    }
    return 0;
}

sub parse_map {
    my ($self, $plus_indent) = @_;
    my $yaml = $self->yaml;
    TRACE and warn "=== parse_map(+$plus_indent)\n";
    if ($$yaml =~ s/\A($key_re) *:($WS|$)//m) {
        TRACE and warn "### MAP item\n";
        my $key = $1;
        my $space = length $2;
        if ($plus_indent or $self->events->[-1] eq 'DOC') {
            $self->begin("MAP");
            $self->offset->[ $self->level ] = $self->indent + $plus_indent;
            $self->inc_indent($plus_indent);
        }
        $self->event("=VAL", ":$key");
        if ($space and $$yaml =~ s/\A *#.*\n//) {
            while ( $$yaml =~ s/\A +#.*\n// ) {
            }
            if ($$yaml =~ s/\A( *)//) {
                my $space = length $1;
                $self->parse_node($space);
            }
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
                $self->event("=VAL", ":$value");
                $self->dec_indent(1);
            }
        }
#            else {
#                $$yaml =~ s/\A\n//;
#            }
        return 1;
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
        $self->event("=VAL", $type . $content);
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
    $self->push_events($event);
    TRACE and warn "---------------------------> BEGIN $event @content\n";
    $self->cb->($self, "+$event", @content);
}

sub end {
    my ($self, $event, @content) = @_;
    $self->pop_events($event);
    TRACE and warn "---------------------------> END   $event @content\n";
    $self->cb->($self, "-$event", @content);
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
