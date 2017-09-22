#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use FindBin '$Bin';

use Data::Dumper;
use YAML::XS qw/ Load Dump /;

my $grammar_file = "$Bin/grammar.yaml";
open my $fh, '<', $grammar_file or die $!;
my $yaml = do { local $/; <$fh> };
close $fh;

my $module_file = "$Bin/../lib/YAML/PP/Grammar.pm";

my $grammar = Load $yaml;

open $fh, '<', $module_file or die $!;
my $replaced = '';
while (my $line = <$fh>) {
    my $state = $line =~ m/^# START OF GRAMMAR INLINE/ ... $line =~ m/^# END OF GRAMMAR INLINE/;
    my $state2 = $line =~ m/^ *# START OF YAML INLINE/ ... $line =~ m/^ *# END OF YAML INLINE/;
    if ($state) {
        if ($state == 1) {
            $replaced .= $line;
            local $Data::Dumper::Indent = 1;
            local $Data::Dumper::Sortkeys = 1;
            my $dump = Data::Dumper->Dump([$grammar], ['GRAMMAR']);
            $replaced .= <<"EOM";

# DO NOT CHANGE THIS
# This grammar is automatically generated from etc/grammar.yaml

$dump

EOM
        }
        elsif ($state =~ m/E0$/) {
            $replaced .= $line;
        }
    }
    elsif ($state2) {
        if ($state2 == 1) {
            $replaced .= $line;
            my $yaml_formatted = $yaml;
            $yaml_formatted =~ s/^/    /mg;
            $replaced .= <<"EOM";

    # DO NOT CHANGE THIS
    # This grammar is automatically generated from etc/grammar.yaml

$yaml_formatted

EOM
        }
        elsif ($state2 =~ m/E0$/) {
            $replaced .= $line;
        }
    }
    else {
        $replaced .= $line;
    }
}
close $fh;

open $fh, '>', $module_file or die $!;
print $fh $replaced;
close $fh;

