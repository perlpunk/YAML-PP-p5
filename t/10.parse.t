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
/;
my @skip = qw/
    EHF6 6CK3 9WXW Z9M4 U3C3
    P76L N782 CC74 C4HZ BEC7 6ZKB 6LVF 5TYM
    WZ62 UGM3 LE5A L94M


    87E4 ZF4X UT92 YD5X W42U UDR7 U9NS TL85
    TE2A SYW4 SBG9 S9E8 S3PD RZT7 QF4Y Q9WF
    Q88A PW8X NHX8 MZX3 M5DY M5C3 M29M LQZ7
    LP6E L9U5 JS2J JHB9 J7PZ CT4Q 6HB6 6BCT
    5WE3

    S4T7 RR7F R4YG RLU9 S4JQ
    PRH3 PBJ2 P94K P2AD NP9H
    MXS3 KZN9 K858 K4SU JTV5
    JQ4R J9HZ J7VC J5UC J3BT
    HMK4 H2RW GH63 G4RS FUP4
    FRK4 FQ7F FH7J F8F9 F2C7
    E76Z DHP8 DFF7 DBG4 D88J
    AZ63 A984 A2M4 C2DT AZW3
    A6F9 9YRD 9U5K 9SHH 9J7A
    9FMG 93JH 8UDB 8QBE 8MK2
    8KHE 7W2P 7FWL 7BUB 7A4E
    77H8 74H7 735Y 6VJK 6JWB
    65WH 5NYZ 5KJE 5GBF 5BVJ
    57H4 54T7 4ZYM 4UYU 4GC6
    4CQQ 4ABK 3GZX 3ALJ 5C5M
    35KP 2XXW 2SXE 2JQS 2AUY
    229Q

    8G76

    98YD

    MYW6 MJS9 M9B4
    M7A3 KMK3 HS5T D9TU

/;
my @todo = qw/

    RTP8
    7T8X

/;
my @done = qw/
    6FWR
/;
my @anchors = qw/
    ZH7C X38W V55R HMQ5 CUP7 BP6S 6M2F
/;
my @keymap = qw/
    V9D5
/;
push @skip, @check, @anchors, @keymap;

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

sub test {
    my ($name, $yaml, $test_events) = @_;
#    @$test_events = grep { m/DOC|STR/ } @$test_events;
    my @events;
    my $parser = YAML::PP::Parser->new(
        cb => sub {
            my ($self, $event, $content) = @_;
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
