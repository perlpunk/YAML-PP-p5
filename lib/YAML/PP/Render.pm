# ABSTRACT: YAML::PP Rendering functions
use strict;
use warnings;
package YAML::PP::Render;

use constant TRACE => $ENV{YAML_PP_TRACE};

sub render_tag {
    my ($tag, $map) = @_;
    if ($tag eq '!') {
        return "<!>";
    }
    elsif ($tag =~ m/^(![a-z]*!|!)(.+)/) {
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
    $string =~ s/\\/\\\\/g;
    $string =~ s/\n/\\n/g;
    $string =~ s/\t/\\t/g;
    return $string;
}



1;
