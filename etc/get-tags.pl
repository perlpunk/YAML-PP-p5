#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use YAML::PP qw/ DumpFile /;

sub get_tags {
    my ($dir) = @_;
    my %tag_id;

    opendir my $dh, $dir or die $!;
    my @tags = grep { not m/^\./ } readdir $dh;
    for my $tag (sort @tags) {
        next unless -d "$dir/$tag";
        opendir my $dh, "$dir/$tag" or die $!;
        my @ids = grep { -l "$dir/$tag/$_" } readdir $dh;
        $tag_id{ $tag }->{ $_ } = 1 for @ids;
        closedir $dh;
    }
    closedir $dh;
    return \%tag_id;
}

my $data = get_tags("$Bin/../test-suite/yaml-test-suite-data/tags");
DumpFile("$Bin/../test-suite/tag_id.yaml", $data);
