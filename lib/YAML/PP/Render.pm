# ABSTRACT: YAML::PP Rendering functions
use strict;
use warnings;
package YAML::PP::Render;

our $VERSION = '0.000'; # VERSION

use constant TRACE => $ENV{YAML_PP_TRACE};
my $WS = '[\t ]';

sub render_tag {
    my ($tag, $map) = @_;
    if ($tag eq '!') {
        return "<!>";
    }
    elsif ($tag =~ m/^!(<.*)/) {
        return $1;
    }
    elsif ($tag =~ m/^(![^!]*!|!)(.+)/) {
        my $alias = $1;
        my $name = $2;
        $name =~ s/%([0-9a-fA-F]{2})/chr hex $1/eg;
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

my %control = (
    '\\' => '\\', n => "\n", t => "\t", r => "\r", b => "\b",
    'x0a' => "\n", 'x0d' => "\r",
);
sub render_quoted {
    my (%args) = @_;
    my $double = $args{double};
    my $lines = $args{lines};
    my $quoted = '';
    my $addspace = 0;
    for my $i (0 .. $#$lines) {
        my $line = $lines->[ $i ];
        if ($#$lines == 0) {
            if ($double) {
                $line =~ s/\\"/"/g;
                $line =~ s/\\(x0d|x0a|[\\ntrb])/$control{ $1 }/g;
                $line =~ s/\\u([A-Fa-f0-9]+)/chr(oct("x$1"))/eg;
            }
            else {
                $line =~ s/''/'/g;
            }
            $quoted .= $line;
            last;
        }
        my $last = $i == $#$lines;
        my $first = $i == 0;
        if ($line =~ s/^$WS*$/\n/) {
            $addspace = 0;
            if ($first or $last) {
                $quoted .= " ";
            }
            else {
                $quoted .= "\n";
            }
        }
        else {
            $quoted .= ' ' if $addspace;
            $addspace = 1;
            if ($first) {
            }
            else {
                $line =~ s/^$WS+//;
            }
            if ($last) {
            }
            else {
                $line =~ s/$WS+$//;
            }
            if ($double) {
                $line =~ s/\\"/"/g;
            }
            else {
                $line =~ s/''/'/g;
            }
            if (not $last and $line =~ s/\\$//) {
                $addspace = 0;
            }
            $line =~ s/^\\ / /;
            if ($double) {
                $line =~ s/\\(x0d|x0a|[\\ntrb])/$control{ $1 }/g;
                $line =~ s/\\u([A-Fa-f0-9]+)/chr(oct("x$1"))/eg;
            }
            $quoted .= $line;
        }
    }
    return $quoted;
}

sub render_block_scalar {
    my (%args) = @_;
    my $block_type = $args{block_type};
    my $chomp = $args{chomp};
    my $lines = $args{lines};

    my ($folded, $keep, $trim);
    if ($block_type eq '>') {
        $folded = 1;
    }
    if ($chomp eq '+') {
        $keep = 1;
    }
    elsif ($chomp eq '-') {
        $trim = 1;
    }

    my $string = '';
    if (not $keep) {
        # remove trailing empty lines
        while (@$lines) {
            if ($lines->[-1]->[0] ne 'EMPTY') {
                last;
            }
            pop @$lines;
        }
    }
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$lines], ['lines']);
    my $prev = 'START';
    for my $i (0 .. $#$lines) {
        my $item = $lines->[ $i ];
        my ($type, $indent, $line) = @$item;
        TRACE and printf STDERR "=========== %7s '%s' '%s'\n", @$item;
        if ($folded) {

            if ($type eq 'EMPTY') {
                if ($prev eq 'MORE') {
                    $type = 'PARAGRAPH';
                }
                $string .= "\n";
            }
            elsif ($type eq 'CONTENT') {
                if ($prev eq 'CONTENT') {
                    $string .= ' ';
                }
                $string .= $line;
                if ($i == $#$lines) {
                    $string .= "\n";
                }
            }
            elsif ($type eq 'MORE') {
                if ($prev eq 'EMPTY' or $prev eq 'CONTENT') {
                    $string .= "\n";
                }
                $string .=  $line . "\n";
            }
            $prev = $type;

        }
        else {
            $string .= $line . "\n";
        }
        TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$string], ['string']);
    }
    if ($trim) {
        $string =~ s/\n$//;
    }
    return $string;
}

sub render_multi_val {
    my ($multi) = @_;
    # remove empty lines at beginning and end
    while (@$multi and $multi->[0] eq '') {
        shift @$multi;
    }
    while (@$multi and $multi->[-1] eq '') {
        pop @$multi;
    }
    my $string = '';
    my $start = 1;
    for my $line (@$multi) {
        $line =~ s/\\/\\\\/g;
        if (not $start) {
            if ($line eq '') {
                $string .= "\n";
                $start = 1;
            }
            else {
                $string .= " $line";
            }
        }
        else {
            $string .= $line;
            $start = 0;
        }
    }
    return $string;
}


1;
