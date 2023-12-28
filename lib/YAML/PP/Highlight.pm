use strict;
use warnings;
package YAML::PP::Highlight;

our $VERSION = '0.000'; # VERSION

our @EXPORT_OK = qw/ Dump /;

use base 'Exporter';
use YAML::PP;
use YAML::PP::Parser;
use Encode;

sub Dump {
    my (@docs) = @_;
    # Dumping objects is safe, so we enable the Perl schema here
    require YAML::PP::Schema::Perl;
    my $yp = YAML::PP->new( schema => [qw/ + Perl /] );
    my $yaml = $yp->dump_string(@docs);

    my ($error, $tokens) = YAML::PP::Parser->yaml_to_tokens(string => $yaml);
    my $highlighted = YAML::PP::Highlight->ansicolored($tokens);
    encode_utf8 $highlighted;
}


my %ansicolors = (
    ANCHOR => [qw/ green /],
    ALIAS => [qw/ bold green /],
    TAG => [qw/ bold blue /],
    INDENT => [qw/ white on_grey3 /],
    COMMENT => [qw/ grey12 /],
    COLON => [qw/ bold magenta /],
    DASH => [qw/ bold magenta /],
    QUESTION => [qw/ bold magenta /],
    YAML_DIRECTIVE => [qw/ cyan /],
    TAG_DIRECTIVE => [qw/ bold cyan /],
    SINGLEQUOTE => [qw/ bold green /],
    SINGLEQUOTED => [qw/ green /],
    SINGLEQUOTED_LINE => [qw/ green /],
    DOUBLEQUOTE => [qw/ bold green /],
    DOUBLEQUOTED => [qw/ green /],
    DOUBLEQUOTED_LINE => [qw/ green /],
    LITERAL => [qw/ bold yellow /],
    FOLDED => [qw/ bold yellow /],
    DOC_START => [qw/ bold /],
    DOC_END => [qw/ bold /],
    BLOCK_SCALAR_CONTENT => [qw/ yellow /],
    TAB => [qw/ on_blue /],
    ERROR => [qw/ bold red /],
    EOL => [qw/ grey12 /],
    TRAILING_SPACE => [qw/ on_grey6 /],
    FLOWSEQ_START => [qw/ bold magenta /],
    FLOWSEQ_END => [qw/ bold magenta /],
    FLOWMAP_START => [qw/ bold magenta /],
    FLOWMAP_END => [qw/ bold magenta /],
    FLOW_COMMA => [qw/ bold magenta /],
    PLAINKEY => [qw/ bright_blue /],
);

sub ansicolored {
    my ($class, $tokens, %args) = @_;
    my $expand_tabs = $args{expand_tabs};
    $expand_tabs = 1 unless defined $expand_tabs;
    require Term::ANSIColor;

    local $Term::ANSIColor::EACHLINE = "\n";
    my $ansi = '';
    my $highlighted = '';

    my @list = $class->transform($tokens);


    for my $token (@list) {
        my $name = $token->{name};
        my $str = $token->{value};

        my $color = $ansicolors{ $name };
        if ($color) {
            $str = Term::ANSIColor::colored($color, $str);
        }
        $highlighted .= $str;
    }

    if ($expand_tabs) {
        # Tabs can't be displayed with ansicolors
        $highlighted =~ s/\t/' ' x 8/eg;
    }
    $ansi .= $highlighted;
    return $ansi;
}

my %htmlcolors = (
    ANCHOR => 'anchor',
    ALIAS => 'alias',
    SINGLEQUOTE => 'singlequote',
    DOUBLEQUOTE => 'doublequote',
    SINGLEQUOTED => 'singlequoted',
    DOUBLEQUOTED => 'doublequoted',
    SINGLEQUOTED_LINE => 'singlequoted',
    DOUBLEQUOTED_LINE => 'doublequoted',
    INDENT => 'indent',
    DASH => 'dash',
    COLON => 'colon',
    QUESTION => 'question',
    YAML_DIRECTIVE => 'yaml_directive',
    TAG_DIRECTIVE => 'tag_directive',
    TAG => 'tag',
    COMMENT => 'comment',
    LITERAL => 'literal',
    FOLDED => 'folded',
    DOC_START => 'doc_start',
    DOC_END => 'doc_end',
    BLOCK_SCALAR_CONTENT => 'block_scalar_content',
    TAB => 'tab',
    ERROR => 'error',
    EOL => 'eol',
    TRAILING_SPACE => 'trailing_space',
    FLOWSEQ_START => 'flowseq_start',
    FLOWSEQ_END => 'flowseq_end',
    FLOWMAP_START => 'flowmap_start',
    FLOWMAP_END => 'flowmap_end',
    FLOW_COMMA => 'flow_comma',
    PLAINKEY => 'plainkey',
    NOEOL => 'noeol',
);
sub htmlcolored {
    require HTML::Entities;
    my ($class, $tokens) = @_;
    my $html = '';
    my @list = $class->transform($tokens);
    for my $token (@list) {
        my $name = $token->{name};
        my $str = $token->{value};
        my $colorclass = $htmlcolors{ $name } || 'default';
        $str = HTML::Entities::encode_entities($str);
        $html .= qq{<span class="$colorclass">$str</span>};
    }
    return $html;
}

my %svgcolors = (
    ANCHOR => 'green',
    ALIAS => 'green',
    SINGLEQUOTE => 'green',
    DOUBLEQUOTE => 'green',
    SINGLEQUOTED => 'green',
    DOUBLEQUOTED => 'green',
    SINGLEQUOTED_LINE => 'green',
    DOUBLEQUOTED_LINE => 'green',
    INDENT => 'indent',
    DASH => 'magenta',
    COLON => 'magenta',
    QUESTION => 'magenta',
    YAML_DIRECTIVE => 'lightblue',
    TAG_DIRECTIVE => 'lightblue',
    TAG => 'blue',
    COMMENT => 'grey',
    LITERAL => 'magenta',
    FOLDED => 'magenta',
    DOC_START => 'blue',
    DOC_END => 'blue',
    BLOCK_SCALAR_CONTENT => 'darkorange',
    TAB => '',
    ERROR => 'red',
    EOL => 'grey',
    TRAILING_SPACE => '',
    FLOWSEQ_START => 'green',
    FLOWSEQ_END => 'green',
    FLOWMAP_START => 'green',
    FLOWMAP_END => 'green',
    FLOW_COMMA => 'green',
    PLAINKEY => 'blue',
    NOEOL => '',
);
sub svgcolored {
    require HTML::Entities;
    my ($class, $tokens) = @_;
    my @list = $class->transform($tokens);
    my $nextx = 10;
    my $body = '';
    my $lines = 0;
    my $linebreak = 0;
    for my $i (0 .. $#list) {
        my $token = $list[ $i ];
        my $name = $token->{name};
        my $str = $token->{value};
        my $colorclass = $svgcolors{ $name };
        $str = HTML::Entities::encode_entities($str);
        $str =~ s/ /&#160;/g;
        my $x = defined $nextx ? qq{x="$nextx"} : '';
        my $style = '';
        if ($colorclass) {
            my ($fg, $bg) = ref $colorclass ? @$colorclass : ($colorclass, undef);
            $fg ||= 'black';
            $style = qq{fill:$fg;} if $fg;
            $style .= qq{stroke:$bg} if $bg;
        }
        my $dy = $linebreak ? "1.5em" : $i == 0 ? "1.5em" : "0em";
        if ($name eq 'EOL') {
            $linebreak = 1;
            $lines++;
#            $dy = "1em";
            $nextx = 10;
        }
        else {
#            $dy = $i == 0 ? "1.5em" : "0em";
            undef $nextx;
            $linebreak = 0;
        }
        $body .= qq{<tspan $x dy="$dy" style="$style">$str</tspan>};
    }
    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$lines], ['lines']);
    my $height = $lines * 1.5 + 4;
    my $header = <<"EOM";
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
height="${height}em" width="300">
<rect x="-2" y="-2" width="100%" height="100%" fill="#f0f0f0" stroke="#787878" stroke-width="5"/>
<polygon points="2,18 22,7 22,33" style="fill:cyan" />
<circle cx="17" cy="18" r="3" stroke="#444444" stroke-width="1" fill="cyan" />
<rect x="24" y="10" width="50" height="20" fill="cyan" stroke="cyan" stroke-width="5"/>

<text x="28" y="25"  font-family="monospace" font-size="130%"><tspan>\$ID</tspan>
</text>
<text x="0" y="35" style="font-family:monospace;" xml:space="preserve">

EOM
    my $footer = qq{</text></svg>};
    my $svg = $header . $body . $footer;
    return $svg;
}

sub transform {
    my ($class, $tokens) = @_;
    my @list;
    for my $token (@$tokens) {
        my @values;
        my $value = $token->{value};
        my $subtokens = $token->{subtokens};
        if ($subtokens) {
            @values = @$subtokens;
        }
        else {
            @values = $token;
        }
        for my $token (@values) {
            my $value = defined $token->{orig} ? $token->{orig} : $token->{value};
            if ($token->{name} eq 'EOL' and not length $value) {
                push @list, { name => 'NOEOL', value => '' };
                next;
            }
            push @list, map {
                    $_ =~ tr/\t/\t/
                    ? { name => 'TAB', value => $_ }
                    : { name => $token->{name}, value => $_ }
                } split m/(\t+)/, $value;
        }
    }
    for my $i (0 .. $#list) {
        my $token = $list[ $i ];
        my $name = $token->{name};
        my $str = $token->{value};
        my $trailing_space = 0;
        if ($token->{name} eq 'EOL') {
            if ($str =~ m/ +([\r\n]|\z)/) {
                $token->{name} = "TRAILING_SPACE";
            }
        }
        elsif ($i < $#list) {
            if ($name eq 'PLAIN') {
                for my $n ($i+1 .. $#list) {
                    my $next = $list[ $n ];
                    last if $next->{name} eq 'EOL';
                    next if $next->{name} =~ m/^(WS|SPACE)$/;
                    if ($next->{name} eq 'COLON') {
                        $token->{name} = 'PLAINKEY';
                    }
                }
            }
            my $next = $list[ $i + 1];
            if ($next->{name} eq 'EOL') {
                if ($str =~ m/ \z/ and $name =~ m/^(BLOCK_SCALAR_CONTENT|WS|INDENT)$/) {
                    $token->{name} = "TRAILING_SPACE";
                }
            }
        }
    }
    return @list;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Highlight - Syntax highlighting utilities

=head1 SYNOPSIS


    use YAML::PP::Highlight qw/ Dump /;

    my $highlighted = Dump $data;

=head1 FUNCTIONS

=over

=item Dump

=back

    use YAML::PP::Highlight qw/ Dump /;

    my $highlighted = Dump $data;
    my $highlighted = Dump @docs;

It will dump the given data, and then parse it again to create tokens, which
are then highlighted with ansi colors.

The return value is ansi colored YAML.
