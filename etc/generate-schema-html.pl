#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Data::Dumper;
use FindBin '$Bin';
use lib "$Bin/../lib";
use YAML::PP;
use URI::Escape qw/ uri_escape /;

my $file = "$Bin/../ext/yaml-test-schema/yaml-schema.yaml";
my $modulesfile = "$Bin/../examples/yaml-schema-modules.yaml";
my $htmlfile = "$Bin/../gh-pages/schema-examples.html";

my $data = YAML::PP::LoadFile($file);
my $modules = YAML::PP::LoadFile($modulesfile);
my @mods = qw/ YAML YAML::Syck YAML::XS /;

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
    if ($str == 4) {
        delete $examples{ $input };
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
my $table = schema_table(\%examples, $modules);
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
    $html .= qq{<tr><th></th><th colspan="8">YAML::PP</th><th colspan="6">Other Perl Modules</th></tr>\n};
    my $header;
    $header .= qq{<tr><th>Input YAML</th>};
    $header .= join '', map {
        my $m = $_ eq 'YAML' ? 'YAML.pm' : $_;
        qq{<th colspan="2" class="border-left">$m</th>\n};
    } (qw/ Failsafe JSON Core /, 'YAML 1.1', @mods);
    $header .= qq{</tr>\n};
    $html .= $header;
    $html .= qq{<tr><td></td>} . (qq{<td class="border-left">Type</td><td>Output</td>} x 7) . qq{</tr>\n};
    for my $i (0 .. $#all) {
        my $input = $all[ $i ];
        if ($i and $i % 30 == 0) {
            $html .= $header;
        }
        my $schemas = $examples->{ $input };
        my $mods = $modules->{ $input };
        my $input_escaped = uri_escape($input);
        $input =~ s/ /&nbsp;/g;
        $html .= qq{<tr id="input-$input_escaped"><td class="input code"><a href="#input-$input_escaped">$input</a></th>};
        for my $mod (@mods) {
            my $result = $mods->{ $mod };
            $schemas->{ $mod } = [ $result->{type}, '', $result->{dump} // '' ];
        }
        for my $schema (@keys, @mods) {
            my $example = $schemas->{ $schema };
            my $class = 'type-str';
            my ($type, $perl, $out) = @$example;
            $class = "type-$type";
            for ($out) {
                s/ /&nbsp;/g;
            }
            if ($type eq 'str') {
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

#sub format_perl {
#    my ($type, $perl) = @_;
#    my $perlcode;
#    local $Data::Dumper::Terse = 1;
#    local $Data::Dumper::Useqq = 1;
#    if ($type eq 'null') {
#        $perlcode = 'undef';
#    }
#    elsif ($type eq 'float' or $type eq 'int') {
#        $perlcode = $perl;
#    }
#    elsif ($type eq 'inf') {
#        if ($perl eq 'inf-neg()') {
#            $perlcode = '- "inf" + 0';
#        }
#        else {
#            $perlcode = '"inf" + 0';
#        }
#    }
#    elsif ($type eq 'nan') {
#        $perlcode = '"nan" + 0';
#    }
#    elsif ($type eq 'bool') {
#        $perlcode = $perl;
#    }
#    else {
#        $perlcode = Data::Dumper->Dump([$perl], ['perl']);
#    }
#    return $perlcode;
#}

sub generate_html {
    my ($content) = @_;
    my $html = <<'EOM';
<html>
<head>
<title>YAML Schema examples in YAML::PP and other Perl Modules</title>
<link rel="stylesheet" type="text/css" href="css/yaml.css">
</head>
<body>
<a href="test-suite.html">YAML Test Suite Test Cases</a>
| <a href="schema-examples.html">Schema examples</a>
| <a href="schemas.html">Schema comparison</a>
<hr>
<p>
The Perl Module YAML::PP implements <a href="https://yaml.org/spec/1.2/spec.html">YAML 1.2</a>.
You can choose between several Schemas.<br>
The following table shows which strings result in which native data, depending
on the Schema (or other YAML module) you use.<br>
For each of the Schemas and modules, the first column is the type,
and the second shows how the data is encoded into YAML again.<br>
Note that the YAML 1.2 JSON Schema is not exactly like the official schema,
as all strings would have to be quoted.
</p>
EOM
    $html .= $content;
    $html .= <<'EOM';
</body></html>
EOM
    return $html;
}


