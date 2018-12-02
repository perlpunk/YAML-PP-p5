use strict;
use warnings;
package YAML::PP::Common;

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
                if ($event->{style} and $event->{style} eq 'flow') {
                    $string .= " {}";
                }
            }
        }
        elsif ($ev eq 'sequence_start_event') {
            $string = "+SEQ";
            $string .= $properties;
            if (0) {
                # doesn't match yaml-test-suite format
                if ($event->{style} and $event->{style} eq 'flow') {
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
            $string .= ' ' . $event->{style} . $content;
        }
        elsif ($ev eq 'alias_event') {
            $string = "=ALI *$content";
        }
        return $string;
}

1;
