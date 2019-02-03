use strict;
use warnings;
package YAML::PP::Common;

our $VERSION = '0.000'; # VERSION

use base 'Exporter';

our @EXPORT_OK = qw/
    YAML_ANY_SCALAR_STYLE YAML_PLAIN_SCALAR_STYLE
    YAML_SINGLE_QUOTED_SCALAR_STYLE YAML_DOUBLE_QUOTED_SCALAR_STYLE
    YAML_LITERAL_SCALAR_STYLE YAML_FOLDED_SCALAR_STYLE
    YAML_QUOTED_SCALAR_STYLE

    YAML_ANY_SEQUENCE_STYLE
    YAML_BLOCK_SEQUENCE_STYLE YAML_FLOW_SEQUENCE_STYLE

    YAML_ANY_MAPPING_STYLE
    YAML_BLOCK_MAPPING_STYLE YAML_FLOW_MAPPING_STYLE
/;

use constant {
    YAML_ANY_SCALAR_STYLE           => 'A',
    YAML_PLAIN_SCALAR_STYLE         => ':',
    YAML_SINGLE_QUOTED_SCALAR_STYLE => "'",
    YAML_DOUBLE_QUOTED_SCALAR_STYLE => '"',
    YAML_LITERAL_SCALAR_STYLE       => '|',
    YAML_FOLDED_SCALAR_STYLE        => '>',
    YAML_QUOTED_SCALAR_STYLE        => 'Q',

    YAML_ANY_SEQUENCE_STYLE   => 'any',
    YAML_BLOCK_SEQUENCE_STYLE => 'block',
    YAML_FLOW_SEQUENCE_STYLE  => 'flow',

    YAML_ANY_MAPPING_STYLE   => 'any',
    YAML_BLOCK_MAPPING_STYLE => 'block',
    YAML_FLOW_MAPPING_STYLE  => 'flow',
};

my %scalar_style_to_string = (
    YAML_PLAIN_SCALAR_STYLE() => ':',
    YAML_SINGLE_QUOTED_SCALAR_STYLE() => "'",
    YAML_DOUBLE_QUOTED_SCALAR_STYLE() => '"',
    YAML_LITERAL_SCALAR_STYLE() => '|',
    YAML_FOLDED_SCALAR_STYLE() => '>',
);


sub event_to_test_suite {
    my ($event) = @_;
    my $ev = $event->{name};
        my $string;
        my $content = $event->{value};

        my $properties = '';
        $properties .= " &$event->{anchor}" if defined $event->{anchor};
        $properties .= " <$event->{tag}>" if defined $event->{tag};

        if ($ev eq 'document_start_event') {
            $string = "+DOC";
            $string .= " ---" unless $event->{implicit};
        }
        elsif ($ev eq 'document_end_event') {
            $string = "-DOC";
            $string .= " ..." unless $event->{implicit};
        }
        elsif ($ev eq 'stream_start_event') {
            $string = "+STR";
        }
        elsif ($ev eq 'stream_end_event') {
            $string = "-STR";
        }
        elsif ($ev eq 'mapping_start_event') {
            $string = "+MAP";
            $string .= $properties;
            if (0) {
                # doesn't match yaml-test-suite format
                if ($event->{style} and $event->{style} eq YAML_FLOW_MAPPING_STYLE) {
                    $string .= " {}";
                }
            }
        }
        elsif ($ev eq 'sequence_start_event') {
            $string = "+SEQ";
            $string .= $properties;
            if (0) {
                # doesn't match yaml-test-suite format
                if ($event->{style} and $event->{style} eq YAML_FLOW_SEQUENCE_STYLE) {
                    $string .= " []";
                }
            }
        }
        elsif ($ev eq 'mapping_end_event') {
            $string = "-MAP";
        }
        elsif ($ev eq 'sequence_end_event') {
            $string = "-SEQ";
        }
        elsif ($ev eq 'scalar_event') {
            $string = '=VAL';
            $string .= $properties;
            if (defined $content) {
                $content =~ s/\\/\\\\/g;
                $content =~ s/\t/\\t/g;
                $content =~ s/\r/\\r/g;
                $content =~ s/\n/\\n/g;
                $content =~ s/[\b]/\\b/g;
            }
            else {
                $content = '';
            }
            $string .= ' '
                . $scalar_style_to_string{ $event->{style} }
                . $content;
        }
        elsif ($ev eq 'alias_event') {
            $string = "=ALI *$content";
        }
        return $string;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Common - Constants and common functions

=head1 SYNOPSIS

    use YAML::PP::Common qw/
        YAML_ANY_SCALAR_STYLE YAML_PLAIN_SCALAR_STYLE
        YAML_SINGLE_QUOTED_SCALAR_STYLE YAML_DOUBLE_QUOTED_SCALAR_STYLE
        YAML_LITERAL_SCALAR_STYLE YAML_FOLDED_SCALAR_STYLE
        YAML_QUOTED_SCALAR_STYLE
    /;

=head1 DESCRIPTION

=head1 FUNCTONS

=over

=item event_to_test_suite

    my $string = YAML::PP::Common::event_to_test_suite($event_prom_parser);

For examples of the returned format look into this distributions's directory
C<yaml-test-suite> which is a copy of
L<https://github.com/yaml/yaml-test-suite>.

=back

