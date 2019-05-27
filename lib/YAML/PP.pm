# ABSTRACT: YAML Framework
use strict;
use warnings;
package YAML::PP;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Schema;
use YAML::PP::Schema::JSON;
use YAML::PP::Loader;
use YAML::PP::Dumper;
use Scalar::Util qw/ blessed /;

use base 'Exporter';
our @EXPORT_OK = qw/ Load LoadFile Dump DumpFile /;

sub new {
    my ($class, %args) = @_;

    my $bool = delete $args{boolean};
    $bool = 'perl' unless defined $bool;
    my $schemas = delete $args{schema} || ['JSON'];
    my $cyclic_refs = delete $args{cyclic_refs} || 'allow';
    my $indent = delete $args{indent};
    my $writer = delete $args{writer};
    my $header = delete $args{header};
    my $footer = delete $args{footer};
    my $parser = delete $args{parser};
    my $emitter = delete $args{emitter} || {
        indent => $indent,
        writer => $writer,
    };

    my $schema;
    if (blessed($schemas) and $schemas->isa('YAML::PP::Schema')) {
        $schema = $schemas;
    }
    else {
        $schema = YAML::PP::Schema->new(
            boolean => $bool,
        );
        $schema->load_subschemas(@$schemas);
    }

    my $loader = YAML::PP::Loader->new(
        schema => $schema,
        cyclic_refs => $cyclic_refs,
        parser => $parser,
    );
    my $dumper = YAML::PP::Dumper->new(
        schema => $schema,
        emitter => $emitter,
        header => $header,
        footer => $footer,
    );

    my $self = bless {
        schema => $schema,
        loader => $loader,
        dumper => $dumper,
    }, $class;
    return $self;
}

sub loader {
    if (@_ > 1) {
        $_[0]->{loader} = $_[1]
    }
    return $_[0]->{loader};
}

sub dumper {
    if (@_ > 1) {
        $_[0]->{dumper} = $_[1]
    }
    return $_[0]->{dumper};
}

sub schema {
    if (@_ > 1) { $_[0]->{schema} = $_[1] }
    return $_[0]->{schema};
}

sub default_schema {
    my ($self, %args) = @_;
    my $schema = YAML::PP::Schema->new(
        boolean => $args{boolean},
    );
    $schema->load_subschemas(qw/ JSON /);
    return $schema;
}

sub load_string {
    my ($self, $yaml) = @_;
    return $self->loader->load_string($yaml);
}

sub load_file {
    my ($self, $file) = @_;
    return $self->loader->load_file($file);
}

sub dump {
    my ($self, @data) = @_;
    return $self->dumper->dump(@data);
}

sub dump_string {
    my ($self, @data) = @_;
    return $self->dumper->dump_string(@data);
}

sub dump_file {
    my ($self, $file, @data) = @_;
    return $self->dumper->dump_file($file, @data);
}

# legagy interface
sub Load {
    my ($yaml) = @_;
    YAML::PP->new->load_string($yaml);
}

sub LoadFile {
    my ($file) = @_;
    YAML::PP->new->load_file($file);
}

sub Dump {
    my (@data) = @_;
    YAML::PP->new->dump_string(@data);
}

sub DumpFile {
    my ($file, @data) = @_;
    YAML::PP->new->dump_file($file, @data);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP - YAML 1.2 processor

=head1 SYNOPSIS

WARNING: This is not yet stable.

Here are a few examples of the basic load and dump methods:

    use YAML::PP;
    my $ypp = YAML::PP->new;
    my $yaml = <<'EOM';
    --- # Document one is a mapping
    name: Tina
    age: 29
    favourite language: Perl

    --- # Document two is a sequence
    - plain string
    - 'in single quotes'
    - "in double quotes we have escapes! like \t and \n"
    - | # a literal block scalar
      line1
      line2
    - > # a folded block scalar
      this is all one
      single line because the
      linebreaks will be folded
    EOM

    my @documents = $ypp->load_string($yaml);
    my @documents = $ypp->load_file($filename);

    my $yaml = $ypp->dump_string($data1, $data2);
    $ypp->dump_file($filename, $data1, $data2);

    # The loader offers JSON::PP::Boolean, boolean.pm or
    # perl 1/'' (currently default) for booleans
    my $ypp = YAML::PP->new(boolean => 'JSON::PP');
    my $ypp = YAML::PP->new(boolean => 'boolean');
    my $ypp = YAML::PP->new(boolean => 'perl');

    # Legacy interface
    use YAML::PP qw/ Load Dump LoadFile DumpFile /;
    my @documents = Load($yaml);
    my @documents = LoadFile($filename);
    my @documents = LoadFile($filehandle);
    my $yaml = = Dump(@documents);
    DumpFile($filename, @documents);
    DumpFile($filenhandle @documents);

    my $ypp = YAML::PP->new(schema => [qw/ JSON Perl /]);
    my $yaml = $yp->dump_string($data_with_perl_objects);


Some utility scripts:

    # Load YAML into a data structure and dump with Data::Dumper
    yamlpp5-load < file.yaml

    # Load and Dump
    yamlpp5-load-dump < file.yaml

    # Print the events from the parser in yaml-test-suite format
    yamlpp5-events < file.yaml

    # Create ANSI colored YAML
    yamlpp5-highlight < file.yaml

    # Parse and emit events directly without loading
    yamlpp5-parse-emit < file.yaml


=head1 DESCRIPTION

This is Yet Another YAML Framework. For why this project was started, see
L<"WHY">.

It aims to support C<YAML 1.2> and C<YAML 1.1>. See L<http://yaml.org/>.

You can check out all current parse and load results from the
yaml-test-suite here:
L<https://perlpunk.github.io/YAML-PP-p5/test-suite.html>

YAML is a serialization language. The YAML input is called "YAML Stream".
A stream consists of one or more "Documents", seperated by a line with a
document start marker C<--->. A document optionally ends with the document
end marker C<...>.

This allows to process continuous streams additionally to a fixed input
file or string.

The YAML::PP frontend will currently load all documents, and return only
the last if called with scalar context.

The YAML backend is implemented in a modular way that allows to add
custom handling of YAML tags, perl objects and data types. The inner API
is not yet stable. Suggestions welcome.

=head1 PLUGINS

You can alter the behaviour of YAML::PP by using the following schema
classes:

=over

=item L<YAML::PP::Schema::Failsafe>

One of the three YAML 1.2 official schemas

=item L<YAML::PP::Schema::JSON>

One of the three YAML 1.2 official schemas. Default

=item L<YAML::PP::Schema::Core>

One of the three YAML 1.2 official schemas

=item L<YAML::PP::Schema::YAML1_1>

Schema implementing the most common YAML 1.1 types

=item L<YAML::PP::Schema::Perl>

Serializing Perl objects and types

=item L<YAML::PP::Schema::Binary>

Serializing binary data

=item L<YAML::PP::Schema::Tie::IxHash>

In progress. Keeping hash key order.

=item L<YAML::PP::Schema::Merge>

YAML 1.1 merge keys for mappings

=back

=head1 IMPLEMENTATION

The process of loading and dumping is split into the following steps:

    Load:

    YAML Stream        Tokens        Event List        Data Structure
              --------->    --------->        --------->
                lex           parse           construct


    Dump:

    Data Structure       Event List        YAML Stream
                --------->        --------->
                represent           emit


You can dump basic perl types like hashes, arrays, scalars (strings, numbers).
For dumping blessed objects and things like coderefs have a look at
L<YAML::PP::Perl>/L<YAML::PP::Schema::Perl>.

For keeping your ordered L<Tie::IxHash> hashes, try out
L<YAML::PP::Schema::Tie::IxHash>.

=over

=item L<YAML::PP::Lexer>

The Lexer is reading the YAML stream into tokens. This makes it possible
to generate syntax highlighted YAML output.

Note that the API to retrieve the tokens will change.

=item L<YAML::PP::Parser>

The Parser retrieves the tokens from the Lexer. The main YAML content is then
parsed with the Grammar.

=item L<YAML::PP::Grammar>

=item L<YAML::PP::Constructor>

The Constructor creates a data structure from the Parser events.

=item L<YAML::PP::Loader>

The Loader combines the constructor and parser.

=item L<YAML::PP::Dumper>

The Dumper will delegate to the Representer

=item L<YAML::PP::Representer>

The Representer will create Emitter events from the given data structure.

=item L<YAML::PP::Emitter>

The Emitter creates a YAML stream.

=back

=head2 YAML::PP::Parser

Still TODO:

=over 4

=item Flow Style

Flow style is partially implemented.

Not yet working: Implicit flow collection keys, implicit keys in
flow sequences, content directly after the colon, empty nodes, explicit
keys

=item Supported Characters

If you have valid YAML that's not parsed, or the other way round, please
create an issue.

=item Line and Column Numbers

You will see line and column numbers in the error message. The column numbers
might still be wrong in some cases.

=item Error Messages

The error messages need to be improved.

=item Unicode Surrogate Pairs

Currently loaded as single characters without validating

=item Possibly more

=back

=head2 YAML::PP::Constructor

The Constructor now supports all three YAML 1.2 Schemas, Failsafe, JSON and JSON.
Additionally you can choose the schema for YAML 1.1 as C<YAML1_1>.

Too see what strings are resolved as booleans, numbers, null etc. look at
C<t/31.schema.t>.

You can choose the Schema, however, the API for that is not yet fixed.
Currently it looks like this:

    my $ypp = YAML::PP->new(schema => ['Core']); # default is 'JSON'

The Tags C<!!seq> and C<!!map> are still ignored for now.

It supports:

=over 4

=item Handling of Anchors/Aliases

Like in modules like L<YAML>, the Constructor will use references for mappings and
sequences, but obviously not for scalars.

=item Boolean Handling

You can choose between C<'perl'> (1/'', currently default), C<'JSON::PP'> and
C<'boolean'>.pm for handling boolean types.  That allows you to dump the data
structure with one of the JSON modules without losing information about
booleans.

=item Numbers

Numbers are created as real numbers instead of strings, so that they are
dumped correctly by modules like L<JSON::PP> or L<JSON::XS>, for example.

See L<"NUMBERS"> for an example.

=back

TODO:

=over 4

=item Complex Keys

Mapping Keys in YAML can be more than just scalars. Of course, you can't load
that into a native perl structure. The Constructor will stringify those keys
with L<Data::Dumper> instead of just returning something like
C<HASH(0x55dc1b5d0178)>.

Example:

    use YAML::PP;
    use JSON::PP;
    my $ypp = YAML::PP->new;
    my $coder = JSON::PP->new->ascii->pretty->allow_nonref->canonical;
    my $yaml = <<'EOM';
    complex:
        ?
            ?
                a: 1
                c: 2
            : 23
        : 42
    EOM
    my $data = $yppl->load_string($yaml);
    say $coder->encode($data);
    __END__
    {
       "complex" : {
          "{'{a => 1,c => 2}' => 23}" : 42
       }
    }

=item Parse Tree

I would like to generate a complete parse tree, that allows you to manipulate
the data structure and also dump it, including all whitespaces and comments.
The spec says that this is throwaway content, but I read that many people
wish to be able to keep the comments.

=back

=head2 YAML::PP::Dumper, YAML::PP::Emitter

The Dumper should be able to dump strings correctly, adding quotes
whenever a plain scalar would look like a special string, like C<true>,
or when it contains or starts with characters that are not allowed.

Most strings will be dumped as plain scalars without quotes. If they
contain special characters or have a special meaning, they will be dumped
with single quotes. If they contain control characters, including <"\n">,
they will be dumped with double quotes.

It will recognize JSON::PP::Boolean and boolean.pm objects and dump them
correctly.

TODO: Correctly recognize numbers which also have a string flag, like:

    my $int = 23;
    say "int: $int"; # $int will now also have a PV flag

The layout is like libyaml output:

    key:
    - a
    - b
    - c
    ---
    - key1: 1
      key2: 2
      key3: 3
    ---
    - - a1
      - a2
    - - b1
      - b2

=head1 METHODS

=over

=item new

    my $ypp = YAML::PP->new;
    # load booleans via boolean.pm
    my $ypp = YAML::PP->new( boolean => 'boolean' );
    # load booleans via JSON::PP::true/false
    my $ypp = YAML::PP->new( boolean => 'JSON::PP' );
    
    # use YAML 1.2 Failsafe Schema
    my $ypp = YAML::PP->new( schema => ['Failsafe'] );
    # use YAML 1.2 JSON Schema
    my $ypp = YAML::PP->new( schema => ['JSON'] );
    # use YAML 1.2 Core Schema
    my $ypp = YAML::PP->new( schema => ['Core'] );
    
    # Die when detecting cyclic references
    my $ypp = YAML::PP->new( cyclic_refs => 'fatal' );
    # Other values:
    # warn   - Just warn about them and replace with undef
    # ignore - replace with undef
    # allow  - Default
    
    my $ypp = YAML::PP->new(
        boolean => 'JSON::PP',
        schema => ['JSON'],
        cyclic_refs => 'fatal',
        indent => 4, # use 4 spaces for dumping indentation
        header => 1, # default 1; print document header ---
        footer => 1, # default 0; print document footer ...
    );

=item load_string

    my $doc = $ypp->load_string("foo: bar");
    my @docs = $ypp->load_string("foo: bar\n---\n- a");

Input should be utf-8 decoded.

=item load_file

    my $doc = $ypp->load_file("file.yaml");
    my @docs = $ypp->load_file("file.yaml");

UTF-8 decoding will be done automatically

=item dump_string

    my $yaml = $ypp->dump_string($doc);
    my $yaml = $ypp->dump_string($doc1, $doc2);
    my $yaml = $ypp->dump_string(@docs);

Input data should be UTF-8 decoded. If not, it will be upgraded with
C<utf8::upgrade>.

Output will be UTF-8 decoded.

=item dump_file

    $ypp->dump_file("file.yaml", $doc);
    $ypp->dump_file("file.yaml", $doc1, $doc2);
    $ypp->dump_file("file.yaml", @docs);

Input data should be UTF-8 decoded. If not, it will be upgraded with
C<utf8::upgrade>.

File will be written UTF-8 encoded.

=item dump

This will dump to a predefined writer. By default it will just use the
L<YAML::PP::Writer> and output a string.

    my $writer = MyWriter->new(\my $output);
    my $yp = YAML::PP->new(
        writer => $writer,
    );
    $yp->dump($data);

=item loader

Returns or sets the loader object, by default L<YAML::PP::Loader>

=item dumper

Returns or sets the dumper object, by default L<YAML::PP::Dumper>

=item schema

Returns or sets the schema object

=item default_schema

Creates and returns the default schema

=back

=head1 FUNCTIONS

The functions C<Load>, C<LoadFile>, C<Dump> and C<DumpFile> are provided
as a drop-in replacement for other existing YAML processors.
No function is exported by default.

=over

=item Load

    use YAML::PP qw/ Load /;
    my $doc = Load($yaml);
    my @docs = Load($yaml);

=item LoadFile

    use YAML::PP qw/ LoadFile /;
    my $doc = LoadFile($file);
    my @docs = LoadFile($file);
    my @docs = LoadFile($filehandle);

=item Dump

    use YAML::PP qw/ Dump /;
    my $yaml = Dump($doc);
    my $yaml = Dump(@docs);

=item DumpFile

    use YAML::PP qw/ DumpFile /;
    DumpFile($file, $doc);
    DumpFile($file, @docs);
    DumpFile($filehandle, @docs);

=back

=head1 NUMBERS

Compare the output of the following YAML Loaders and JSON::PP dump:

    use JSON::PP;
    use Devel::Peek;

    use YAML::XS ();
    use YAML ();
        $YAML::Numify = 1; # since version 1.23
    use YAML::Syck ();
        $YAML::Syck::ImplicitTyping = 1;
    use YAML::Tiny ();
    use YAML::PP;

    my $yaml = "foo: 23";

    my $d1 = YAML::XS::Load($yaml);
    my $d2 = YAML::Load($yaml);
    my $d3 = YAML::Syck::Load($yaml);
    my $d4 = YAML::Tiny->read_string($yaml)->[0];
    my $d5 = YAML::PP->new->load_string($yaml);

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

    SV = PVIV(0x55bbaff2bae0) at 0x55bbaff26518
      REFCNT = 1
      FLAGS = (IOK,POK,pIOK,pPOK)
      IV = 23
      PV = 0x55bbb06e67a0 "23"\0
      CUR = 2
      LEN = 10
    SV = PVMG(0x55bbb08959b0) at 0x55bbb08fc6e8
      REFCNT = 1
      FLAGS = (IOK,pIOK)
      IV = 23
      NV = 0
      PV = 0
    SV = IV(0x55bbaffcb3b0) at 0x55bbaffcb3c0
      REFCNT = 1
      FLAGS = (IOK,pIOK)
      IV = 23
    SV = PVMG(0x55bbaff2f1f0) at 0x55bbb08fc8c8
      REFCNT = 1
      FLAGS = (POK,pPOK,UTF8)
      IV = 0
      NV = 0
      PV = 0x55bbb0909d00 "23"\0 [UTF8 "23"]
      CUR = 2
      LEN = 10
    SV = PVMG(0x55bbaff2f6d0) at 0x55bbb08b2c10
      REFCNT = 1
      FLAGS = (IOK,pIOK)
      IV = 23
      NV = 0
      PV = 0

    {"foo":"23"}
    {"foo":23}
    {"foo":23}
    {"foo":"23"}
    {"foo":23}



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

It contains about 230 test cases and expected parsing events and more.
There will be more tests coming. This test suite allows to write parsers
without turning the examples from the Specification into tests yourself.
Also the examples aren't completely covering all cases - the test suite
aims to do that.

The suite contains .tml files, and in a seperate 'data' branch you will
find the content in seperate files, if you can't or don't want to
use TestML.

Thanks also to Felix Krause, who is writing a YAML parser in Nim.
He turned all the spec examples into test cases.

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

As of this writing, the test matrix only contains valid test cases.
Invalid ones will be added.

=head1 CONTRIBUTORS

=over

=item Ingy döt Net

Ingy is one of the creators of YAML. In 2016 he started the YAML Test Suite
and the YAML Editor. He also made useful suggestions on the class
hierarchy of YAML::PP.

=item Felix "flyx" Krause

Felix answered countless questions about the YAML Specification.

=back

=head1 SEE ALSO

=over

=item L<YAML>

=item L<YAML::XS>

=item L<YAML::Syck>

=item L<YAML::Tiny>

=back

=head1 SPONSORS

The Perl Foundation L<https://www.perlfoundation.org/> sponsored this project
(and the YAML Test Suite) with a grant of 2500 USD in 2017-2018.

=head1 COPYRIGHT AND LICENSE

Copyright 2018 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut
