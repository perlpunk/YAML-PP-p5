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
            if ($alias ne '!' and $alias ne '!!') {
                die "Found undefined tag handle '$alias'";
            }
            $tag = "<!$name>";
        }
    }
    else {
        die "Invalid tag";
    }
    return $tag;
}

my %control = (
    '\\' => '\\', '/' => '/', n => "\n", t => "\t", r => "\r", b => "\b",
    'x0a' => "\n", 'x0d' => "\r",
);

sub render_quoted {
    my ($self, $info) = @_;
    my $double = $info->{style} eq '"';
    my $lines = $info->{value};

    if ($#$lines == 0) {
        my $quoted = $lines->[0];
        if ($double) {
            $quoted =~ s/\\"/"/g;
            $quoted =~ s/\\(x0d|x0a|[\\\/ntrb])/$control{ $1 }/g;
            $quoted =~ s/\\u([A-Fa-f0-9]+)/chr(oct("x$1"))/eg;
        }
        else {
            $quoted =~ s/''/'/g;
        }
        return $quoted;
    }

    my $quoted = '';
    my $addspace = 0;

    for my $i (0 .. $#$lines) {
        my $line = $lines->[ $i ];
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
            if (not $first) {
                $line =~ s/^$WS+//;
            }
            if (not $last) {
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
                $line =~ s/\\(x0d|x0a|[\\\/ntrb])/$control{ $1 }/g;
                $line =~ s/\\u([A-Fa-f0-9]+)/chr(oct("x$1"))/eg;
            }
            $quoted .= $line;
        }
    }
    return $quoted;
}

sub render_block_scalar {
    my ($self, $info) = @_;
    my $block_type = $info->{style};
    my $chomp = $info->{block_chomp} || '';
    my $lines = $info->{value};

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
            last if $lines->[-1] ne '';
            pop @$lines;
        }
    }
    if ($folded) {

        my $prev = '';
        for my $i (0 .. $#$lines) {
            my $line = $lines->[ $i ];

            my $type = $line eq ''
                ? 'EMPTY'
                : $line =~ m/\A[ \t]/
                ? 'MORE'
                : 'CONTENT';
            if ($i > 0) {
                if ($type eq 'EMPTY' and $prev eq 'MORE') {
                    $type = 'MORE';
                }

                if ($type eq 'CONTENT') {
                    if ($prev eq 'MORE') {
                        $string .= "\n";
                    }
                    elsif ($prev eq 'CONTENT') {
                        $string .= ' ';
                    }
                }
                else {
                    $string .= "\n";
                }
            }
            else {
                if ($type eq 'EMPTY') {
                    $string .= "\n";
                }
            }
            $string .= $line;

            $prev = $type;
        }
        $string .= "\n" if @$lines and not $trim;
    }
    else {
        for my $i (0 .. $#$lines) {
            $string .= $lines->[ $i ];
            $string .= "\n" if ($i != $#$lines or not $trim);
        }
    }
    TRACE and warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$string], ['string']);
    return $string;
}

sub render_multi_val {
    my ($self, $info) = @_;
    my $multi = $info->{value};
    return $multi unless ref $multi;
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
        #$line =~ s/\\/\\\\/g;
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
