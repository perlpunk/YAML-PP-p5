use strict;
use warnings;
package YAML::PP::Parser;

use Moo;

has cb => ( is => 'rw' );
has yaml => ( is => 'rw' );
has indent => ( is => 'rw', default => 0 );
has level => ( is => 'rw', default => 0 );
has offset => ( is => 'rw', default => sub { [] } );
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
    $self->cb->($self, "+STR");

    $self->parse_document;
    $self->cb->($self, "-STR");

}

sub push_events {
    push @{ $_[0]->events }, $_[1];
}
sub pop_events {
    my $last = pop @{ $_[0]->events };
    if ($last ne $_[1]) {
        die "Unexpected event '$last', expected $_[1]";
    }
}

sub parse_document {
    my ($self) = @_;
    my $yaml = $self->yaml;

    while (length $$yaml) {
        if ($self->level and $$yaml =~ s/^ *# .*\n//) {
            next;
        }
        if ($$yaml =~ s/^ *\n//) {
            next;
        }

        if ($$yaml =~ s/\A *# .*$//m) {
            next;
        }
        if ($$yaml =~ s/\A\s*%YAML ?1\.2\s*//) {
            next;
        }

        if ($$yaml =~ s/^--- ?//) {
            if ($self->level) {
                $self->dec_level;
                $self->pop_events('DOC');
                $self->cb->($self, "-DOC");
            }
            $self->push_events('DOC');
            $self->cb->($self, "+DOC", "---");
            $self->inc_level;
            $$yaml =~ s/^#.*\n//;
            $$yaml =~ s/^\n//;
        }
        elsif (not $self->level) {
            $self->push_events('DOC');
            $self->cb->($self, "+DOC");
            $self->inc_level;
        }

        TRACE and $self->debug_yaml;
        my $content = $self->parse_node;

        if ($$yaml =~ s/^\.\.\. ?//) {
            $self->pop_events('DOC');
            $self->cb->($self, "-DOC", "...");
            $$yaml =~ s/^#.*\n//;
            $$yaml =~ s/^\n//;
            $self->dec_level;
        }
    }
    if ($self->level) {
        $self->pop_events('DOC');
        $self->cb->($self, "-DOC");
        $self->dec_level;
    }
}

sub parse_node {
    my ($self) = @_;
    my $yaml = $self->yaml;
    my $type = ':';
    {
#        last if $$yaml =~ m/^--- ?/;
#        last if $$yaml =~ m/^\.\.\. ?/;

#        my $indent_re = '[ ]' x $self->indent;
#        last unless $$yaml =~ s/^$indent_re//;

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
            my $content = $self->parse_folded(%args);
            $content =~ s/\\/\\\\/g;
            $content =~ s/\n/\\n/g;
            $content =~ s/\t/\\t/g;
            $self->cb->($self, "=VAL", $type . $content);
            return $content;
        }


        if ($$yaml =~ s/\A *\n//m) {
            return;
        }
        if ($$yaml =~ s/\A *# .*//) {
            return;
        }


        my $value = $self->parse_folded(folded => 1);

    }

    return;
}

sub parse_folded {
    my ($self, %args) = @_;
    my $trim = $args{trim};
    my $block = $args{block};
    my $folded = $args{folded};
    my $keep = $args{keep};
    my $yaml = $self->yaml;
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
#    $self->inc_indent(1);
    my $indent = $self->indent;
    my $content;
    my $fold_indent = 0;
    my $fold_indent_str = '';
    my $got_indent = 0;
    while (length $$yaml) {

        my $indent_re = "[ ]{$indent}";
        my$fold_indent_re = "[ ]{$fold_indent}";
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
        my $end = $2;
        TRACE and warn __PACKAGE__.':'.__LINE__.": =============== LINE: '$line' ('$fold_indent')\n";
        if (not length $line) {
            $content .= "\n";
        }
        elsif ($line =~ m/^ +\z/ and not $keep) {
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
    }
    if ($trim) {
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
}


sub debug_yaml {
    my ($self) = @_;
    my $yaml = $self->yaml;
    warn "YAML: <<$$yaml>>\n";
}
1;
