use strict;
use warnings;
package YAML::PP::Exception;

our $VERSION = '0.000'; # VERSION

use overload '""' => \&to_string;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        line => $args{line},
        msg => $args{msg},
        next => $args{next},
        where => $args{where},
        yaml => $args{yaml},
    }, $class;
    return $self;
}

sub to_string {
    my ($self) = @_;
    my $next = $self->{next};
    my $yaml = '';
    for my $token (@$next) {
        $yaml .= $token->{value};
    }
    my $remaining_yaml = $self->{yaml}->[0] // '';
    $yaml .= $remaining_yaml;
    $yaml =~ s/[\r\n].*//s;
    {
        local $@; # avoid bug in old Data::Dumper
        require Data::Dumper;
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Terse = 1;
        $yaml = Data::Dumper->Dump([$yaml], ['yaml']);
        chomp $yaml;
    }
    my $fmt = join "\n", ("%-10s: %s") x 4;
    my $string = sprintf $fmt,
        "Line", $self->{line},
        "Message", $self->{msg},
        "Where", $self->{where},
        "YAML", $yaml,
        ;
    return $string;
}

1;
