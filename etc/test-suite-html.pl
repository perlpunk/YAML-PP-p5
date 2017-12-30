#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use FindBin '$Bin';
use lib "$Bin/../lib";

use IO::All;
use Data::Dumper;
use YAML::PP;
use YAML::PP::Dumper;
use File::Basename qw/ basename /;
use HTML::Entities qw/ encode_entities /;
use YAML::PP::Highlight;
use JSON::XS ();
use Encode;

chomp(my $version = qx{git describe --dirty});
my $yaml_test_suite = 'yaml-test-suite';
my @dirs = grep { m{/[0-9A-Z]{4}$} } map { "$_" } io->dir($yaml_test_suite)->all;
my @valid = grep { not -f "$_/error" } @dirs;
my @invalid = grep { -f "$_/error" } @dirs;

my %tags;
for my $tagdir (io->dir("$yaml_test_suite/tags")->all) {
    for my $id (io->dir($tagdir)->all) {
        my $tag = basename $tagdir;
        push @{ $tags{ basename $id } }, basename $tag;
    }
}

my $html = <<"EOM";
<html>
<head>
<title>YAML Test Suite Highlighted</title>
<link rel="stylesheet" type="text/css" href="css/yaml.css">
<style>
body {
    font-family: Arial;
}
table.highlight {
    border: 1px solid #bbb;
    border-collapse: collapse;
    box-shadow: 2px 2px 4px 1px grey;
}
table.highlight tr th, table.highlight tr td {
    border: 1px solid #bbb;
    background-color: white;
    padding: 2px 3px 2px 3px;

}
td.error {
    background-color: #ff7777;
}
td.diff {
    background-color: #ffff77;
}
td.ok {
    background-color: #7777ff;
}
span.anchor { color: green; }
span.indent { background-color: #e8e8e8; }
span.dash { font-weight: bold; color: magenta; }
span.colon { font-weight: bold; color: magenta; }
span.question { font-weight: bold; color: magenta; }
span.yaml_directive { color: cyan; }
span.tag_directive { color: cyan; }
span.tag { color: blue; }
span.comment { color: grey; }
span.alias { color: green; }
span.singlequote { font-weight: bold; color: green; }
span.doublequote { font-weight: bold; color: green; }
span.singlequoted { color: green; }
span.doublequoted { color: green; }
span.literal { font-weight: bold; color: magenta; }
span.folded { font-weight: bold; color: magenta; }
span.doc_start { font-weight: bold; }
span.doc_end { font-weight: bold; }
span.block_scalar_content { color: #aa7700; }
span.tab { background-color: lightblue; }
span.error { background-color: #ff8888; }
span.trailing_space { background-color: magenta; }
span.flowseq_start { font-weight: bold; color: magenta; }
span.flowseq_end { font-weight: bold; color: magenta; }
span.flowmap_start { font-weight: bold; color: magenta; }
span.flowmap_end { font-weight: bold; color: magenta; }
span.flow_comma { font-weight: bold; color: magenta; }

pre {
    background-color: white;
    padding: 2px;
}
pre.error {
    border: 1px solid red;
}
pre.diff {
    border: 1px solid #ff9900;
}
</style>
</head>
<body>
Generated with YAML::PP $version<br>
<a href="#valid">Valid (@{[ scalar @valid ]})</a><br>
<a href="#invalid">Invalid (@{[ scalar @invalid ]})</a><br>
EOM

my $ypp = YAML::PP->new(
    boolean => 'JSON::PP',
);
my $table;
for my $dir (sort @valid) {
    my $test = highlight_test($dir);
    $table .= $test;
}
$html .= <<"EOM";
<h1><a name="valid">Valid</a></h1>
<table class="highlight">
<tr>
<td></td>
<td>YAML::PP::Highlight</td>
<td>YAML::PP::Loader | Data::Dump</td>
<td>YAML::PP::Loader | JSON::XS</td>
<td>YAML::PP::Loader | YAML::PP::Dumper</td>
</tr>
$table
</table>
EOM
$table = '';

for my $dir (sort @invalid) {
    my $test = highlight_test($dir);
    $table .= $test;
}
$html .= <<"EOM";
<h1><a name="invalid">Invalid</a></h1>
<table class="highlight">
<tr>
<td></td>
<td>YAML::PP::Highlight</td>
<td>YAML::PP::Loader | Data::Dump</td>
<td>YAML::PP::Loader | JSON::XS</td>
<td>YAML::PP::Loader | YAML::PP::Dumper</td>
</tr>
$table
</table>
EOM

sub highlight_test {
    my ($dir) = @_;
    my $html;
    my $file = "$dir/in.yaml";
    my $id = basename $dir;
    my $title = io->file("$dir/===")->slurp;
    my $yaml;

    warn "$id\n";
    $yaml = do { open my $fh, '<', $file or die $!; local $/; <$fh> };
    $yaml = decode_utf8 $yaml;

    my $class = "ok";
    my @docs;
    eval {
        @docs = $ypp->load_string($yaml);
    };
    my $error = $@ || '';
    my $tokens = $ypp->loader->parser->tokens;
    my $diff = 0;
    if ($error) {
        $error =~ s{\Q$Bin/../lib/}{};
        $class = "error";
        my $remaining_tokens = $ypp->loader->parser->lexer->next_tokens;
        push @$tokens, map {
            { name => 'ERROR', value => $_->{value} } } @$remaining_tokens;
        my $remaining = $ypp->loader->parser->lexer->reader->read;
        push @$tokens, { name => 'ERROR', value => $remaining };
        my $out = join '', map { $_->{value} } @$tokens;
        if ($out ne $yaml) {
            warn "$id error diff";
            $diff = 1;
        }
    }
    else {
        my $out = join '', map { $_->{value} } @$tokens;
        if ($out ne $yaml) {
            $class = "diff";
            warn "$id diff";
            $diff = 1;
        }
    }

    my $coder = JSON::XS->new->ascii->pretty->allow_nonref->canonical;
    my $json_dump = join "\n", map {
        "Doc " . ($_+1) . ': ' . $coder->encode( $docs[ $_ ] );
    } 0 .. $#docs;

    my $yppd = YAML::PP::Dumper->new( bool => 'JSON::PP' );
    my $yaml_dump = $yppd->dump_string(@docs);

    my @reload_docs = $ypp->load_string($yaml_dump);
    my $reload_tokens = $ypp->loader->parser->tokens;

    my $dd = eval { require Data::Dump; 1 };
    my $data_dump = join "\n", map {
        if ($dd) {
            '$doc' . ($_ + 1) . ' = ' . Data::Dump::dump( $docs[ $_ ] );
        }
        else {
            local $Data::Dumper::Useqq = 1;
            local $Data::Dumper::Sortkeys = 1;
            Data::Dumper->Dump([$docs[ $_ ]], ['doc' . ($_ + 1)]);
        }
    } 0 .. $#docs;

    $title = decode_utf8($title);
    $title = encode_entities($title);
    $error =~ s{\Q$Bin/../lib/}{}g;
    $error = encode_entities($error);
    $yaml = encode_entities($yaml);
    $data_dump = encode_entities($data_dump);
    $json_dump = encode_entities($json_dump);
    $yaml_dump = encode_entities($yaml_dump);
    my $taglist = join ', ', @{ $tags{ $id } || [] };
    $html .= <<"EOM";
<tr>
<td colspan="5" valign="top" style="background-color: #dddddd"><b>$id - $title</b></td></tr>
<tr>
<td style="max-width: 15em;" valign="top" >Tags:<br>$taglist<br>
<a href="https://github.com/yaml/yaml-test-suite/blob/master/test/$id.tml">View source</a><br>
</td>
EOM
    my $high = YAML::PP::Highlight->htmlcolored($tokens);
    my $reload_high = YAML::PP::Highlight->htmlcolored($reload_tokens);
    my $orig = $diff ? qq{<br><pre>$yaml</pre>} : '';
    $html .= <<"EOM";
<td style="max-width: 20em; overflow-x: auto;" valign="top"><pre class="$class">$high</pre>
<pre>$error</pre>
$orig
</td>
<td valign="top" style="max-width: 20em; overflow-x: auto;">
<pre>$data_dump</pre>
</td>
<td valign="top" style="max-width: 20em; overflow-x: auto;">
<pre>$json_dump</pre>
</td>
<td valign="top" style="max-width: 20em; overflow-x: auto;">
<pre>$reload_high</pre>
</td>
</tr>
EOM
    return $html;

}

$html .= <<"EOM";
</body></html>
EOM

binmode STDOUT, ":encoding(utf-8)";
say $html;
