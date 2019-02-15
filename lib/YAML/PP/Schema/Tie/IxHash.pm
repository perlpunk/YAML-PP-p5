use strict;
use warnings;
package YAML::PP::Schema::Tie::IxHash;

our $VERSION = '0.000'; # VERSION

use base 'YAML::PP::Schema';

use Scalar::Util qw/ blessed reftype /;
use Tie::IxHash;

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_representer(
        tied_equals => 'Tie::IxHash',
        code => sub {
            my ($rep, $node) = @_;
            $node->{items} = [ %{ $node->{data} } ];
            return 1;
        },
    );
    return;
}

1;
