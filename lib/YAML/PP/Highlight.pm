use strict;
use warnings;
package YAML::PP::Highlight;

our $VERSION = '0.000'; # VERSION

use YAML::PP;
use YAML::PP::Parser;
use Encode;

sub Dump {
    my (@docs) = @_;
    my $yp = YAML::PP->new;
    my $yaml = $yp->dump_string(@docs);

    my ($error, $tokens) = YAML::PP::Highlight->parse_tokens(string => $yaml);
    my $highlighted = YAML::PP::Highlight->ansicolored($tokens);
    encode_utf8 $highlighted;
}

sub parse_tokens {
    my ($class, $type, $input) = @_;
    my $yp = YAML::PP::Parser->new( receiver => sub {} );
    my @docs = eval {
        $type eq 'string' ? $yp->parse_string($input) : $yp->parse_file($input);
    };
    my $error = $@;

    my $tokens = $yp->tokens;
    my $next = $yp->lexer->next_tokens;
    if ($error) {
        push @$tokens, map { +{ %$_, name => 'ERROR' } } @$next;
        my $remaining = $yp->reader->read;
        $remaining = '' unless defined $remaining;
        push @$tokens, { name => "ERROR", value => $remaining };
    }
    else {
        push @$tokens, @$next;
    }
    return $error, $tokens;
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
);

sub ansicolored {
    my ($class, $tokens) = @_;
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

    $ansi .= "$highlighted\n";
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

sub transform {
    my ($class, $tokens) = @_;
    my @list;
    for my $token (@$tokens) {
        push @list, map {
                $_ =~ tr/\t/\t/
                ? { name => 'TAB', value => $_ }
                : { name => $token->{name}, value => $_ }
            } split m/(\t+)/, $token->{value};
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
            my $next = $list[ $i + 1];
            if ($next->{name} eq 'EOL') {
                if ($str =~ m/ \z/ and $name =~ m/^(BLOCK_SCALAR_CONTENT|WS)$/) {
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

    my ($error, $tokens) = YAML::PP::Highlight->parse_tokens(string => $yaml);
    my ($error, $tokens) = YAML::PP::Highlight->parse_tokens(file => $file);

=head1 METHODS

=over

=item parse_tokens

    my ($error, $tokens) = YAML::PP::Highlight->parse_tokens(string => $yaml);

It will return the error, if the YAML was invalid. The second return value
is the list of tokens.

Note that the tokens are very likely to be changed in the future, so don't rely
on them.

=back

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
