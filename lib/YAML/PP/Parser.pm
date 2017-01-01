use strict;
use warnings;
package YAML::PP::Parser;

use Moo;

has cb => ( is => 'rw' );
has yaml => ( is => 'rw' );
has indent => ( is => 'rw', default => 0 );
has level => ( is => 'rw', default => 0 );
has offset => ( is => 'rw', default => sub { [] } );

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

        if ($$yaml =~ s/^\s*%YAML ?1\.2\s*//) {
        }

        if ($$yaml =~ s/^--- ?//) {
            if ($self->level) {
                $self->dec_level;
                $self->cb->($self, "-DOC");
            }
            $self->cb->($self, "+DOC", "---");
            $self->inc_level;
            $$yaml =~ s/^#.*\n//;
            $$yaml =~ s/^\n//;
        }
        elsif (not $self->level) {
            $self->cb->($self, "+DOC");
            $self->inc_level;
        }

        TRACE and $self->debug_yaml;
        my $content = $self->parse_node;

        if ($$yaml =~ s/^\.\.\. ?//) {
            $self->cb->($self, "-DOC", "...");
            $$yaml =~ s/^#.*\n//;
            $$yaml =~ s/^\n//;
            $self->dec_level;
        }
    }
    if ($self->level) {
        $self->cb->($self, "-DOC");
        $self->dec_level;
    }
}

sub parse_node {
    my ($self) = @_;
    my $yaml = $self->yaml;
    my $content = '';
    my $block = 0;
    my $folded = 0;
    my $type = ':';
#    warn __PACKAGE__.':'.__LINE__.": ====== parse_node\n";
    while (length $$yaml) {
        last if $$yaml =~ m/^--- ?/;
        last if $$yaml =~ m/^\.\.\. ?/;

        my $indent_re = '[ ]' x $self->indent;


        $$yaml =~ s/^(.*)(\n|\z)//;
        my $line = $1;
        my $end = $2;

        TRACE and warn __PACKAGE__.':'.__LINE__.": LINE: '$line'\n";

        last unless $line =~ m/ ^ $indent_re /x;

        next unless length $line;
        if ($line =~ s/^ *$//) {
            next;
        }
        if ($line =~ s/^ *# .*//) {
            next;
        }

        if ($line eq '|') {
            $block = 1;
            $type = '|';
#            $self->inc_indent(1);
            $content .= $self->parse_folded("block");
        }
        elsif ($line eq '>' or $line eq '>-') {
            $type = '>';
            $folded = 1;
            $content .= $self->parse_folded($line eq '>-' ? "trim" : "folded");
        }
        else {
            $content .= $line . $end;
        }
    }

    $content =~ s/\n/\\n/g;
    $content =~ s/\t/\\t/g;
    $self->cb->($self, "=VAL", $type . $content);
    return $content;
}

sub parse_folded {
    my ($self, $type) = @_;
    my $yaml = $self->yaml;
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$yaml], ['yaml']);
    $self->inc_indent(1);
    my $indent = $self->indent;
    my $content;
    my $fold_indent = '';
    my $got_indent = 1;
    while (length $$yaml) {

        my $indent_re = '[ ]' x $indent;
        if ($$yaml =~ m/^$/) {
        }
        elsif ($got_indent == 1 and $$yaml =~ m/^$indent_re( +)/m) {
            $got_indent += length $1;
            $self->inc_indent(length $1);
            $indent = $self->indent;
            $indent_re = '[ ]' x $indent;
        }
        elsif ($$yaml =~ m/^$indent_re/m) {
        }
        else {
            last;
        }


        $$yaml =~ s/^(.*)(\n|\z)//;
        my $line = $1;
        my $end = $2;
        TRACE and warn __PACKAGE__.':'.__LINE__.": LINE: '$line' ('$fold_indent')\n";
        if (not length $line or $line =~ m/^ +\z/) {
            $content .= "\n";
        }
        elsif ($line =~ s/ ^ $indent_re //x) {

            unless (length $line) {
                $content .= "\n";
                next;
            }

            my $change = 0;
            if ($line =~ m/^( +)/) {
                my $local_indent = $1;
                if (length $local_indent != length $fold_indent) {
                    $change = 1;
                }
                $fold_indent = $1;
            }
            elsif (length $line) {
                $change = 1 if length $fold_indent;
                $fold_indent = '';
            }


            if ($type eq 'block') {
                $content .= $line . $end;
            }
            else {
                if ($change or length $fold_indent) {
                    $content .= "\n";
                }
                elsif (length $content and $content !~ m/\n\z/) {
                    $content .= ' ';
                }
                $content .= $line;
            }
        }
        else {
            last;
        }
    }
    $self->dec_indent($got_indent);
    if ($type eq 'trim') {
        $content =~ s/\n+\z/\n/;
    }
    else {
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
