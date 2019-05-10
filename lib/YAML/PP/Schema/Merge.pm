use strict;
use warnings;
package YAML::PP::Schema::Merge;

our $VERSION = '0.000'; # VERSION

use YAML::PP::Type::MergeKey;

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_resolver(
        tag => 'tag:yaml.org,2002:merge',
        match => [ equals => '<<' => YAML::PP::Type::MergeKey->new ],
    );
}

1;
