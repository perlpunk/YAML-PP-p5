#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Data::Dumper;
use YAML::PP::Parser;

$|++;

my $datadir = "$Bin/../yaml-test-suite";
opendir my $dh, $datadir or die $!;
my @dirs = grep { m/^[A-Z0-9]{4}\z/ } readdir $dh;
closedir $dh;

@dirs = sort @dirs;

my @check = qw/
    27NA
    K527
    W4TN
    TS54
    DWX9
    7T8X
    RTP8
    HS5T
    M7A3
    M9B4
    MJS9
    6ZKB
    UT92
    NHX8
/;
my @skip = qw/




    A984
    5NYZ

/;

my @multiline = qw/
    5BVJ
    5GBF
    6VJK
    9FMG
    9YRD
    A6F9
    F8F9
    H2RW
    K858
    NP9H
    P2AD
    P94K
    M5C3
    M29M
/;
my @quoted = qw/
    4CQQ
    4GC6
    4UYU
    7A4E
    9SHH
    G4RS
    J3BT
    PRH3
    MZX3
    TL85
    4ZYM
/;

my @flow = qw/
    4ABK
    54T7
    5KJE
    8UDB
    C2DT
    D88J
    DFF7
    DHP8
    FRK4
    FUP4
    KZN9
    CT4Q
    L9U5
    LP6E
    LQZ7
    Q88A
    Q9WF
    QF4Y
    SBG9
    UDR7
    ZF4X
    87E4
    WZ62
    N782
/;
my @seq = qw/
    5C5M
    3ALJ
    65WH
    6JWB
    735Y
    7BUB
    8QBE
    93JH
    9U5K
    AZ63
    FQ7F
    J9HZ
    JQ4R
    K4SU
    MXS3
    PBJ2
    S4JQ
    RLU9
    R4YG
    6BCT
    JHB9
    S3PD
    W42U
    YD5X
    229Q
    AZW3
/;
my @sets = qw/
    2XXW
/;
my @tags = qw/
    2AUY
    57H4
    74H7
    77H8
    7FWL
    8MK2
    F2C7
    FH7J
    J7PZ
    LE5A
    5TYM
    C4HZ
    CC74
    P76L
    U3C3
    Z9M4
    9WXW
    6CK3
    EHF6
/;
my @todo = qw/
/;
my @misc = qw/
    DBG4
    6HB6
    RZT7
    UGM3
    6LVF
    BEC7
/;
my @done = qw/
    KMK3
/;
my @anchors = qw/
    ZH7C X38W V55R HMQ5 CUP7 BP6S 6M2F
    2SXE
    3GZX
    E76Z
    JS2J
    PW8X
/;
my @keymap = qw/
    V9D5
    35KP
    7W2P
    8KHE
    A2M4
    GH63
    JTV5
    RR7F
    5WE3
    M5DY
    S9E8
    L94M
/;
push @skip,
    @check, @anchors, @keymap, @tags, @misc, @sets, @seq, @flow, @quoted,
    @multiline;

#@skip = ();

if (my $dir = $ENV{YAML_TEST_DIR}) {
    @dirs = ($dir);
    @todo = ();
}
my %skip;
@skip{ @skip } = ();
my %todo;
@todo{ @todo } = ();

plan tests => scalar @dirs;

for my $dir (@dirs) {
    diag "\n------------------------------ $dir";
    open my $fh, "<", "$datadir/$dir/in.yaml" or die $!;
    my $yaml = do { local $/; <$fh> };
    close $fh;
    open $fh, "<", "$datadir/$dir/test.event" or die $!;
    chomp(my @test_events = <$fh>);
    close $fh;
    my $skip = exists $skip{ $dir };
    my $todo = exists $todo{ $dir };

    if ($skip) {
        SKIP: {
            skip "SKIP $dir", 1 if $skip;
            test($dir, $yaml, \@test_events);
        }
    }
    elsif ($todo) {
        TODO: {
            local $TODO = $todo;
            test($dir, $yaml, \@test_events);
        }
    }
    else {
        test($dir, $yaml, \@test_events);
    }

}
my $skipped = @skip;
diag "Skipped $skipped tests";

sub test {
    my ($name, $yaml, $test_events) = @_;
#    @$test_events = grep { m/DOC|STR/ } @$test_events;
    my @events;
    my $parser = YAML::PP::Parser->new(
        cb => sub {
            my ($self, $event, $content) = @_;
            no warnings 'uninitialized';
            $ENV{YAML_PP_TRACE} and
                warn __PACKAGE__.':'.__LINE__.": ----------------> EVENT $event $content\n";
            push @events, defined $content ? "$event $content" : $event;
        },
    );
    $parser->parse($yaml);
    my @squashed;
    for (my $i = 0; $i < @events; $i++) {
        my $event = $events[ $i ];
        if ($event =~ m/^=VAL /) {
            next;
        }

        push @squashed, $event;
    }

#    @events = @squashed;
    my $ok = is_deeply(\@events, $test_events, "$name");
    if (not $ok and not $TODO or $ENV{YAML_PP_TRACE}) {
        diag "YAML:\n$yaml" unless $TODO;
        diag "EVENTS:\n" . join '', map { "$_\n" } @$test_events;
        diag "GOT EVENTS:\n" . join '', map { "$_\n" } @events;
    }
}

done_testing;
