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

    my $doc = 0;
    while (length $$yaml) {
        if ($$yaml =~ s/^ *# .*\n//) {
            next;
        }
        if ($$yaml =~ s/^ *\n//) {
            next;
        }

        if ($$yaml =~ s/^\s*%YAML ?1\.2\s*//) {
        }

        if ($$yaml =~ s/^--- ?//) {
            if ($doc) {
                $doc--;
                $self->cb->($self, "-DOC");
            }
            $self->cb->($self, "+DOC", "---");
            $doc++;
            $$yaml =~ s/^#.*\n//;
            $$yaml =~ s/^\n//;
            next;
        }
        elsif (not $doc) {
            $self->cb->($self, "+DOC");
            $doc++;
            next;
        }

        TRACE and $self->debug_yaml;
        my $content = $self->parse_node;

        if ($$yaml =~ s/^\.\.\. ?//) {
            $self->cb->($self, "-DOC", "...");
            $$yaml =~ s/^#.*\n//;
            $$yaml =~ s/^\n//;
            $doc--;
        }
    }
    if ($doc) {
        $self->cb->($self, "-DOC");
    }
}

sub parse_node {
    my ($self) = @_;
    my $yaml = $self->yaml;
    my $content = 0;
    while (length $$yaml) {
        last if $$yaml =~ m/^--- ?/;
        last if $$yaml =~ m/^\.\.\. ?/;
        $$yaml =~ s/^(.*)\n// or next;
        my $line = $1;
        next unless length $line;
        TRACE and warn __PACKAGE__.':'.__LINE__.": LINE: '$line'\n";
        if ($line =~ s/^ *$//) {
            next;
        }
        if ($line =~ s/^ *# .*//) {
            next;
        }
        $content++;
        $self->cb->($self, "=VAL", $line);
    }
    return $content;
}


sub debug_yaml {
    my ($self) = @_;
    my $yaml = $self->yaml;
    warn "YAML: <<$$yaml>>\n";
}
1;
