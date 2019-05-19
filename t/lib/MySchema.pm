package MySchema;
  use base 'YAML::PP::Schema';
  use strict;
  use warnings;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    return $self;
  }

  sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_representer(
      class_equals => 'Class1',
      code => sub {
        my ($representer, $node) = @_;
        # $node->{value} contains the object
        $node->{tag} = '!Class1';
        $node->{ data } = '';
        return 1;
      },
    );
  }

1;
