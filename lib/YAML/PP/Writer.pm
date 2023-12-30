# ABSTRACT: Writer class for YAML::PP representing output data
use strict;
use warnings;
package YAML::PP::Writer;
use Encode;

our $VERSION = '0.000'; # VERSION

use Devel::Peek;
sub output {
    my ($self) = @_;
    warn __PACKAGE__.':'.__LINE__.": !!!!!!!!!!!!! $self->{utf8_in} <-> $self->{utf8_out}\n";
    my $output = $self->{output};
    Dump $output;
    return $output if $self->{coded};
    if ($self->{utf8_in} and ! $self->{utf8_out}) {
        warn __PACKAGE__.':'.__LINE__.": !!!!!!!!! DECODE $output\n";
        $output = decode 'UTF-8', $output, Encode::FB_CROAK;
    }
    elsif (not $self->{utf8_in} and $self->{utf8_out}) {
        warn __PACKAGE__.':'.__LINE__.": !!!!!!!!! ENCODE $output\n";
        $output = encode 'UTF-8', $output, Encode::FB_CROAK;
    }
    $self->{output} = $output;
    $self->{coded} = 1;
    return $output
}
sub set_output { $_[0]->{output} = $_[1] }

sub new {
    my ($class, %args) = @_;
    my $utf8_in = delete $args{utf8_in};
    my $utf8_out = delete $args{utf8_out};
    $utf8_in = 0 unless defined $utf8_in;
    $utf8_out = 0 unless defined $utf8_out;
    my $output = delete $args{output};
    $output = '' unless defined $output;
    return bless {
        utf8_in => $utf8_in,
        utf8_out => $utf8_out,
        output => $output,
    }, $class;
}

sub write {
    my ($self, $line) = @_;
    $self->{output} .= $line;
}

sub init {
    $_[0]->set_output('');
    $_[0]->{coded} = 0;
}

sub finish {
    my ($self) = @_;
    $_[0]->set_output(undef);
    $_[0]->{coded} = 0;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Writer - Write YAML output

=head1 SYNOPSIS

    my $writer = YAML::PP::Writer->new;

=head1 DESCRIPTION

The L<YAML::PP::Emitter> sends its output to the writer.

You can use your own writer. if you want to send the YAML output to
somewhere else. See t/44.writer.t for an example.

=head1 METHODS

=over

=item new

    my $writer = YAML::PP::Writer->new;

Constructor.

=item write

    $writer->write('- ');

=item init

    $writer->init;

Initialize

=item finish

    $writer->finish;

Gets called when the output ends.

=item output, set_output

Getter/setter for the YAML output

=back

=cut
