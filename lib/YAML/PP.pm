# ABSTRACT: YAML Parser and Loader
use strict;
use warnings;
package YAML::PP;

our $VERSION = '0.000'; # VERSION

sub new {
    my ($class, %args) = @_;
    my $self = bless {
    }, $class;
    return $self;
}

sub loader { return $_[0]->{loader} }

sub Load {
    require YAML::PP::Loader;
    my ($self, $yaml) = @_;
    $self->{loader} = YAML::PP::Loader->new;
    return $self->loader->Load($yaml);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP - YAML Parser and Loader

=head1 SYNOPSIS

WARNING: This is highly experimental.

Here are a few examples of what you can do right now:

    # Load YAML into a very simple data structure
    yaml-pp-p5-load < file.yaml

    # The loader offers JSON::PP, boolean.pm or pureperl 1/0 (default)
    # for booleans
    my $ypp = YAML::PP::Loader->new(boolean => 'JSON::PP');
    my ($data1, $data2) = $ypp->Load($yaml);

    # Print the events from the parser in yaml-test-suite format
    yaml-pp-p5-events < file.yaml

=head1 DESCRIPTION

This is Yet Another YAML Parser. For why this project was started, see
L<"WHY">.

This project contains a Parser L<YAML::PP::Parser> and a Loader
L<YAML::PP::Loader>.

=head2 YAML::PP::Parser

The parser aims to parse C<YAML 1.2>.

Still TODO:

=over 4

=item Flow Style

Flow style is not implemented yet, you will get an appropriate error message.

=item Supported Characters

The regexes are not complete. It will not accept characters that should be
valid, and it will accept characters that should be invalid.

=item Line Numbers

The parser currently doesn't keep track of the line numbers, so the error
messages might not be very useful yet

=item Error Messages

The error messages in general aren't often very informative

=item Lexer

I would like to support a lexer that can be used for highlighting.

=item Possibly more

=back

=head2 YAML::PP::Loader

The loader is very simple so far.

It supports:

=over 4

=item Simple handling of Anchors/Aliases

Like in modules like L<YAML>, the Loader will use references for mappings and
sequences, but obviously not for scalars.

=item Boolean Handling

You can choose between C<'perl'> (default), C<'JSON::PP'> and C<'boolean'>.pm
for handling boolean types.
That allows you to dump the data structure with one of the JSON modules
without losing information about booleans.

I also would like to add the possibility to specify a callback for your
own boolean handling.

=item Numbers

Numbers are created as real numbers instead of strings, so that they are
dumped correctly by modules like L<JSON::XS>, for example.

See L<"NUMBERS"> for an example.

=back

TODO:

=over 4

=item Complex Keys

Mapping Keys in YAML can be more than just scalars. Of course, you can't load
that into a native perl structure. The Loader will stringify those keys
with L<Data::Dumper>.
I would like to add a possibility to specify a method for stringification.

Example:

    use YAML::PP::Loader;
    use JSON::XS;
    my $yppl = YAML::PP::Loader->new;
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref->canonical;
    my $yaml = <<'EOM';
    complex:
        ?
            ?
                a: 1
                c: 2
            : 23
        : 42
    EOM
    my $data = $yppl->Load($yaml);
    say $coder->encode($data);
    __END__
    {
       "complex" : {
          "{'{a => 1,c => 2}' => 23}" : 42
       }
    }

=item Tags

Tags are completely ignored.

=item Parse Tree

I would like to generate a complete parse tree, that allows you to manipulate
the data structure and also dump it, including all whitespaces and comments.
The spec says that this is throwaway content, but I read that many people
wish to be able to keep the comments.

=back

=head1 NUMBERS

Compare the output of the following YAML Loaders and JSON::XS dump:


    use JSON::XS;
    use Devel::Peek;

    use YAML::XS ();
    use YAML ();
        $YAML::Numify = 1; # since version 1.23
    use YAML::Syck ();
        $YAML::Syck::ImplicitTyping = 1;
    use YAML::Tiny ();
    use YAML::PP::Loader;

    my $yaml = "foo: 23";

    my $d1 = YAML::XS::Load($yaml);
    my $d2 = YAML::Load($yaml);
    my $d3 = YAML::Syck::Load($yaml);
    my $d4 = YAML::Tiny->read_string($yaml);
    my $d5 = YAML::PP::Loader->new->Load($yaml);

    Dump $d1->{foo};
    Dump $d2->{foo};
    Dump $d3->{foo};
    Dump $d4->{foo};
    Dump $d5->{foo};

    say encode_json($d1);
    say encode_json($d2);
    say encode_json($d3);
    say encode_json($d4);
    say encode_json($d5);

    SV = PVIV(0x564f09465c00) at 0x564f09460780
      REFCNT = 1
      FLAGS = (IOK,POK,pIOK,pPOK)
      IV = 23
      PV = 0x564f0945a600 "23"\0
      CUR = 2
      LEN = 10

    SV = PVMG(0x5654d491dd80) at 0x5654d4aca4c8
      REFCNT = 1
      FLAGS = (IOK,pIOK)
      IV = 23
      NV = 0
      PV = 0

    SV = IV(0x564f6fab37d0) at 0x564f6fab37e0
      REFCNT = 1
      FLAGS = (IOK,pIOK)
      IV = 23

    SV = PVMG(0x5640b45a42a0) at 0x5640b4594250
      REFCNT = 1
      FLAGS = (POK,pPOK,UTF8)
      IV = 0
      NV = 0
      PV = 0x5640b45a21f0 "23"\0 [UTF8 "23"]
      CUR = 2
      LEN = 10

    SV = PVMG(0x564f09b5cbc0) at 0x564f09d473c0
      REFCNT = 1
      FLAGS = (IOK,pIOK)
      IV = 23
      NV = 0
      PV = 0

    {"foo":"23"}
    {"foo":23}
    {"foo":23}
    {"foo":23}
    {"foo":"23"}


=head1 WHY

All the available parsers and loaders for Perl are behaving differently,
and more important, aren't conforming to the spec. L<YAML::XS> is
doing pretty well, but C<libyaml> only handles YAML 1.1 and diverges
a bit from the spec. The pure perl loaders lack support for a number of
features.

I was going over L<YAML>.pm issues end of 216, integrating old patches
from rt.cpan.org and creating some pull requests myself. I realized
that it would be difficult to patch YAML.pm to parse YAML 1.1 or even 1.2,
and it would also break existing usages relying on the current behaviour.


In 2016 Ingy döt Net initiated two really cool projects:

=over 4

=item L<"YAML TEST SUITE">

=item L<"YAML EDITOR">

=back

These projects are a big help for any developer. So I got the idea
to write my own parser and started on New Year's Day 2017.
Without the test suite and the editor I would have never started this.

I also started another YAML Test project which allows to get a quick
overview of which frameworks support which YAML features:

=over 4

=item L<"YAML TEST MATRIX">

=back

=head2 YAML TEST SUITE

L<https://github.com/yaml/yaml-test-suite>

It contains about 160 test cases and expected parsing events and more.
There will be more tests coming. This test suite allows to write parsers
without turning the examples from the Specification into tests yourself.
Also the examples aren't completely covering all cases - the test suite
aims to do that.

The suite contains .tml files, and in a seperate 'data' branch you will
find the content in seperate files, if you can't or don't want to
use TestML.

Thanks also to Felix Krause, who is writing a YAML parser in Nim.
He turned all the spec examples into test cases.

As of this writing, the test suite only contains valid examples.
Invalid ones are currently added.

=head2 YAML EDITOR

This is a tool to play around with several YAML parsers and loaders in vim.

L<https://github.com/yaml/yaml-editor>

The project contains the code to build the frameworks (16 as of this
writing) and put it into one big Docker image.

It also contains the yaml-editor itself, which will start a vim in the docker
container. It uses a lot of funky vimscript that makes playing with it easy
and useful. You can choose which frameworks you want to test and see the
output in a grid of vim windows.

Especially when writing a parser it is extremely helpful to have all
the test cases and be able to play around with your own examples to see
how they are handled.

=head2 YAML TEST MATRIX

I was curious to see how the different frameworks handle the test cases,
so, using the test suite and the docker image, I wrote some code that runs
the tests, manipulates the output to compare it with the expected output,
and created a matrix view.

L<https://github.com/perlpunk/yaml-test-matrix>

You can find the latest build at L<http://matrix.yaml.io>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut
