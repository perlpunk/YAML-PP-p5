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

    $schema->add_mapping_resolver(
        tag => '!Class1',
        on_create => sub { return bless { id => 23 }, 'Class1' },
        on_data => sub {
            my ($constructor, $data, $list) = @_;
            %$$data = (%$$data, @$list);
        },
    );

    $schema->add_representer(
      class_equals => 'Class1',
      code => sub {
        my ($representer, $node) = @_;
        # $node->{value} contains the object
        $node->{tag} = '!Class1';
        $node->{data} = $node->{value};
        return 1;
      },
    );
  }

1;
