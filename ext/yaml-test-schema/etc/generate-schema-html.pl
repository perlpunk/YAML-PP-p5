#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Data::Dumper;
use FindBin '$Bin';
use lib "$Bin/../lib";
use YAML::PP;
use URI::Escape qw/ uri_escape /;

my $file = "$Bin/../yaml-schema.yaml";
my $htmlfile = "$Bin/../gh-pages/data.html";

my $data = YAML::PP::LoadFile($file);

my %examples;

for my $input (sort keys %$data) {
    my $schemas = $data->{ $input };
    my @keys = keys %$schemas;
    for my $key (@keys) {
        my $def = $schemas->{ $key };
        my @schemas = split m/ *, */, $key;
        for my $schema (@schemas) {
            $examples{ $input }->{ $schema } = $def;
        }
    }
}
my @keys = qw/ failsafe json core yaml11 /;
for my $input (sort keys %examples) {
    my $schemas = $examples{ $input };
    my $str = 0;
    for my $schema (@keys) {
        my $example = $schemas->{ $schema };
        unless ($example) {
            $example = $schemas->{ $schema } = [ 'todo', '', '', '' ];
        }
        if ($example->[0] eq 'str' or $example->[0] eq 'todo') {
            $str++;
        }
    }
}

my %type_index = (
    null => 0,
    bool => 1,
    float => 2,
    inf => 3,
    nan => 4,
    int => 5,
    str => 6,
    todo => 7,
);
my $table = schema_table(\%examples);
my $html = generate_html($table);

open my $fh, '>', $htmlfile or die $!;
print $fh $html;
close $fh;

sub sort_rows {
    my ($x, $y, $a, $b) = @_;
           $type_index{ $x->{yaml11}->[0] } <=> $type_index{ $y->{yaml11}->[0] }
        || $type_index{ $x->{core}->[0] } <=> $type_index{ $y->{core}->[0] }
        || $type_index{ $x->{json}->[0] } <=> $type_index{ $y->{json}->[0] }
        || lc $a cmp lc $b
        || $a cmp $b
}
sub schema_table {
    my ($examples) = @_;
    my $html = '<table class="schema">';
    my @sorted = sort {
        sort_rows($examples->{ $a }, $examples->{ $b }, $a, $b)
    } grep { not m/^!!\w/ } keys %$examples;
    my @sorted_explicit = sort {
        sort_rows($examples->{ $a }, $examples->{ $b }, $a, $b)
    } grep { m/^!!\w/ } keys %$examples;
    my @all = (@sorted, @sorted_explicit);
    $html .= qq{<tr><th></th><th colspan="6">YAML 1.2</th><th colspan="2">YAML 1.1</th></tr>\n};
    my $header;
    $header .= qq{<tr><th>Input YAML</th>};
    $header .= join '', map {
        my $m = $_ eq 'YAML' ? 'YAML.pm' : $_;
        qq{<th colspan="2" class="border-left">$m</th>\n};
    } (qw/ Failsafe JSON Core /, 'YAML 1.1');
    $header .= qq{</tr>\n};
    $html .= $header;
    $html .= qq{<tr><td></td>} . (qq{<td class="border-left">Type</td><td>Output</td>} x 4) . qq{</tr>\n};
    for my $i (0 .. $#all) {
        my $input = $all[ $i ];
        if ($i and $i % 30 == 0) {
            $html .= $header;
        }
        my $schemas = $examples->{ $input };
        my $input_escaped = uri_escape($input);
        $input =~ s/ /&nbsp;/g;
        $html .= qq{<tr id="input-$input_escaped"><td class="input code"><a href="#input-$input_escaped">$input</a></th>};
        for my $schema (@keys) {
            my $example = $schemas->{ $schema };
            my $class = 'type-str';
            my ($type, $perl, $out) = @$example;
            $class = "type-$type";
            for ($out) {
                s/ /&nbsp;/g;
            }
            if (0 and $type eq 'str') {
                $html .= qq{<td class="code $class border-left" colspan="2">$type</td>};
            }
            else {
                $html .= qq{<td class="code $class border-left">$type</td><td class="code $class"><pre>$out</pre></td>};
            }
        }
        $html .= qq{</tr>\n};
    }
    $html .= "</table>";
    return $html;
}

sub generate_html {
    my ($content) = @_;
    my $html = <<'EOM';
<html>
<head>
<title>YAML Schema Data</title>
<link rel="stylesheet" type="text/css" href="css/yaml.css">
</head>
<body>
<a href="index.html">YAML Test Schema</a>
| <a href="schemas.html">Schemas</a>
| <a href="data.html">Test Data</a>
<hr>
<p>
For each of the four schemas, the first column shows to which type the input
YAML should resolve. The second column shows how the output YAML should
look like.
</p>
EOM
    $html .= $content;
    $html .= <<'EOM';
</body></html>
EOM
    return $html;
}


