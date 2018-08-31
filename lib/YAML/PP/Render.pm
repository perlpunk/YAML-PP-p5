# ABSTRACT: YAML::PP Rendering functions
use strict;
use warnings;
package YAML::PP::Render;

our $VERSION = '0.000'; # VERSION

use constant TRACE => $ENV{YAML_PP_TRACE} ? 1 : 0;
my $WS = '[\t ]';

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

my %control = (
    '\\' => '\\', '/' => '/', n => "\n", t => "\t", r => "\r", b => "\b",
    'a' => "\a", 'b' => "\b", 'e' => "\e", 'f' => "\f", 'v' => "\x0b",
    'P' => "\x{2029}", L => "\x{2028}", 'N' => "\x85",
    '0' => "\0", '_' => "\xa0", ' ' => ' ', q/"/ => q/"/,
);

sub render_quoted {
    my ($self, $info) = @_;
    my $double = $info->{style} eq '"';
    my $lines = $info->{value};

    if ($#$lines == 0) {
        my $quoted = $lines->[0];
        if ($double) {
            $quoted =~ s{(?:
                \\([ \\\/_0abefnrtvLNP"]) | \\x([0-9a-fA-F]{2})
                | \\u([A-Fa-f0-9]{4}) | \\U([A-Fa-f0-9]{4,8})
            )}{
            defined $1 ? $control{ $1 } : defined $2 ? chr hex $2 :
            defined $3 ? chr hex $3 : chr hex $4
            }xeg;
        }
        else {
            $quoted =~ s/''/'/g;
        }
        $info->{value} = $quoted;
        return;
    }

    my $quoted = '';
    my $addspace = 0;

    for my $i (0 .. $#$lines) {
        my $line = $lines->[ $i ];
        my $last = $i == $#$lines;
        my $first = $i == 0;
        if ($line =~ s/^$WS*$/\n/) {
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
        if (not $first) {
            $line =~ s/^$WS+//;
        }
        if (not $last) {
            $line =~ s/$WS+$//;
        }
        if ($double) {
            $line =~ s{(?:
                \\([ \\\/_0abefnrtvLNP"]) | \\x([0-9a-fA-F]{2})
                | \\u([A-Fa-f0-9]{4}) | \\U([A-Fa-f0-9]{4,8})
            )}{
            defined $1 ? $control{ $1 } : defined $2 ? chr hex $2 :
            defined $3 ? chr hex $3 : chr hex $4
            }xeg;
            if ($line =~ s/\\$//) {
                $addspace = 0;
            }
        }
        else {
            $line =~ s/''/'/g;
        }
        $quoted .= $line;
    }
    $info->{value} = $quoted;
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
    $info->{value} = $string;
}


1;
