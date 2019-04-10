#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use FindBin '$Bin';
use lib "$Bin/../lib";
use YAML::PP;

my $tests_perl = require "$Bin/../examples/schema-perl.pm";
my $tests_ixhash = require "$Bin/../examples/schema-ixhash.pm";

my $schema_perl_pm_file = "$Bin/../lib/YAML/PP/Schema/Perl.pm";
my $schema_ixhash_pm_file = "$Bin/../lib/YAML/PP/Schema/Tie/IxHash.pm";

my $yp = YAML::PP->new( schema => [qw/ JSON Perl Tie::IxHash /] );

generate(
    file => $schema_perl_pm_file,
    tests => $tests_perl,
);
generate(
    file => $schema_ixhash_pm_file,
    tests => $tests_ixhash,
);

sub generate {
    my %args = @_;
    my $file = $args{file};
    my $tests = $args{tests};
    open my $fh, '<', $file;
    my $text = do { local $/; <$fh> };
    close $fh;

    my $examples;
    for my $name (sort keys %$tests) {
        my $test = $tests->{ $name };
        my $code = $test->[0];
        my $data = eval $code;
        if ($@) {
            die "Error: $@";
        }
        my $yaml = $yp->dump_string($data);
        $yaml =~ s/^/        /gm;
        my $example = <<"EOM";
=item $name

        # Code
$code

        # YAML
$yaml

EOM
        $examples .= $example;
    }

    my $pod = <<"EOM";
### BEGIN EXAMPLE

=pod

=over 4

$examples

=back

=cut

### END EXAMPLE
EOM

    $text =~ s/^### BEGIN EXAMPLE.*^### END EXAMPLE\n/$pod/ms;

    open $fh, '>', $file;
    print $fh $text;
    close $fh;
}
