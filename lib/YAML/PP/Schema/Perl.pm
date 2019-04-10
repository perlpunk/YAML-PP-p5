use strict;
use warnings;
package YAML::PP::Schema::Perl;

our $VERSION = '0.000'; # VERSION

use base 'YAML::PP::Schema';

use Scalar::Util qw/ blessed reftype /;
use YAML::PP::Common qw/ YAML_QUOTED_SCALAR_STYLE /;

use constant PREFIX_PERL => '!perl/';

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

    if ($options->{with}->{loadcode}) {
        $schema->add_resolver(
            tag => '!perl/code',
            match => [ all => sub {
                my ($constructor, $event) = @_;
                my $code = $event->{value};
                $code = "sub $code";
                my $sub = eval $code;
                if ($@) {
                    die "Couldn't eval code: $@>>$code<<";
                }
                return $sub;
            }],
            implicit => 0,
        );
        $schema->add_resolver(
            tag => qr{^!perl/code:.*},
            match => [ all => sub {
                my ($constructor, $event) = @_;
                my $class = $event->{tag};
                $class =~ s{^!perl/code:}{};
                my $code = $event->{value};
                $code = "sub $code";
                my $sub = eval $code;
                if ($@) {
                    die "Couldn't eval code: $@>>$code<<";
                }
                return bless $sub, $class;
            }],
            implicit => 0,
        );
    }
    else {
        $schema->add_resolver(
            tag => '!perl/code',
            match => [ all => sub {
                my ($constructor, $event) = @_;
                my $code = sub {};
                return $code;
            }],
            implicit => 0,
        );
        $schema->add_resolver(
            tag => qr{^!perl/code:.*},
            match => [ all => sub {
                my ($constructor, $event) = @_;
                my $class = $event->{tag};
                $class =~ s{^!perl/code:}{};
                my $code = sub {};
                return bless $code, $class;
            }],
            implicit => 0,
        );
    }

    $schema->add_resolver(
        tag => '!perl/regexp',
        match => [ all => sub {
            my ($constructor, $event) = @_;
            my $regex = $event->{value};
            if ($regex =~ m/^\Q$qr_prefix\E(.*)\)\z/s) {
                $regex = $1;
            }
            my $qr = qr{$regex};
            return $qr;
        }],
        implicit => 0,
    );
    $schema->add_resolver(
        tag => qr{^!perl/regexp:.*},
        match => [ all => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^!perl/regexp:}{};
            my $regex = $event->{value};
            if ($regex =~ m/^\Q$qr_prefix\E(.*)\)\z/s) {
                $regex = $1;
            }
            my $qr = qr{$regex};
            return bless $qr, $class;
        }],
        implicit => 0,
    );

    $schema->add_sequence_resolver(
        tag => '!perl/array',
        on_create => sub {
            my ($constructor, $event) = @_;
            return [];
        },
    );
    $schema->add_sequence_resolver(
        tag => qr{^!perl/array:.*},
        on_create => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^!perl/array:}{};
            return bless [], $class;
        },
    );
    $schema->add_mapping_resolver(
        tag => '!perl/hash',
        on_create => sub {
            my ($constructor, $event) = @_;
            return {};
        },
    );
    $schema->add_mapping_resolver(
        tag => qr{^!perl/hash:.*},
        on_create => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^!perl/hash:}{};
            return bless {}, $class;
        },
    );
    $schema->add_mapping_resolver(
        tag => '!perl/ref',
        on_create => sub {
            my ($constructor, $event) = @_;
            my $value = undef;
            return \$value;
        },
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            if (@$list > 2) {
                die "Unexpected data in !perl/scalar construction";
            }
            my ($key, $value) = @$list;
            unless ($key eq '=') {
                die "Unexpected data in !perl/scalar construction";
            }
            $$ref = $value;
        },
    );
    $schema->add_mapping_resolver(
        tag => qr{^!perl/ref:.*},
        on_create => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^!perl/ref:}{};
            my $value = undef;
            return bless \$value, $class;
        },
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            if (@$list > 2) {
                die "Unexpected data in !perl/scalar construction";
            }
            my ($key, $value) = @$list;
            unless ($key eq '=') {
                die "Unexpected data in !perl/scalar construction";
            }
            $$ref = $value;
        },
    );
    $schema->add_mapping_resolver(
        tag => '!perl/scalar',
        on_create => sub {
            my ($constructor, $event) = @_;
            my $value = undef;
            return \$value;
        },
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            if (@$list > 2) {
                die "Unexpected data in !perl/scalar construction";
            }
            my ($key, $value) = @$list;
            unless ($key eq '=') {
                die "Unexpected data in !perl/scalar construction";
            }
            $$ref = $value;
        },
    );
    $schema->add_mapping_resolver(
        tag => qr{^!perl/scalar:.*},
        on_create => sub {
            my ($constructor, $event) = @_;
            my $class = $event->{tag};
            $class =~ s{^!perl/scalar:}{};
            my $value = undef;
            return bless \$value, $class;
        },
        on_data => sub {
            my ($constructor, $ref, $list) = @_;
            if (@$list > 2) {
                die "Unexpected data in !perl/scalar construction";
            }
            my ($key, $value) = @$list;
            unless ($key eq '=') {
                die "Unexpected data in !perl/scalar construction";
            }
            $$ref = $value;
        },
    );

    $schema->add_representer(
        scalarref => 1,
        code => sub {
            my ($rep, $node) = @_;
            $node->{tag} = PREFIX_PERL . "scalar";
            if (blessed($node->{value})) {
                $node->{tag} .= ':' . blessed($node->{value});
            }
            %{ $node->{data} } = ( '=' => ${ $node->{value} } );
        },
    );
    $schema->add_representer(
        refref => 1,
        code => sub {
            my ($rep, $node) = @_;
            $node->{tag} = PREFIX_PERL . "ref";
            if (blessed($node->{value})) {
                $node->{tag} .= ':' . blessed($node->{value});
            }
            %{ $node->{data} } = ( '=' => ${ $node->{value} } );
        },
    );
    $schema->add_representer(
        coderef => 1,
        code => sub {
            my ($rep, $node) = @_;
            require B::Deparse;
            my $deparse = B::Deparse->new("-p", "-sC");
            $node->{tag} = PREFIX_PERL . "code";
            $node->{data} = $deparse->coderef2text($node->{value});
        },
    );

    $schema->add_representer(
        class_matches => 1,
        code => sub {
            my ($rep, $node) = @_;
            my $blessed = blessed $node->{value};
            $node->{tag} = sprintf PREFIX_PERL . "%s:%s",
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
                    $node->{tag} = sprintf PREFIX_PERL . "%s",
                        lc($node->{reftype});
                }
                $node->{data} = "$node->{value}";
            }
            elsif ($node->{reftype} eq 'SCALAR') {

                # in perl <= 5.10 regex reftype(regex) was SCALAR
                if ($blessed eq 'Regexp') {
                    $node->{tag} = PREFIX_PERL . 'regexp';
                    $node->{data} = "$node->{value}";
                }

                # In perl <= 5.10 there seemed to be no better pure perl
                # way to detect a blessed regex?
                elsif (
                    $] <= 5.010001
                    and not defined ${ $node->{value} }
                    and $node->{value} =~ m/^\(\?/
                ) {
                    $node->{tag} = PREFIX_PERL . 'regexp:' . $blessed;
                    $node->{data} = "$node->{value}";
                }
                else {
                    # phew, just a simple scalarref
                    %{ $node->{data} } = ( '=' => ${ $node->{value} } );
                }
            }
            elsif ($node->{reftype} eq 'REF') {
                %{ $node->{data} } = ( '=' => ${ $node->{value} } );
            }

            elsif ($node->{reftype} eq 'CODE') {
                require B::Deparse;
                my $deparse = B::Deparse->new("-p", "-sC");
                $node->{data} = $deparse->coderef2text($node->{value});
            }
            else {
                die "Reftype '$node->{reftype}' not implemented";
            }

            return 1;
        },
    );
    return;
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

This schema allows you to dump perl objects and special types to YAML.

Please note that loading objects of arbitrary classes can be dangerous
in Perl. You have to load the modules yourself, but if an exploitable module
is loaded and an object is created, its C<DESTROY> method will be called
when the object falls out of scope. L<File::Temp> is an example that can
be exploitable and might remove arbitrary files.

This code is pretty new and experimental. Typeglobs are not implemented
yet. Dumping code references is on by default, but not loading (because
that is easily exploitable since it's using string C<eval>).

Currently it only supports tags with a single exclamation mark.
L<YAML>.pm and L<YAML::Syck> are supporting both C<!perl/type:...> and
C<!!perl/type:...>. L<YAML::XS> currently only supports the latter.

I want to support both styles via an option.

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
        --- !perl/regexp (?^:unblessed)


=item regexp_blessed

        # Code
        bless qr{blessed}, "Foo"


        # YAML
        --- !perl/regexp:Foo (?^:blessed)


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

=back

=cut
