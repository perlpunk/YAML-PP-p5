use strict;
use warnings;
package YAML::PP::Schema::Perl;

our $VERSION = '0.000'; # VERSION

use base 'YAML::PP::Schema';

use Scalar::Util qw/ blessed reftype /;
use YAML::PP::Common qw/ YAML_QUOTED_SCALAR_STYLE /;

use constant PREFIX_PERL => '!perl/';

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_resolver(
        match => [ equals => '' => '' ],
    );

    $schema->add_representer(
        undefined => sub {
            my ($rep, $node) = @_;
            $node->{data} = '';
            $node->{style} = YAML_QUOTED_SCALAR_STYLE;
            return 1;
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
    use YAML::PP::Schema::Perl;
    my $yp = YAML::PP->new( schema => [qw/ JSON Perl /] );
    my $yaml = $yp->dump_string(sub { return 23 });

=head1 DESCRIPTION

This schema allows you to dump perl objects and special types to YAML.

This code is pretty new and experimental. Typeglobs are not implemented
yet. Dumping code references is on by default.

Only dumping is supported so far.

This is a list of the currently supported types and how they are dumped into
YAML:

=cut

### BEGIN EXAMPLE

=pod

=over 4

=item array

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


=item code

        # Code
        sub {
            my ($self, %args) = @_;
            return $args{x} + $args{y};
        }


        # YAML
        --- !perl/code |-
          {
              use warnings;
              use strict;
              (my($self, %args) = @_);
              (return ($args{'x'} + $args{'y'}));
          }


=item code_blessed

        # Code
        bless sub {
            my ($self, %args) = @_;
            return $args{x} - $args{y};
        }, "I::Am::Code"


        # YAML
        --- !perl/code:I::Am::Code |-
          {
              use warnings;
              use strict;
              (my($self, %args) = @_);
              (return ($args{'x'} - $args{'y'}));
          }


=item hash

        # Code
        bless {
            U => 2,
            B => 52,
        }, 'A::Very::Exclusive::Class'


        # YAML
        --- !perl/hash:A::Very::Exclusive::Class
        B: 52
        U: 2


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
