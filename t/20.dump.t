#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use YAML::PP::Test;
use Data::Dumper;
use YAML::PP::Loader;
use YAML::PP::Dumper;
use Encode;
use File::Basename qw/ dirname basename /;

$|++;

my $yts = "$Bin/../yaml-test-suite";
my @dirs = YAML::PP::Test->get_tests(
    valid => 1,
    test_suite_dir => "$yts",
    dir => "$Bin/valid",
);

@dirs = sort @dirs;

# skip tests that parser can't parse
my @skip = qw/
    4ABK 54T7 5C5M 5KJE 5TRB 6HB6 87E4 8CWC 8UDB 9MMW
    C2DT C4HZ CN3R CT4Q D88J DBG4 DFF7 DHP8
    EHF6 F3CP FRK4 FUP4
    KZN9 L9U5 LP6E LQZ7 LX3P
    M5DY M7NX MXS3 N782
    Q88A Q9WF QF4Y
    SBG9 UDR7 UT92 WZ62 X38W YD5X ZF4X

    6BFJ
    7TMG
    Q5MG
/;

# dumper
# alias
#push @skip, qw/ v015 /;

push @skip, qw/
/;

my $skipped = \@skip;

my @todo = ();

# test all
if ($ENV{TEST_ALL}) {
    @todo = @$skipped;
    @$skipped = ();
}

if (my $dir = $ENV{YAML_TEST_DIR}) {
    @dirs = ($dir);
    @todo = ();
    @$skipped = ();
}
my %skip;
@skip{ @$skipped } = ();
my %todo;
@todo{ @todo } = ();

#plan tests => scalar @dirs;

my %results;
my %errors;
@results{qw/ DIFF OK ERROR TODO /} = ([], (0) x 3);
for my $item (@dirs) {
    my $dir = dirname $item;
    my $id = basename $item;
    my $skip = exists $skip{ $id };
    my $todo = exists $todo{ $id };
    next if $skip;

    open my $fh, "<", "$dir/$id/in.yaml" or die $!;
    my $yaml = do { local $/; <$fh> };
    close $fh;
    $yaml = decode_utf8 $yaml;
    open $fh, "<", "$dir/$id/===" or die $!;
    chomp(my $title = <$fh>);
    close $fh;

    my $out_yaml_file = "$dir/$id/out.yaml";
    $out_yaml_file = "$dir/$id/in.yaml" unless -f $out_yaml_file;
    open $fh, "<", $out_yaml_file or die $!;
    local $/;
    my $out_yaml = <$fh>;
    close $fh;

    if ($skip) {
        SKIP: {
            skip "SKIP $id", 1 if $skip;
            test($title, $id, $yaml, $out_yaml);
        }
    }
    elsif ($todo) {
        TODO: {
            local $TODO = $todo;
            test($title, $id, $yaml, $out_yaml);
        }
    }
    else {
        test($title, $id, $yaml, $out_yaml);
    }

}
my $skip_count = @$skipped;
diag "Skipped $skip_count tests";

sub test {
    my ($title, $name, $yaml, $exp_out_yaml) = @_;
#    warn __PACKAGE__.':'.__LINE__.": ================================ $name\n";
    my $ok = 0;
    my $loader = YAML::PP::Loader->new;
    my $dumper = YAML::PP::Dumper->new;
    my @docs = eval { $loader->load_string($yaml) };
    my $error = $@;
    my $out_yaml;
    unless ($error) {
        eval {
            $out_yaml = $dumper->dump_string(@docs);
        };
    }
    if ($@) {
        # should not happen though because we skip tests that cannot be parsed
        diag "ERROR: $@";
        $results{ERROR}++;
        my $error_type = 'unknown';
        push @{ $errors{ $error_type } }, $name;
        $error = 1;
    }

    my $reload_error;
    my @reload;
    if ($error) {
        ok(0, "$name - $title ERROR");
    }
    else {
        @reload = eval { $loader->load_string($out_yaml) };
        $reload_error = $@;
        if ($reload_error) {
            diag "RELOAD ERROR: $reload_error";
            $ok = 0;
            ok(0, "Reload $name - $title");
        }
        else {
            $ok = is_deeply(\@reload, \@docs, "Reload - $name - $title");
        }
    }
    if ($ok) {
        $results{OK}++;
    }
    else {
        push @{ $results{DIFF} }, $name unless $error;
        if ($TODO) {
            $results{TODO}++;
        }
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@docs], ['docs']);
        if (not $TODO or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$exp_out_yaml" unless $TODO;
            diag "OUT YAML:\n$out_yaml" unless $TODO;
            my $reload_dump = Data::Dumper->Dump([\@reload], ['reload']);
            diag "RELOAD DATA:\n$reload_dump" unless $TODO;
        }
    }
}
my $diff_count = @{ $results{DIFF} };
diag "OK: $results{OK} DIFF: $diff_count ERROR: $results{ERROR} TODO: $results{TODO}";
diag "DIFF: (@{ $results{DIFF} })";
for my $type (sort keys %errors) {
    diag "ERRORS($type): (@{ $errors{ $type } })";
}

done_testing;
