package YAML::PP::Test;
use strict;
use warnings;

use File::Basename qw/ dirname basename /;
use Encode;
use Test::More;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        stats => {},
        %args,
    }, $class;
    return $self;
}

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

sub read_tests {
    my ($self, %args) = @_;
    my $test_suite_dir = $self->{test_suite_dir};
    my $dir = $self->{dir};
    my $valid = $self->{valid};
    my $skip = $args{skip};

    my @dirs = $self->get_tests(
        test_suite_dir => $test_suite_dir,
        dir => $dir,
        valid => $valid,
        %args,
    );

    my @todo = ();

    if ($ENV{TEST_ALL}) {
        @todo = @$skip;
        @$skip = ();
    }

    if (my $dir = $ENV{YAML_TEST_DIR}) {
        @dirs = ($dir);
        @todo = ();
        @$skip = ();
    }

    my $skipped;
    @$skipped{ @$skip } = (1) x @$skip;

    my %todo;
    @todo{ @todo } = ();

    my @testcases;
    for my $dir (sort @dirs) {
        my $id = basename $dir;

        open my $fh, '<', "$dir/===" or die $!;
        chomp(my $title = <$fh>);
        close $fh;

        my @test_events;
        if ($self->{events}) {
            open my $fh, '<', "$dir/test.event" or die $!;
            chomp(@test_events = <$fh>);
            close $fh;
        }

        my $in_yaml;
        if ($self->{in_yaml}) {
            open my $fh, "<", "$dir/in.yaml" or die $!;
            my $yaml = do { local $/; <$fh> };
            close $fh;
            $in_yaml = decode_utf8($yaml);
        }

        my $in_json;
        if ($self->{in_json}) {
            unless (-f "$dir/in.json") {
                # ignore all tests whichhave no in.json
                next;
            }
            open my $fh, "<", "$dir/in.json" or die $!;
            $in_json = do { local $/; <$fh> };
            close $fh;
            $in_json = decode_utf8($in_json);
        }

        my $test = {
            id => $id,
            dir => dirname($dir),
            title => $title,
            test_events => \@test_events,
            in_yaml => $in_yaml,
            in_json => $in_json,
        };
        push @testcases, $test;
    }

    $self->{skipped} = $skipped;
    $self->{todo} = \%todo;
    $self->{testcases} = \@testcases;
    return (\@testcases);
}

sub run_testcases {
    my ($self, %args) = @_;
    my $skipped = $self->{skipped};
    my $testcases = $self->{testcases};
    my $todos = $self->{todo};
    my $code = $args{code};
    my $skip_count = keys %$skipped;
    my $results = $self->{stats};
    @$results{qw/ DIFFS OKS DIFF OK ERROR TODO SKIP /} = ([], [], (0) x 5);

    for my $testcase (@$testcases) {
        my $id = $testcase->{id};
        my $skip = delete $skipped->{ $id };
#        next if $skip;
        my $todo = exists $todos->{ $id };
        $testcase->{todo} = $todo;

    #    diag "------------------------------ $id";

        my $result;
        if ($skip) {
            SKIP: {
                $results->{SKIP}++;
                skip "SKIP $id", 1 if $skip;
                $result = $code->($self, $testcase);
            }
        }
        elsif ($todo) {
            TODO: {
                local $TODO = $todo;
                $result = $code->($self, $testcase);
            }
        }
        else {
            $result = $code->($self, $testcase);
        }

    }
    if (keys %$skipped) {
        # are there any leftover skips?
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$skipped], ['skipped']);
    }
#    diag "Skipped $skip_count tests";

}

sub parse_events {
    my ($class, $testcase) = @_;

    my @events;
    my $parser = YAML::PP::Parser->new(
        receiver => sub {
            my ($self, @args) = @_;
            push @events, YAML::PP::Parser->event_to_test_suite(\@args);
        },
    );
    eval {
        $parser->parse_string($testcase->{in_yaml});
    };
    my $err = $@;
    my $line = $parser->lexer->line;
    return {
        events => \@events,
        err => $err,
        parser => $parser,
        line => $line,
    };
}

sub compare_parse_events {
    my ($self, $testcase, $result) = @_;
    my $results = $self->{stats};
    my $id = $testcase->{id};
    my $title = $testcase->{title};
    my $err = $result->{err};
    my $yaml = $testcase->{in_yaml};
    my $test_events = $testcase->{test_events};
    my $exp_lines = () = $yaml =~ m/[\r\n]/g;

    my @events = @{ $result->{events} };
    $_ = encode_utf8 $_ for @events;

    my $ok = 0;
    if ($err) {
        $results->{ERROR}++;
        ok(0, "$id - $title (ERROR)");
    }
    else {
        $ok = is_deeply(\@events, $test_events, "$id - $title");
    }
    if ($ok) {
        $results->{OK}++;
        my $lines = $result->{line};
        cmp_ok($lines, '==', $exp_lines, "$id - Line count $lines == $exp_lines");
    }
    else {
        push @{ $results->{DIFFS} }, $id unless $err;
        $results->{DIFF}++;
        if ($testcase->{todo}) {
            $results->{TODO}++;
        }
        if (not $testcase->{todo} or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$yaml" unless $testcase->{todo};
            diag "EVENTS:\n" . join '', map { "$_\n" } @$test_events;
            diag "GOT EVENTS:\n" . join '', map { "$_\n" } @events;
        }
    }
}

sub compare_invalid_parse_events {
    my ($self, $testcase, $result) = @_;
    my $results = $self->{stats};
    my $id = $testcase->{id};
    my $title = $testcase->{title};
    my $err = $result->{err};
    my $yaml = $testcase->{in_yaml};
    my $test_events = $testcase->{test_events};

    my $ok = 0;
    if (not $err) {
        $results->{OK}++;
        push @{ $results->{OKS} }, $id;
        ok(0, "$id - $title - should be invalid");
    }
    else {
        $results->{ERROR}++;
        if (not $result->{events}) {
            $ok = ok(1, "$id - $title");
        }
        else {
            $ok = is_deeply($result->{events}, $test_events, "$id - $title");
        }
    }

    if ($ok) {
    }
    else {
        $results->{DIFF}++;
        if ($TODO) {
            $results->{TODO}++;
        }
        if (not $testcase->{todo} or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$yaml" unless $TODO;
            diag "EVENTS:\n" . join '', map { "$_\n" } @$test_events;
            diag "GOT EVENTS:\n" . join '', map { "$_\n" } @{ $result->{events} };
        }
    }
}

sub load_json {
    my ($self, $testcase) = @_;

    my $ypp = YAML::PP->new(boolean => 'JSON::PP');
    my @docs = eval { $ypp->load_string($testcase->{in_yaml}) };

    my $err = $@;
    return {
        data => \@docs,
        err => $err,
    };
}

sub compare_load_json {
    my ($self, $testcase, $result) = @_;
    my $results = $self->{stats};
    my $id = $testcase->{id};
    my $title = $testcase->{title};
    my $err = $result->{err};
    my $yaml = $testcase->{in_yaml};
    my $exp_json = $testcase->{in_json};
    my $docs = $result->{data};

    # input can contain multiple JSON
    my @exp_json = split m/^(?=true|false|null|[0-9"\{\[])/m, $exp_json;
    $exp_json = '';
    my $coder = JSON::PP->new->ascii->pretty->allow_nonref->canonical;
    for my $exp (@exp_json) {
        my $data = $coder->decode($exp);
        $exp = $coder->encode($data);
        $exp_json .= $exp;
    }

    my $json = '';
    for my $doc (@$docs) {
        my $j = $coder->encode($doc);
        $json .= $j;
    }

    my $ok = 0;
    if ($err) {
        $results->{ERROR}++;
        push @{ $results->{ERRORS} }, $id;
        ok(0, "$id - $title - ERROR");
    }
    else {
        $results->{OK}++;
        $ok = cmp_ok($json, 'eq', $exp_json, "$id - load -> JSON equals expected JSON");
        unless ($ok) {
            $results->{DIFF}++;
            push @{ $results->{DIFFS} }, $id;
        }
    }

    unless ($ok) {
        if ($testcase->{todo}) {
            $results->{TODO}++;
        }
        if (not $testcase->{todo} or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$yaml" unless $TODO;
            diag "JSON:\n" . $exp_json;
            diag "GOT JSON:\n" . $json;
        }
    }
}

1;
