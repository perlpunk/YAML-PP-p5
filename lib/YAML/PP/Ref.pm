package YAML::PP::Ref;
use strict;
use warnings;

use Scalar::Util qw/ openhandle /;
use YAML::Parser;

use base 'YAML::PP::Parser';

sub parse {
    my ($self) = @_;
    my $reader = $self->reader;
    my $string;
    if ($reader->can('open_handle')) {
        if (openhandle($reader->input)) {
            $string = do { local $/; $reader->open_handle->read };
        }
        else {
            open my $fh, '<:encoding(UTF-8)', $reader->input;
            $string = do { local $/; <$fh> };
            close $fh;
        }
    }
    else {
        $string = $reader->read;
    }
    my $co = $self->receiver;

    my $cb = sub {
        my ($info) = @_;
        $info->{event} .= '_event';
        my $event = $info->{event};
        return $co->$event($info);
    };
    my $refrec = PerlYamlReferenceParserReceiver->new(
        callback => $cb,
    );
    my $p = YAML::Parser->new(receiver => $refrec);
    $p->parse($string);
}

1;
