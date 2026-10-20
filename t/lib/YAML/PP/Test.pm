package YAML::PP::Test;
use strict;
use warnings;

use File::Basename qw/ dirname basename /;
use Encode;
use Test::More;
use YAML::PP qw/ LoadFile /;
use YAML::PP::Common qw/ YAML_FLOW_SEQUENCE_STYLE YAML_FLOW_MAPPING_STYLE YAML_PLAIN_SCALAR_STYLE /;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        stats => {},
        %args,
    }, $class;
    $self->{tag2ids} = LoadFile "$self->{test_suite_dir}/../tag_id.yaml";
    return $self;
}

sub get_tests {
    my ($self) = @_;
    my $test_suite_dir = $self->{test_suite_dir};
    my $dir = $self->{dir};
    my $tag = $self->{tag};
    my $tag2ids = $self->{tag2ids};
    my $valid = $self->{valid};
    my $json = $self->{in_json};

    my @dirs;
    if (-d $test_suite_dir) {

        opendir my $dh, $test_suite_dir or die $!;
        my @ids = grep { m/^[A-Z0-9]{4}\z/ } readdir $dh;
        closedir $dh;
        my @allids;
        for my $id (@ids) {
            if (-f "$test_suite_dir/$id/===") {
                push @allids, $id;
                next;
            }
            opendir my $dh, "$test_suite_dir/$id" or die $!;
            my @subids = map { "$id/$_" } grep { m/^[0-9]+\z/ } readdir $dh;
            closedir $dh;
            push @allids, @subids;
        }
        @allids = grep {
            $valid
            ? not -f "$test_suite_dir/$_/error"
            : -f "$test_suite_dir/$_/error"
        } @allids;
        if ($json) {
            @allids = grep {
                -f "$test_suite_dir/$_/in.json"
            } @allids;
        }
        if ($tag) {
            @allids = grep {
                $tag2ids->{ $tag }->{ $_ };
            } @allids;
        }
        push @dirs, map { "$test_suite_dir/$_" } @allids;

    }
    else {
        Test::More::diag("\n############################");
        Test::More::diag("No yaml-test-suite directory");
        Test::More::diag("Using only local tests");
        Test::More::diag("Checkout with: git worktree add test-suite test-suite");
        Test::More::diag("############################");
    }

    @dirs = sort @dirs;
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
    my $skip = $args{skip};

    my @dirs;
    my @todo;

    if ($ENV{TEST_ALL}) {
        @todo = @$skip;
        @$skip = ();
    }

    if (my $dir = $ENV{YAML_TEST_DIR}) {
        @dirs = ($dir);
        @todo = ();
        @$skip = ();
    }
    else {
        @dirs = $self->get_tests();
    }

    my $skipped;
    @$skipped{ @$skip } = (1) x @$skip;

    my %todo;
    @todo{ @todo } = ();

    my @testcases;
    for my $dir (sort @dirs) {
        my $id = basename $dir;
        if ($id =~ m/^\d+$/) {
            $id = (basename dirname $dir) . ':' . $id;
        }

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
            open my $fh, "<:encoding(UTF-8)", "$dir/in.yaml" or die $!;
            $in_yaml = do { local $/; <$fh> };
            close $fh;
        }

        my $linecount = 0;
        if ($self->{linecount} and length $in_yaml) {
            $linecount = () = $in_yaml =~ m/^/mg;
        }

        my $out_yaml;
        if ($self->{out_yaml}) {
            if (-f "$dir/out.yaml") {
                open my $fh, "<:encoding(UTF-8)", "$dir/out.yaml" or die $!;
                $out_yaml = do { local $/; <$fh> };
                close $fh;
            }
            else {
                open my $fh, "<:encoding(UTF-8)", "$dir/in.yaml" or die $!;
                $out_yaml = do { local $/; <$fh> };
                close $fh;
            }
        }

        my $emit_yaml;
        if ($self->{emit_yaml}) {
            my $file = "$dir/emit.yaml";
            unless (-f $file) {
                $file = "$dir/out.yaml";
            }
            unless (-f $file) {
                $file = "$dir/in.yaml";
            }
            open my $fh, "<:encoding(UTF-8)", $file or die $!;
            $emit_yaml = do { local $/; <$fh> };
            close $fh;
        }

        my $in_json;
        if ($self->{in_json}) {
            open my $fh, "<:encoding(UTF-8)", "$dir/in.json" or die $!;
            $in_json = do { local $/; <$fh> };
            close $fh;
        }

        my $todo = exists $todo{ $id };
        my $skip = delete $skipped->{ $id };
        my $test = {
            id => $id,
            dir => dirname($dir),
            title => $title,
            test_events => \@test_events,
            in_yaml => $in_yaml,
            out_yaml => $out_yaml,
            emit_yaml => $emit_yaml,
            in_json => $in_json,
            linecount => $linecount,
            todo => $todo,
            skip => $skip,
        };
        push @testcases, $test;
    }

    if (keys %$skipped) {
        # are there any leftover skips?
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$skipped], ['skipped']);
    }
    $self->{testcases} = \@testcases;
    return (\@testcases);
}

sub run_testcases {
    my ($self, %args) = @_;
    my $testcases = $self->{testcases};
    my $code = $args{code};
    my $stats = $self->{stats};

    unless (@$testcases) {
        ok(1);
        return;
    }

    for my $testcase (@$testcases) {
        my $id = $testcase->{id};
        my $todo = $testcase->{todo};

    #    diag "------------------------------ $id";

        my $result;
        if ($testcase->{skip}) {
            SKIP: {
                push @{ $stats->{SKIP} }, $id;
                skip "SKIP $id", 1;
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

}

sub print_stats {
    my ($self, %args) = @_;
    my $count_fields = $args{count};
    my $list_fields = $args{ids};
    my $stats = $self->{stats};

    my $counts = '';
    for my $field (@$count_fields) {
        my $count = scalar @{ $stats->{ $field } || [] };
        $counts .= "$field: $count ";
    }
    $counts .= "\n";
    diag $counts;

    for my $field (@$list_fields) {
        my $ids = $stats->{ $field } || [];
        diag "$field: (@$ids)" if @$ids;
    }
}

sub parse_events {
    my ($class, $testcase) = @_;

    my @events;
    my $parser = YAML::PP::Parser->new(
        receiver => sub {
            my ($self, $event, $info) = @_;
            push @events, YAML::PP::Common::event_to_test_suite($info, { flow => 1 });
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
    my $stats = $self->{stats};
    my $id = $testcase->{id};
    my $title = $testcase->{title};
    my $err = $result->{err};
    my $yaml = $testcase->{in_yaml};
    my $test_events = $testcase->{test_events};
    my $exp_lines = $testcase->{linecount};

    my @events = @{ $result->{events} };
    $_ = encode_utf8 $_ for @events;

    my $ok = 0;
    if ($err) {
        push @{ $stats->{ERROR} }, $id;
        ok(0, "$id - $title (ERROR)");
    }
    else {
        $ok = is_deeply(\@events, $test_events, "$id - $title");
    }
    if ($ok) {
        push @{ $stats->{OK} }, $id;
        if (defined $exp_lines) {
            my $lines = $result->{line};
            cmp_ok($lines, '==', $exp_lines, "$id - Line count $lines == $exp_lines");
        }
    }
    else {
        push @{ $stats->{DIFF} }, $id unless $err;
        if ($testcase->{todo}) {
            push @{ $stats->{TODO} }, $id;
        }
        if (not $testcase->{todo} or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$yaml" unless $testcase->{todo};
            diag "EVENTS:\n" . join '', map { "$_\n" } @$test_events;
            diag "GOT EVENTS:\n" . join '', map { "$_\n" } @events;
        }
    }
}

sub parse_tokens {
    my ($class, $testcase) = @_;

    my $parser = YAML::PP::Parser->new(
        receiver => sub {
            my ($self, @args) = @_;
        },
    );
    eval {
        $parser->parse_string($testcase->{in_yaml});
    };
    my $err = $@;
    my $tokens = $parser->tokens;
    return {
        err => $err,
        tokens => $tokens,
    };
}

sub compare_tokens {
    my ($self, $testcase, $result) = @_;
    my $id = $testcase->{id};
    my $title = $testcase->{title};
    my $yaml = $testcase->{in_yaml};

    my $all_tokens = $result->{tokens};
    my @yaml_lines = split /(?<=\n)/, $yaml;

    my $error;
    my $ok = 1;
    LINE: for my $i (0 .. $#yaml_lines) {
        my $line_number = $i + 1;
#        diag("============== Line $line_number");
        my $line = $yaml_lines[ $i ];
        my @tokens;
        TOKEN: while (@$all_tokens) {
            my $next = $all_tokens->[0];
            if (my $sub = $next->{subtokens}) {
                shift @$all_tokens;
                unshift @$all_tokens, @$sub;
                next TOKEN;
            }
            if ($next->{line} < $line_number) {
                $error = {
                    token => $next,
                    msg => "Wrong line",
                };
                $ok = 0;
                last LINE;
            }
            last if $next->{line} > $line_number;
            $next = shift @$all_tokens;
            push @tokens, $next;
        }

        my $column = 0;
        while (@tokens) {
            my $token = shift @tokens;
            my $token_column = $token->{column};
            my $value = $token->{value};
            if ($token->{orig}) {
                $value = $token->{orig};
            }
            unless ($token->{column} == $column) {
                $ok = 0;
                $error = {
                    token => $token,
                    msg => "Wrong column",
                };
                last LINE;
            }
            unless ($line =~ s/^\Q$value//) {
                $ok = 0;
                $error = {
                    token => $token,
                    msg => "Token does not match YAML",
                };
                last LINE;
            }
            $column += length($value);
        }
        if (length $line) {
            $ok = 0;
            $error = {
                msg => "Line is longer than tokens",
            };
        }

    }

    if (@$all_tokens) {
        $ok = 0;
        $error = {
            msg => "More tokens than YAML lines",
        };
    }
    unless ($ok) {
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([$error], ['error']);
        diag($yaml);
    }
    ok($ok, "$id - Tokens match YAML");
}

sub compare_invalid_parse_events {
    my ($self, $testcase, $result) = @_;
    my $stats = $self->{stats};
    my $id = $testcase->{id};
    my $title = $testcase->{title};
    my $err = $result->{err};
    my $yaml = $testcase->{in_yaml};
    my $test_events = $testcase->{test_events};

    my $ok = 0;
    if (not $err) {
        push @{ $stats->{OK} }, $id;
        ok(0, "$id - $title - should be invalid");
    }
    else {
        push @{ $stats->{ERROR} }, $id;
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
        push @{ $stats->{DIFF} }, $id;
        if ($testcase->{todo}) {
            push @{ $stats->{TODO} }, $id;
        }
        if (not $testcase->{todo} or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$yaml" unless $testcase->{todo};
            diag "EVENTS:\n" . join '', map { "$_\n" } @$test_events;
            diag "GOT EVENTS:\n" . join '', map { "$_\n" } @{ $result->{events} };
        }
    }
}

sub load_json {
    my ($self, $testcase) = @_;

    my $ypp = YAML::PP->new(boolean => 'JSON::PP', schema => [qw/ Core Catchall /]);
    my @docs = eval { $ypp->load_string($testcase->{in_yaml}) };

    my $err = $@;
    return {
        data => \@docs,
        err => $err,
    };
}

sub compare_load_json {
    my ($self, $testcase, $result) = @_;
    my $stats = $self->{stats};
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
        push @{ $stats->{ERROR} }, $id;
        ok(0, "$id - $title - ERROR");
    }
    else {
        $ok = cmp_ok($json, 'eq', $exp_json, "$id - load -> JSON equals expected JSON");
        if ($ok) {
            push @{ $stats->{OK} }, $id;
        }
        else {
            push @{ $stats->{DIFF} }, $id;
        }
    }

    unless ($ok) {
        if ($testcase->{todo}) {
            push @{ $stats->{TODO} }, $id;
        }
        if (not $testcase->{todo} or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$yaml" unless $testcase->{todo};
            diag "JSON:\n" . $exp_json;
            diag "GOT JSON:\n" . $json;
        }
    }
}

sub dump_yaml {
    my ($self, $testcase) = @_;
    my $id = $testcase->{id};

    my $ypp = YAML::PP->new( boolean => 'JSON::PP', duplicate_keys => 1, schema => [qw/ + Catchall /] );
    my @docs = eval { $ypp->load_string($testcase->{in_yaml}) };
    my $err = $@;
    my $result = {};
    if ($err) {
        diag "ERROR loading $id";
        $result->{err} = $err;
        return $result;
    }

    my $out_yaml;
    eval {
        $out_yaml = $ypp->dump_string(@docs);
    };
    $err = $@;
    if ($err) {
        diag "ERROR dumping $id";
        $result->{err} = $err;
        return $result;
    }
    $result->{dump_yaml} = $out_yaml;


    my @reload = eval { $ypp->load_string($out_yaml) };
    $err = $@;
    if ($err) {
        diag "ERROR reloading $id";
        $result->{err} = $err;
        return $result;
    }
    $result->{data} = \@docs;
    $result->{data_reload} = \@reload;

    my $exp_out_yaml = $testcase->{out_yaml};
    my @events;
    my @reparse_events;
    my $parser = YAML::PP::Parser->new(
        receiver => sub {
            my ($self, $event, $info) = @_;
            push @events, YAML::PP::Common::event_to_test_suite($info, { flow => 0 });
        },
    );
    eval {
        $parser->parse_string($out_yaml);
    };
    $err = $@;
    if ($err) {
        diag "ERROR parsing $id\n$err";
        $result->{err} = $err;
        return $result;
    }
    @reparse_events = @events;
    @events = ();
    my @exp_events;
    eval {
        $parser->parse_string($testcase->{out_yaml});
    };
    $err = $@;
    @exp_events = @events;
    $result->{dump_events} = \@reparse_events;
    $result->{expected_events} = \@exp_events;

    return $result;
}

sub compare_dump_yaml {
    my ($self, $testcase, $result) = @_;
    my $stats = $self->{stats};
    my $id = $testcase->{id};
    my $title = $testcase->{title};
    my $err = $result->{err};
    my $yaml = $testcase->{in_yaml};
    my $out_yaml = $testcase->{out_yaml};
    my $docs = $result->{data};
    my $reload_docs = $result->{data_reload};
    my $dump_yaml = $result->{dump_yaml};
    my $dump_events = $result->{dump_events};
    my $exp_events = $result->{expected_events};

    my $ok = 0;
    if ($err) {
        push @{ $stats->{ERROR} }, $id;
        ok(0, "$id - $title - ERROR");
    }
    else {
        $ok = is_deeply($reload_docs, $docs, "$id - $title - Reload data equals original");
        push @{ $stats->{DIFF} }, $id unless $ok;
    }

    if ($ok) {
        push @{ $stats->{OK} }, $id;
    }
    else {
        if ($testcase->{todo}) {
            push @{ $stats->{TODO} }, $id;
        }
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$docs], ['docs']);
        if (not $testcase->{todo} or $ENV{YAML_PP_TRACE}) {
            diag "YAML:\n$out_yaml" unless $testcase->{todo};
            diag "OUT YAML:\n$out_yaml" unless $testcase->{todo};
            my $reload_dump = Data::Dumper->Dump([$reload_docs], ['reload_docs']);
            diag "RELOAD DATA:\n$reload_dump" unless $testcase->{todo};
        }
    }

# TODO
#    my $same_events = is_deeply($dump_events, $exp_events, "$id - $title - Events from re-parsing are the same");
}

sub emit_yaml {
    my ($self, $testcase, $args) = @_;
    my $flow = $args->{flow} ||= 'no';
    my $indent = $args->{indent} ||= 2;
    my $id = $testcase->{id};
    my $exp_yaml = $testcase->{emit_yaml};

    my $result;
    eval {
        # Emitter tests consume the corpus event stream. Parser conformance
        # is checked independently by t/10.parse-valid.t.
        my $input = [map {
            my $info = YAML::PP::Common::test_suite_to_event(decode_utf8($_));
            [$info->{name}, $info];
        } @{ $testcase->{test_events} }];
        die 'Missing input event fixture' unless @$input;
        my $reference = eval { $self->_parse_emit_events($exp_yaml) };
        my $reference_error = $@;
        # Some valid references need a parser fix on a separate PR. Their
        # event fixture still permits an independent, exact emitter check.
        $reference ||= $input;
        my $presentation = $args->{presentation} || '';
        my $events = $presentation eq 'reference' ? $reference : $input;
        my $emit_yaml = $self->_emit_events($events, $args);
        my $emitted = eval { $self->_parse_emit_events($emit_yaml) };
        my $output_error = $@;
        if (!$emitted and ($presentation ne 'reference'
            or $emit_yaml ne $exp_yaml)) {
            die $output_error;
        }
        my $expected = $flow eq 'no' ? $reference : $input;
        my @containers;
        my @expected = map {
            my %info = %{ $_->[1] };
            if ($flow eq 'yes') {
                if ($info{name} =~ /^(sequence|mapping)_start_event$/) {
                    push @containers, $1;
                }
                elsif ($info{name} =~ /^(sequence|mapping)_end_event$/) {
                    pop @containers;
                }
                elsif ($info{name} eq 'scalar_event' and @containers
                    and $containers[-1] eq 'sequence'
                    and $info{style} == YAML_PLAIN_SCALAR_STYLE
                    and $info{value} eq '' and not defined $info{anchor}
                    and not defined $info{tag}) {
                    $info{value} = 'null';
                }
                $info{style} = YAML_FLOW_SEQUENCE_STYLE
                    if $info{name} eq 'sequence_start_event';
                $info{style} = YAML_FLOW_MAPPING_STYLE
                    if $info{name} eq 'mapping_start_event';
                $info{style} = YAML_PLAIN_SCALAR_STYLE
                    if $info{name} eq 'scalar_event';
            }
            YAML::PP::Common::event_to_test_suite(\%info, {flow => 1});
        } @$expected;
        my @got = map {
            my %info = %{ $_->[1] };
            $info{style} = YAML_PLAIN_SCALAR_STYLE
                if $flow eq 'yes' and $info{name} eq 'scalar_event';
            YAML::PP::Common::event_to_test_suite(\%info, {flow => 1});
        } @{ $emitted || [] };
        $result = {
            expected_events => \@expected,
            reparse_events => \@got,
            input_data => $self->_construct_emit_events($input),
            reference_data => $self->_construct_emit_events($reference),
            input_properties => $self->_emit_event_properties($input),
            reference_properties => $self->_emit_event_properties($reference),
            output_data => $emitted
                ? $self->_construct_emit_events($emitted) : undef,
            output_properties => $emitted
                ? $self->_emit_event_properties($emitted) : undef,
            exact_reference_only => !$emitted,
            reference_matched => $emit_yaml eq $exp_yaml,
            reference_parser_error => $reference_error,
        };
        $result->{emit_yaml} = $emit_yaml if $flow eq 'no';
    };
    if (my $err = $@) {
        return {err => $err};
    }
    return $result;
}

sub _parse_emit_events {
    my ($self, $yaml) = @_;
    my @events;
    my $parser = YAML::PP::Parser->new(receiver => sub {
        my ($parser, $name, $info) = @_;
        push @events, [$name, {%$info}];
    });
    $parser->parse_string($yaml);
    return \@events;
}

sub _construct_emit_events {
    my ($self, $events) = @_;
    my $yp = YAML::PP->new(schema => ['Core', 'Catchall'],
        cyclic_refs => 'allow', duplicate_keys => 1);
    my $constructor = $yp->loader->constructor;
    for my $event (@$events) {
        my ($name, $info) = @$event;
        my %copy = %$info;
        delete $copy{version_directive};
        $constructor->$name(\%copy);
    }
    return $constructor->docs;
}

sub _emit_event_properties {
    my ($self, $events) = @_;
    return [map {
        my $info = $_->[1];
        my %properties = (name => $info->{name});
        for my $key ('anchor', 'tag') {
            $properties{$key} = $info->{$key} if defined $info->{$key};
        }
        $properties{value} = $info->{value}
            if $info->{name} eq 'alias_event';
        \%properties;
    } grep { $_->[0] !~ /^(?:stream|document)_/ } @$events];
}

sub _emit_events {
    my ($testsuite, $events, $args) = @_;
    my $indent = $args->{indent} ||= 2;
    my $writer = YAML::PP::Writer->new;
    my $emitter = YAML::PP::Emitter->new( indent => $indent );
    $emitter->set_writer($writer);
    $emitter->init;
    for my $event (@$events) {
        my ($type, $original) = @$event;
        my $info = {%$original};
        delete $info->{version_directive};
        if ($type eq 'sequence_start_event' or $type eq 'mapping_start_event') {
            if ($args->{flow} eq 'no'
                and ($args->{presentation} || '') ne 'reference') {
                delete $info->{style};
            }
            elsif ($args->{flow} eq 'keep') {
                delete $info->{style} if $args->{flow} eq 'no';
            }
            elsif ($args->{flow} eq 'yes') {
                if ($type eq 'sequence_start_event') {
                    $info->{style} = YAML_FLOW_SEQUENCE_STYLE;
                }
                else {
                    $info->{style} = YAML_FLOW_MAPPING_STYLE;
                }
            }
        }
        $emitter->$type($info);
    }
    my $yaml = $emitter->writer->output;
    return $yaml;
}

sub compare_emit_yaml {
    my ($self, $testcase, $result) = @_;
    my $stats = $self->{stats};
    my $id = $testcase->{id};
    my $title = $testcase->{title};
    my $err = $result->{err};
    my $yaml = $testcase->{in_yaml};
    my $exp_emit_yaml = $testcase->{emit_yaml};
    my $emit_yaml = $result->{emit_yaml};
    my $exp_events = $result->{expected_events};
    my $reparse_events = $result->{reparse_events};

    if ($err) {
        diag "$id: $err" unless $testcase->{todo};
        push @{ $stats->{ERROR} }, $id;
        ok(0, "$id - $title - ERROR");
        return;
    }
    my $same_reference = is_deeply($result->{reference_data},
        $result->{input_data}, "$id - Reference preserves input values/types");
    unless ($same_reference) {
        push @{ $stats->{DIFF_EVENTS} }, $id;
        return;
    }
    my $same_reference_properties = is_deeply($result->{reference_properties},
        $result->{input_properties}, "$id - Reference preserves tags/anchors");
    unless ($same_reference_properties) {
        push @{ $stats->{DIFF_EVENTS} }, $id;
        return;
    }
    if ($result->{exact_reference_only}) {
        my $same_yaml = ok($result->{reference_matched},
            "$id - Exact reference output (parser fix is on a separate PR)");
        push @{ $stats->{$same_yaml ? 'SAME_YAML' : 'DIFF_YAML'} }, $id;
        return;
    }
    my $same_data = is_deeply($result->{output_data}, $result->{input_data},
        "$id - Emission preserves input values/types");
    unless ($same_data) {
        push @{ $stats->{DIFF_EVENTS} }, $id;
        return;
    }
    my $same_properties = is_deeply($result->{output_properties},
        $result->{input_properties}, "$id - Emission preserves tags/anchors");
    unless ($same_properties) {
        push @{ $stats->{DIFF_EVENTS} }, $id;
        return;
    }
    $_ = encode_utf8 $_ for (@$reparse_events, @$exp_events);
    my $same_events = is_deeply($reparse_events, $exp_events, "$id - $title - Events from re-parsing are the same");
    if ($same_events) {
        push @{ $stats->{SAME_EVENTS} }, $id;
        if (defined $emit_yaml) {
            $_ = encode_utf8 $_ for ($emit_yaml, $exp_emit_yaml);
            my $same_yaml = cmp_ok($emit_yaml, 'eq', $exp_emit_yaml, "$id - $title - Emit events");
            if ($same_yaml) {
                push @{ $stats->{SAME_YAML} }, $id;
            }
            else {
                local $Data::Dumper::Useqq = 1;
                diag('    ' . Data::Dumper->Dump([$emit_yaml], ['emit_yaml']));
                diag(Data::Dumper->Dump([$exp_emit_yaml], ['exp_emit_yaml']));
                push @{ $stats->{DIFF_YAML} }, $id;
            }
        }
    }
    else {
        push @{ $stats->{DIFF_EVENTS} }, $id;
    }
}

1;
