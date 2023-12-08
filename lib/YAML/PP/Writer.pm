# ABSTRACT: Writer class for YAML::PP representing output data
use strict;
use warnings;
package YAML::PP::Writer;
use Encode;

our $VERSION = '0.000'; # VERSION

sub output { return $_[0]->{output} }
sub set_output { $_[0]->{output} = $_[1] }

sub new {
    my ($class, %args) = @_;
    my $utf8 = delete $args{utf8};
    $utf8 = 0 unless defined $utf8;
    my $output = delete $args{output};
    $output = '' unless defined $output;
    return bless {
        utf8 => $utf8,
        output => $output,
    }, $class;
}

sub write {
    my ($self, $line) = @_;
    if ($self->{utf8}) {
        $line = encode 'UTF-8', $line, Encode::FB_CROAK;
    }
    $self->{output} .= $line;
}

sub init {
    $_[0]->set_output('');
}

sub finish {
    my ($self) = @_;
    $_[0]->set_output(undef);
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
