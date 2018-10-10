# ABSTRACT: YAML::PP Rendering functions
use strict;
use warnings;
package YAML::PP::Render;

our $VERSION = '0.000'; # VERSION

use constant TRACE => $ENV{YAML_PP_TRACE} ? 1 : 0;

sub render_tag {
    my ($tag, $map) = @_;
    if ($tag eq '!') {
        return "!";
    }
    elsif ($tag =~ m/^!<(.*)>/) {
        return $1;
    }
    elsif ($tag =~ m/^(![^!]*!|!)(.+)/) {
        my $alias = $1;
        my $name = $2;
        $name =~ s/%([0-9a-fA-F]{2})/chr hex $1/eg;
        if (exists $map->{ $alias }) {
            $tag = $map->{ $alias }. $name;
        }
        else {
            if ($alias ne '!' and $alias ne '!!') {
                die "Found undefined tag handle '$alias'";
            }
            $tag = "!$name";
        }
    }
    else {
        die "Invalid tag";
    }
    return $tag;
}

sub render_quoted {
    my ($self, $style, $lines) = @_;

    my $quoted = '';
    my $addspace = 0;

    for my $i (0 .. $#$lines) {
        my $line = $lines->[ $i ];
        my $value = $line->{value};
        my $last = $i == $#$lines;
        my $first = $i == 0;
        if ($value eq '') {
            if ($first) {
                $addspace = 1;
            }
            elsif ($last) {
                $quoted .= ' ' if $addspace;
            }
            else {
                $addspace = 0;
                $quoted .= "\n";
            }
            next;
        }

        $quoted .= ' ' if $addspace;
        $addspace = 1;
        if ($style eq '"') {
            if ($line->{orig} =~ m/\\$/) {
                $line->{value} =~ s/\\$//;
                $value =~ s/\\$//;
                $addspace = 0;
            }
        }
        $quoted .= $value;
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

        my $prev = 'START';
        for my $i (0 .. $#$lines) {
            my $line = $lines->[ $i ];

            my $type = $line eq ''
                ? 'EMPTY'
                : $line =~ m/\A[ \t]/
                    ? 'MORE'
                    : 'CONTENT';

            if ($prev eq 'MORE' and $type eq 'EMPTY') {
                $type = 'MORE';
            }
            elsif ($prev eq 'CONTENT') {
                if ($type ne 'CONTENT') {
                    $string .= "\n";
                }
                elsif ($type eq 'CONTENT') {
                    $string .= ' ';
                }
            }
            elsif ($prev eq 'START' and $type eq 'EMPTY') {
                $string .= "\n";
                $type = 'START';
            }
            elsif ($prev eq 'EMPTY' and $type ne 'CONTENT') {
                $string .= "\n";
            }

            $string .= $line;

            if ($type eq 'MORE' and $i < $#$lines) {
                $string .= "\n";
            }

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
    $info->{value} = $string;
}

sub render_multi_val {
    my ($self, $info) = @_;
    my $multi = $info->{value};
    return unless ref $multi;
    # remove empty lines at the end
    while (@$multi and $multi->[-1] eq '') {
        pop @$multi;
    }
    my $string = '';
    my $start = 1;
    for my $line (@$multi) {
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
    $info->{value} = $string;
}


1;
