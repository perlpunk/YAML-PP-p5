package YAML::PP::Test;
use strict;
use warnings;

sub get_tags {
    my ($class, %args) = @_;
    my %id_tags;
    my $dir = $args{test_suite_dir} . "/tags";

    return unless -d $dir;
    opendir my $dh, $dir or die $!;
    my @tags = grep { not m/^\./ } readdir $dh;
    for my $tag (sort @tags) {
        opendir my $dh, "$dir/$tag" or die $!;
        my @ids = grep { -l "$dir/$tag/$_" } readdir $dh;
        $id_tags{ $_ }->{ $tag } = 1 for @ids;
        closedir $dh;
    }
    closedir $dh;
    return %id_tags;
}

sub get_tests {
    my ($class, %args) = @_;
    my $test_suite_dir = $args{test_suite_dir};
    my $dir = $args{dir};
    my $valid = $args{valid};
    my $json = $args{json};

    my @dirs;
    if (-d $test_suite_dir) {

        opendir my $dh, $test_suite_dir or die $!;
        my @ids = grep { m/^[A-Z0-9]{4}\z/ } readdir $dh;
        @ids = grep {
            $valid
            ? not -f "$test_suite_dir/$_/error"
            : -f "$test_suite_dir/$_/error"
        } @ids;
        if ($json) {
            @ids = grep {
                -f "$test_suite_dir/$_/in.json"
            } @ids;
        }
        push @dirs, map { "$test_suite_dir/$_" } @ids;
        closedir $dh;

    }
    else {
        Test::More::diag("\n############################");
        Test::More::diag("No yaml-test-suite directory");
        Test::More::diag("Using only local tests");
        Test::More::diag("############################");
    }

    opendir my $dh, $dir or die $!;
    push @dirs, map { "$dir/$_" } grep {
        m/^[iv][A-Z0-9]{3}\z/
        and (not $json or -f "$dir/$_/in.json")
    } readdir $dh;
    closedir $dh;

    return @dirs;
}

1;
