use strict;
use warnings;
package YAML::PP::Schema::Perl;

our $VERSION = '0.000'; # VERSION

use base 'YAML::PP::Schema';

use Scalar::Util qw/ blessed reftype /;
use YAML::PP::Common qw/ YAML_QUOTED_SCALAR_STYLE /;

my $qr_prefix;
# workaround to avoid growing regexes when repeatedly loading and dumping
# e.g. (?^:(?^:regex))
{
    my $test_qr = qr{TEST_STRINGYFY_REGEX};
    my $test_qr_string = "$test_qr";
    $qr_prefix = $test_qr_string;
    $qr_prefix =~ s/TEST_STRINGYFY_REGEX.*//;
}

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};
    my $options = $args{options};

    $schema->add_resolver(
        match => [ equals => '' => '' ],
    );

    my $tagtype = '!';
    for my $option (@$options) {
        if ($option =~ m/^tag=(.*)$/) {
            $tagtype = $1;
        }
    }

    # TODO
    # check content and deprecate old usage
    $tagtype =~ s/perl//g;
    my $perl_tag;
    my @perl_tags;
    my @tagtypes = split m/\+/, $tagtype;
    if ($tagtypes[0] eq '!') {
        $perl_tag = '!perl';
    }
    elsif ($tagtypes[0] eq '!!') {
        $perl_tag = 'tag:yaml.org,2002:perl';
    }
    for my $tagtype (@tagtypes) {
        if ($tagtype eq '!') {
            push @perl_tags, '!perl';
        }
        elsif ($tagtype eq '!!') {
            push @perl_tags, 'tag:yaml.org,2002:perl';
        }
    }

    my $perl_regex = '!perl';
    if ($tagtype eq '!') {
        $perl_regex = '!perl';
    }
    elsif ($tagtype eq '!!') {
        $perl_regex = 'tag:yaml\\.org,2002:perl';
    }
    elsif ($tagtype eq '!+!!') {
        $perl_regex = '(?:tag:yaml\\.org,2002:|!)perl';
    }
    elsif ($tagtype eq '!!+!') {
        $perl_regex = '(?:tag:yaml\\.org,2002:|!)perl';
    }

    if (grep { $_ eq '+loadcode' } @$options) {
        $schema->add_resolver(
            tag => "$_/code",
            match => [ all => sub {
                my ($constructor, $event) = @_;
                return $self->evaluate_code($event->{value});
            }],
            implicit => 0,
        ) for @perl_tags;
        $schema->add_resolver(
            tag => qr{^$perl_regex/code:.*},
            match => [ all => sub {
                my ($constructor, $event) = @_;
                my $class = $event->{tag};
                $class =~ s{^$perl_regex/code:}{};
                my $sub = $self->evaluate_code($event->{value});
                return $self->object($sub, $class);
            }],
            implicit => 0,
        );
    }
    else {
        $schema->add_resolver(
            tag => "$_/code",
            match => [ all => sub {
                return sub {};
            }],
            implicit => 0,
        ) for @perl_tags;
        $schema->add_resolver(
            tag => qr{^$perl_regex/code:.*},
            match => [ all => sub {
                my ($constructor, $event) = @_;
                my $class = $event->{tag};
                $class =~ s{^$perl_regex/code:}{};
                return $self->object(sub {}, $class);
            }],
            implicit => 0,
        );
    }

    $schema->add_resolver(
        tag => "$_/regexp",
        match => [ all => sub {
            my ($constructor, $event) = @_;
            return $self->construct_regex($event->{value});
        }],
        implicit => 0,
    ) for @perl_tags;
    $schema->add_resolver(
        tag => qr{^$perl_regex/regexp:.*},
        match => [ all => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^$perl_regex/regexp:}{};
            my $qr = $self->construct_regex($event->{value});
            return $self->object($qr, $class);
        }],
        implicit => 0,
    );

    $schema->add_sequence_resolver(
        tag => "$_/array",
        on_create => sub {
            return [];
        },
    ) for @perl_tags;
    $schema->add_sequence_resolver(
        tag => qr{^$perl_regex/array:.*},
        on_create => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^$perl_regex/array:}{};
            return $self->object([], $class);
        },
    );
    $schema->add_mapping_resolver(
        tag => "$_/hash",
        on_create => sub {
            return {};
        },
    ) for @perl_tags;
    $schema->add_mapping_resolver(
        tag => qr{^$perl_regex/hash:.*},
        on_create => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^$perl_regex/hash:}{};
            return $self->object({}, $class);
        },
    );
    $schema->add_mapping_resolver(
        tag => "$_/ref",
        on_create => sub {
            my $value = undef;
            return \$value;
        },
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            $$ref = $self->construct_ref($list);
        },
    ) for @perl_tags;
    $schema->add_mapping_resolver(
        tag => qr{^$perl_regex/ref:.*},
        on_create => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^$perl_regex/ref:}{};
            my $value = undef;
            return $self->object(\$value, $class);
        },
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            $$ref = $self->construct_ref($list);
        },
    );
    $schema->add_mapping_resolver(
        tag => "$_/scalar",
        on_create => sub {
            my $value = undef;
            return \$value;
        },
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            $$ref = $self->construct_scalar($list);
        },
    ) for @perl_tags;
    $schema->add_mapping_resolver(
        tag => qr{^$perl_regex/scalar:.*},
        on_create => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^$perl_regex/scalar:}{};
            my $value = undef;
            return $self->object(\$value, $class);
        },
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            $$ref = $self->construct_scalar($list);
        },
    );

    $schema->add_representer(
        scalarref => 1,
        code => sub {
            my ($rep, $node) = @_;
            $node->{tag} = $perl_tag . "/scalar";
            $node->{data} = $self->represent_scalar($node->{value});
        },
    );
    $schema->add_representer(
        refref => 1,
        code => sub {
            my ($rep, $node) = @_;
            $node->{tag} = $perl_tag . "/ref";
            $node->{data} = $self->represent_ref($node->{value});
        },
    );
    $schema->add_representer(
        coderef => 1,
        code => sub {
            my ($rep, $node) = @_;
            $node->{tag} = $perl_tag . "/code";
            $node->{data} = $self->represent_code($node->{value});
        },
    );

    $schema->add_representer(
        class_matches => 1,
        code => sub {
            my ($rep, $node) = @_;
            my $blessed = blessed $node->{value};
            $node->{tag} = sprintf "$perl_tag/%s:%s",
                lc($node->{reftype}), $blessed;
            if ($node->{reftype} eq 'HASH') {
                $node->{data} = $node->{value};
            }
            elsif ($node->{reftype} eq 'ARRAY') {
                $node->{data} = $node->{value};
            }

            # Fun with regexes in perl versions!
            elsif ($node->{reftype} eq 'REGEXP') {
                if ($blessed eq 'Regexp') {
                    $node->{tag} = $perl_tag . "/regexp";
                }
                $node->{data} = $self->represent_regex($node->{value});
            }
            elsif ($node->{reftype} eq 'SCALAR') {

                # in perl <= 5.10 regex reftype(regex) was SCALAR
                if ($blessed eq 'Regexp') {
                    $node->{tag} = $perl_tag . '/regexp';
                    $node->{data} = $self->represent_regex($node->{value});
                }

                # In perl <= 5.10 there seemed to be no better pure perl
                # way to detect a blessed regex?
                elsif (
                    $] <= 5.010001
                    and not defined ${ $node->{value} }
                    and $node->{value} =~ m/^\(\?/
                ) {
                    $node->{tag} = $perl_tag . '/regexp:' . $blessed;
                    $node->{data} = $self->represent_regex($node->{value});
                }
                else {
                    # phew, just a simple scalarref
                    $node->{data} = $self->represent_scalar($node->{value});
                }
            }
            elsif ($node->{reftype} eq 'REF') {
                $node->{data} = $self->represent_ref($node->{value});
            }

            elsif ($node->{reftype} eq 'CODE') {
                $node->{data} = $self->represent_code($node->{value});
            }
            else {
                die "Reftype '$node->{reftype}' not implemented";
            }

            return 1;
        },
    );
    return;
}

sub evaluate_code {
    my ($self, $code) = @_;
    unless ($code =~ m/^ \s* \{ .* \} \s* \z/xs) {
        die "Malformed code";
    }
    $code = "sub $code";
    my $sub = eval $code;
    if ($@) {
        die "Couldn't eval code: $@>>$code<<";
    }
    return $sub;
}

sub construct_regex {
    my ($self, $regex) = @_;
    if ($regex =~ m/^\Q$qr_prefix\E(.*)\)\z/s) {
        $regex = $1;
    }
    my $qr = qr{$regex};
    return $qr;
}

sub construct_scalar {
    my ($self, $list) = @_;
    if (@$list != 2) {
        die "Unexpected data in perl/scalar construction";
    }
    my ($key, $value) = @$list;
    unless ($key eq '=') {
        die "Unexpected data in perl/scalar construction";
    }
    return $value;
}

sub construct_ref {
    &construct_scalar;
}

sub represent_scalar {
    my ($self, $value) = @_;
    return { '=' => $$value };
}

sub represent_ref {
    &represent_scalar;
}

sub represent_code {
    my ($self, $code) = @_;
    require B::Deparse;
    my $deparse = B::Deparse->new("-p", "-sC");
    return $deparse->coderef2text($code);
}

sub represent_regex {
    my ($self, $regex) = @_;
    $regex = "$regex";
    if ($regex =~ m/^\Q$qr_prefix\E(.*)\)\z/s) {
        $regex = $1;
    }
    return $regex;
}

sub object {
    my ($self, $data, $class) = @_;
    return bless $data, $class;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Schema::Perl - Schema for serializing perl objects and special types

=head1 SYNOPSIS

    use YAML::PP;
    # This can be dangerous when loading untrusted YAML!
    my $yp = YAML::PP->new( schema => [qw/ JSON Perl /] );
    # or
    my $yp = YAML::PP->new( schema => [qw/ Core Perl /] );
    my $yaml = $yp->dump_string(sub { return 23 });

    # loading code references
    # This is very dangerous when loading untrusted YAML!!
    my $yp = YAML::PP->new( schema => [qw/ JSON Perl +loadcode /] );
    my $code = $yp->load_string(<<'EOM');
    --- !perl/code |
        {
            use 5.010;
            my ($name) = @_;
            say "Hello $name!";
        }
    EOM
    $code->("Ingy");

=head1 DESCRIPTION

This schema allows you to load and dump perl objects and special types.

Please note that loading objects of arbitrary classes can be dangerous
in Perl. You have to load the modules yourself, but if an exploitable module
is loaded and an object is created, its C<DESTROY> method will be called
when the object falls out of scope. L<File::Temp> is an example that can
be exploitable and might remove arbitrary files.

This code is pretty new and experimental. Typeglobs are not implemented
yet. Dumping code references is on by default, but not loading (because
that is easily exploitable since it's using string C<eval>).

=head1 TAG STYLES

You can define the style of tags you want to support:

    my $yp_perl_two_one = YAML::PP->new(
        schema => [qw/ JSON Perl tag=!!perl+!perl /],
    );

=over

=item C<!perl>

Only C<!perl/type> tags are supported.

=item C<!!perl>

Only C<!!perl/type> tags are supported.

=item C<!perl+!!perl>

Both C<!perl/type> and C<!!perl/tag> are supported when loading. When dumping,
C<!perl/type> is used.

=item C<!!perl+!perl>

Both C<!perl/type> and C<!!perl/tag> are supported when loading. When dumping,
C<!!perl/type> is used.

=back

L<YAML>.pm, L<YAML::Syck> and L<YAML::XS> are using C<!!perl/type> when dumping.

L<YAML>.pm and L<YAML::Syck> are supporting both C<!perl/type> and
C<!!perl/type> when loading. L<YAML::XS> currently only supports the latter.

=cut

=head1 EXAMPLES

This is a list of the currently supported types and how they are dumped into
YAML:

=cut

### BEGIN EXAMPLE

=pod

=over 4

=item array

        # Code
        [
            qw/ one two three four /
        ]


        # YAML
        ---
        - one
        - two
        - three
        - four


=item array_blessed

        # Code
        bless [
            qw/ one two three four /
        ], "Just::An::Arrayref"


        # YAML
        --- !perl/array:Just::An::Arrayref
        - one
        - two
        - three
        - four


=item circular

        # Code
        my $circle = bless [ 1, 2 ], 'Circle';
        push @$circle, $circle;
        $circle;


        # YAML
        --- &1 !perl/array:Circle
        - 1
        - 2
        - *1


=item coderef

        # Code
        sub {
            my (%args) = @_;
            return $args{x} + $args{y};
        }


        # YAML
        --- !perl/code |-
          {
              use warnings;
              use strict;
              (my(%args) = @_);
              (return ($args{'x'} + $args{'y'}));
          }


=item coderef_blessed

        # Code
        bless sub {
            my (%args) = @_;
            return $args{x} - $args{y};
        }, "I::Am::Code"


        # YAML
        --- !perl/code:I::Am::Code |-
          {
              use warnings;
              use strict;
              (my(%args) = @_);
              (return ($args{'x'} - $args{'y'}));
          }


=item hash

        # Code
        {
            U => 2,
            B => 52,
        }


        # YAML
        ---
        B: 52
        U: 2


=item hash_blessed

        # Code
        bless {
            U => 2,
            B => 52,
        }, 'A::Very::Exclusive::Class'


        # YAML
        --- !perl/hash:A::Very::Exclusive::Class
        B: 52
        U: 2


=item refref

        # Code
        my $ref = { a => 'hash' };
        my $refref = \$ref;
        $refref;


        # YAML
        --- !perl/ref
        =:
          a: hash


=item refref_blessed

        # Code
        my $ref = { a => 'hash' };
        my $refref = bless \$ref, 'Foo';
        $refref;


        # YAML
        --- !perl/ref:Foo
        =:
          a: hash


=item regexp

        # Code
        qr{unblessed}


        # YAML
        --- !perl/regexp unblessed


=item regexp_blessed

        # Code
        bless qr{blessed}, "Foo"


        # YAML
        --- !perl/regexp:Foo blessed


=item scalarref

        # Code
        my $scalar = "some string";
        my $scalarref = \$scalar;
        $scalarref;


        # YAML
        --- !perl/scalar
        =: some string


=item scalarref_blessed

        # Code
        my $scalar = "some other string";
        my $scalarref = bless \$scalar, 'Foo';
        $scalarref;


        # YAML
        --- !perl/scalar:Foo
        =: some other string




=back

=cut

### END EXAMPLE

=head1 METHODS

=over

=item register

A class method called by L<YAML::PP::Schema>

=item construct_ref, represent_ref

Perl variables of the type C<REF> are represented in yaml like this:

    --- !perl/ref
    =:
      a: 1

C<construct_ref> returns the perl data:

    my $data = YAML::PP::Schema::Perl->construct_ref([ '=', { some => 'data' } );
    my $data = \{ a => 1 };

C<represent_ref> turns a C<REF> variable into a YAML mapping:

    my $data = YAML::PP::Schema::Perl->represent_ref(\{ a => 1 });
    my $data = { '=' => { a => 1 } };

=item construct_scalar, represent_scalar

Perl variables of the type C<SCALAR> are represented in yaml like this:

    --- !perl/scalar
    =: string

C<construct_scalar> returns the perl data:

    my $data = YAML::PP::Schema::Perl->construct_ref([ '=', 'string' );
    my $data = \'string';

C<represent_scalar> turns a C<SCALAR> variable into a YAML mapping:

    my $data = YAML::PP::Schema::Perl->represent_scalar(\'string');
    my $data = { '=' => 'string' };

=item construct_regex, represent_regex

C<construct_regex> returns a C<qr{}> object from the YAML string:

    my $qr = YAML::PP::Schema::Perl->construct_regex('foo.*');

C<represent_regex> returns a string representing the regex object:

    my $string = YAML::PP::Schema::Perl->represent_regex(qr{...});

=item evaluate_code, represent_code

C<evaluate_code> returns a code reference from a string. The string must
start with a C<{> and end with a C<}>.

    my $code = YAML::PP::Schema::Perl->evaluate_code('{ return 23 }');

C<represent_code> returns a string representation of the code reference
with the help of B::Deparse:

    my $string = YAML::PP::Schema::Perl->represent_code(sub { return 23 });

=item object

Does the same as C<bless>:

    my $object = YAML::PP::Schema::Perl->object($data, $class);

=back

=cut
