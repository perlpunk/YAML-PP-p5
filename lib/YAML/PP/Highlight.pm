use strict;
use warnings;
package YAML::PP::Highlight;

our $VERSION = '0.000'; # VERSION

use Encode;

my %ansicolors = (
    ANCHOR => 'green',
    ALIAS => [qw/ bold green /],
    TAG => [qw/ bold blue /],
    INDENT => [qw/ white on_grey3 /],
    COMMENT => 'grey12',
    COLON => [qw/ bold magenta /],
    DASH => [qw/ bold magenta /],
    QUESTION => [qw/ bold magenta /],
    YAML_DIRECTIVE => [qw/ cyan /],
    TAG_DIRECTIVE => [qw/ bold cyan /],
    SINGLEQUOTE => [qw/ bold green /],
    SINGLEQUOTED => [qw/ green /],
    DOUBLEQUOTE => [qw/ bold green /],
    DOUBLEQUOTED => [qw/ green /],
    LITERAL => [qw/ bold yellow /],
    FOLDED => [qw/ bold yellow /],
    DOC_START => [qw/ bold /],
    DOC_END => [qw/ bold /],
    BLOCK_SCALAR_CONTENT => [qw/ yellow /],
    TAB => [qw/ on_blue /],
    ERROR => [qw/ bold red /],
);

sub ansicolored {
    my ($class, $tokens) = @_;
    require Term::ANSIColor;

    local $Term::ANSIColor::EACHLINE = "\n";
    my $ansi = Term::ANSIColor::colored([qw/ bold /], '-' x 30);
    $ansi .= "\n";
    my $highlighted = '';
    for my $token (@$tokens) {
        my @list = map {
                $_ =~ tr/\t/\t/
                ? { name => 'TAB', value => $_ }
                : { name => $token->{name}, value => $_ }
            } split m/(\t+)/, $token->{value};
        for my $token (@list) {
            my $type = $token->{name};
            my $color = $ansicolors{ $type };
            my $str = $token->{value};
            if ($color) {
                unless (ref $color) {
                    $color = [$color];
                }
                $str = Term::ANSIColor::colored($color, $str);
            }
            $highlighted .= $str;
        }
    }
    $ansi .= "$highlighted\n";
    $ansi .= Term::ANSIColor::colored([qw/ bold /], '-' x 30);
    $ansi .= "\n";
    return $ansi;
}

my %htmlcolors = (
    ANCHOR => 'anchor',
    ALIAS => 'alias',
    SINGLEQUOTE => 'singlequote',
    DOUBLEQUOTE => 'doublequote',
    SINGLEQUOTED => 'singlequoted',
    DOUBLEQUOTED => 'doublequoted',
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
);
sub htmlcolored {
    require HTML::Entities;
    my ($class, $tokens) = @_;
    my $html = '';
    for my $token (@$tokens) {
        my @list = map {
                $_ =~ tr/\t/\t/ ? [ 'TAB', $_ ] : [ $token->{name}, $_ ]
            } split m/(\t+)/, $token->{value};
        for my $token (@list) {
            my ($type, $str) = @$token;
            my $colorclass = $htmlcolors{ $type } || 'default';
            $str = decode_utf8($str);
            $str = HTML::Entities::encode_entities($str);
            $html .= qq{<span class="$colorclass">$str</span>};
        }
    }
    return $html;
}

1;
