# ABSTRACT: YAML Framework
use strict;
use warnings;
package YAML::PP;

our $VERSION = '0.000'; # VERSION

use base 'Exporter';
our @EXPORT_OK = qw/ Load LoadFile Dump DumpFile /;

sub new {
    my ($class, %args) = @_;

    my $bool = delete $args{boolean} // 'perl';
    my $schemas = delete $args{schema} || ['Core'];

    my $schema = YAML::PP::Schema->new(
        boolean => $bool,
    );
    $schema->load_subschemas(@$schemas);

    my $self = bless {
        boolean => $bool,
        schema => $schema,
    }, $class;
    return $self;
}

sub boolean { return $_[0]->{boolean} }

sub loader {
    if (@_ > 1) {
        $_[0]->{loader} = $_[1]
    }
    else {
        return $_[0]->{loader}
    }
}

sub dumper {
    if (@_ > 1) {
        $_[0]->{dumper} = $_[1]
    }
    else {
        return $_[0]->{dumper}
    }
}

sub schema {
    if (@_ > 1) { $_[0]->{schema} = $_[1] }
    else { return $_[0]->{schema} }
}

sub default_schema {
    my ($self, %args) = @_;
    my $schema = YAML::PP::Schema->new(
        boolean => $args{boolean},
    );
    $schema->load_subschemas(qw/ Core /);
    return $schema;
}

sub load_string {
    my ($self, $yaml) = @_;
    my $loader = $self->loader;
    unless ($loader) {
        require YAML::PP::Loader;
        $loader = YAML::PP::Loader->new(
            boolean => $self->boolean,
            schema => $self->schema,
        );
        $self->loader($loader);
    }
    return $loader->load_string($yaml);
}

sub load_file {
    my ($self, $file) = @_;
    my $loader = $self->loader;
    unless ($loader) {
        require YAML::PP::Loader;
        $loader = YAML::PP::Loader->new(
            boolean => $self->boolean,
            schema => $self->schema,
        );
        $self->loader($loader);
    }
    return $loader->load_file($file);
}

sub dump_string {
    my ($self, @data) = @_;
    my $dumper = $self->dumper;
    unless ($dumper) {
        require YAML::PP::Dumper;
        $dumper = YAML::PP::Dumper->new;
        $self->dumper($dumper);
    }
    return $dumper->dump_string(@data);
}

sub dump_file {
    my ($self, $file, @data) = @_;
    my $dumper = $self->dumper;
    unless ($dumper) {
        require YAML::PP::Dumper;
        $dumper = YAML::PP::Dumper->new;
        $self->dumper($dumper);
    }
    return $dumper->dump_file($file, @data);
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

package YAML::PP::Schema;

sub new {
    my ($class, %args) = @_;

    my $bool = delete $args{boolean} // 'perl';
    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }
    my $true;
    my $false;
    if ($bool eq 'JSON::PP') {
        require JSON::PP;
        $true = \&bool_jsonpp_true;
        $false = \&bool_jsonpp_false;
    }
    elsif ($bool eq 'boolean') {
        require boolean;
        $true = \&bool_booleanpm_true;
        $false = \&bool_booleanpm_false;
    }
    elsif ($bool eq 'perl') {
        $true = \&bool_perl_true;
        $false = \&bool_perl_false;
    }
    else {
        die "Invalid value for 'boolean': '$bool'. Allowed: ('perl', 'boolean', 'JSON::PP')";
    }

    my $self = bless {
        resolvers => $args{resolvers} || {},
        true => $true,
        false => $false,
    }, $class;
    return $self;
}

sub resolvers { return $_[0]->{resolvers} }
sub true { return $_[0]->{true} }
sub false { return $_[0]->{false} }

sub load_subschemas {
    my ($self, @schemas) = @_;
    for my $s (@schemas) {
        my $class = "YAML::PP::Schema::" . $s;
        my $tags = $class->register(
            schema => $self,
        );
    }
}

sub add_matcher {
    my ($self, $type, $match, $value) = @_;
    my $resolvers = $self->resolvers;
    my $res = $resolvers->{value} ||= {};
    if ($type eq 'equals') {
        unless (exists $res->{equals}->{ $match }) {
            $res->{equals}->{ $match } = $value;
        }
        return;
    }
    if ($type eq 'regex') {
        push @{ $res->{regex} }, [ $match => $value ];
        return;
    }
}

sub add_tag_resolver {
    my ($self, $tag, $type, $match, $value) = @_;
    my $resolvers = $self->resolvers;
    my $res = $resolvers->{tag}->{ $tag } ||= {};
    if ($type eq 'equals') {
        unless (exists $res->{equals}->{ $match }) {
            $res->{equals}->{ $match } = $value;
        }
        return;
    }
    if ($type eq 'regex') {
        push @{ $res->{regex} }, [ $match => $value ];
    }
}

sub load_scalar_tag {
    my ($self, $event) = @_;
    my $tag = $event->{tag};
    my $value = $event->{value} // '';
    my $resolvers = $self->resolvers;
    my $res = $resolvers->{tag}->{ $tag };

    if (my $equals = $res->{equals}) {
        if (exists $equals->{ $value }) {
            my $res = $equals->{ $value };
            if (ref $res eq 'CODE') {
                return $res->();
            }
            return $res;
        }
        die "Tag $tag ($value)";
    }
    if (my $regex = $res->{regex}) {
        for my $item (@$regex) {
            my ($re, $sub) = @$item;
            my @matches = $value =~ $re;
            if (@matches) {
                return $sub->(@matches);
            }
        }
        die "Tag $tag ($value)";
    }
#    die "Tag $tag ($value)";
    return $value;
}

sub load_scalar {
    my ($self, $style, $value) = @_;
    if ($style ne ':') {
        return $value;
    }
    my $resolvers = $self->resolvers;
    my $res = $resolvers->{value};
    $value //= '';

    if (my $equals = $res->{equals}) {
        if (exists $equals->{ $value }) {
            my $res = $equals->{ $value };
            if (ref $res eq 'CODE') {
                return $res->();
            }
            return $res;
        }
    }
    if (my $regex = $res->{regex}) {
        for my $item (@$regex) {
            my ($re, $sub) = @$item;
            my @matches = $value =~ $re;
            if (@matches) {
                return $sub->(@matches);
            }
        }
    }
    return $value;
}

sub bool_jsonpp_true { JSON::PP::true() }

sub bool_booleanpm_true { boolean::true() }

sub bool_perl_true { 1 }

sub bool_jsonpp_false { JSON::PP::false() }

sub bool_booleanpm_false { boolean::false() }

sub bool_perl_false { !1 }


package YAML::PP::Schema::Base;

sub register {
    return {};
}

package YAML::PP::Schema::Failsafe;

use base 'YAML::PP::Schema';

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};
    $schema->add_matcher( equals => '' => '' );
    return {
        tags => [
#            '<tag:yaml.org,2002:str>' => {
#                default => 1,
#            },
        ],
    };
}

package YAML::PP::Schema::JSON;
use base 'YAML::PP::Schema';

my $RE_INT = qr{^(-?(?:0|[1-9][0-9]*))$};
my $RE_FLOAT = qr{^(-?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)$};

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub _to_int { 0 + $_[0] }

# DaTa++ && shmem++
sub _to_float { unpack F => pack F => $_[0] }

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};
    $schema->add_matcher( equals => null => undef );
    $schema->add_matcher( equals => true => $schema->true );
    $schema->add_matcher( equals => false => $schema->false );
    $schema->add_matcher( regex => $RE_INT => \&_to_int );
    $schema->add_matcher( regex => $RE_FLOAT => \&_to_float );

    $schema->add_tag_resolver(
        'tag:yaml.org,2002:null' => equals => '' => undef
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:null' => equals => null => undef
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:bool' => equals => true => $schema->true
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:bool' => equals => false => $schema->false
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:int' => regex => $RE_INT => \&_to_int
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:float' => regex => $RE_FLOAT => \&_to_float
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:str' => regex => qr{^(.*)$} => sub { $_[0] }
    );
    return;
}

package YAML::PP::Schema::Core;
use base 'YAML::PP::Schema';

my $RE_INT_CORE = qr{^([+-]?(?:0|[1-9][0-9]*))$};
my $RE_FLOAT_CORE = qr{^([+-]?(?:\.[0-9]+|[0-9]+(?:\.[0-9]*)?)(?:[eE][+-]?[0-9]+)?)$};
my $RE_INT_OCTAL = qr{^0o([0-7]+)$};
my $RE_INT_HEX = qr{^0x([0-9a-fA-F]+)$};


sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub _from_oct { oct $_[0] }
sub _from_hex { hex $_[0] }

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};
    $schema->add_matcher( equals => '' => undef );
    $schema->add_matcher( equals => null => undef );
    $schema->add_matcher( equals => NULL => undef );
    $schema->add_matcher( equals => Null => undef );
    $schema->add_matcher( equals => '~' => undef );
    $schema->add_matcher( equals => true => $schema->true );
    $schema->add_matcher( equals => TRUE => $schema->true );
    $schema->add_matcher( equals => True => $schema->true );
    $schema->add_matcher( equals => false => $schema->false );
    $schema->add_matcher( equals => FALSE => $schema->false );
    $schema->add_matcher( equals => False => $schema->false );
    $schema->add_matcher( regex => $RE_INT_CORE => \&YAML::PP::Schema::JSON::_to_int );
    $schema->add_matcher( regex => $RE_INT_OCTAL => \&_from_oct );
    $schema->add_matcher( regex => $RE_INT_HEX => \&_from_hex );
    $schema->add_matcher( regex => $RE_FLOAT_CORE => \&YAML::PP::Schema::JSON::_to_float );

    $schema->add_tag_resolver(
        'tag:yaml.org,2002:null' => equals => '' => undef
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:null' => equals => null => undef
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:null' => equals => '~' => undef
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:null' => equals => Null => undef
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:null' => equals => NULL => undef
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:bool' => equals => true => $schema->true
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:bool' => equals => True => $schema->true
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:bool' => equals => TRUE => $schema->true
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:bool' => equals => false => $schema->false
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:bool' => equals => False => $schema->false
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:bool' => equals => FALSE => $schema->false
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:int' => regex => $RE_INT_CORE => \&YAML::PP::Schema::JSON::_to_int
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:int' => regex => $RE_INT_OCTAL => \&_from_oct
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:int' => regex => $RE_INT_HEX => \&_from_hex
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:float' => regex => $RE_FLOAT_CORE => \&YAML::PP::Schema::JSON::_to_float
    );
    $schema->add_tag_resolver(
        'tag:yaml.org,2002:str' => regex => qr{^(.*)$} => sub { $_[0] }
    );
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP - YAML 1.2 processor

=head1 SYNOPSIS

WARNING: This is highly experimental.

Here are a few examples of what you can do right now:

    use YAML::PP;
    my $ypp = YAML::PP->new;

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
    my $yaml = = Dump(@documents);
    DumpFile($filename, @documents);


Some utility scripts:

    # Load YAML into a data structure and dump with Data::Dumper
    yamlpp5-load < file.yaml

    # Load and Dump
    yamlpp5-load-dump < file.yaml

    # Print the events from the parser in yaml-test-suite format
    yamlpp5-events < file.yaml

    # Create ANSI colored YAML
    yamlpp5-highlight < file.yaml


=head1 DESCRIPTION

This is Yet Another YAML Framework. For why this project was started, see
L<"WHY">.

The parser aims to parse C<YAML 1.2>. See L<http://yaml.org/>.

You can check out all current parse and load results from the
yaml-test-suite here:
L<https://perlpunk.github.io/YAML-PP-p5/test-suite.html>

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

The Dumper will create Emitter events from the given data structure.

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

=item Possibly more

=back

=head2 YAML::PP::Constructor

The Constructor now supports all three YAML 1.2 Schemas, Failsafe, JSON and Core.

You can choose the Schema, however, the API for that is not yet fixed.
Currently it looks like this:

    my $ypp = YAML::PP->new(schema => ['JSON']); # default is 'Core' for now

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

=item Tags

Tags are completely ignored.

=item Parse Tree

I would like to generate a complete parse tree, that allows you to manipulate
the data structure and also dump it, including all whitespaces and comments.
The spec says that this is throwaway content, but I read that many people
wish to be able to keep the comments.

=back

=head2 YAML::PP::Dumper, YAML::PP::Emitter

This is also pretty simple so far. Any string containing something
other than C<0-9a-zA-Z.-> will be dumped with double quotes.

It will recognize JSON::PP::Boolean and boolean.pm objects and dump them
correctly.

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


=head1 COPYRIGHT AND LICENSE

Copyright 2017 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut
