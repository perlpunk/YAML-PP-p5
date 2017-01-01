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

if (my $dir = $ENV{YAML_TEST_DIR}) {
    @dirs = ($dir);
}
@dirs = sort @dirs;

my @skip = qw/
    EHF6 6CK3 9WXW Z9M4 U3C3
    P76L N782 CC74 C4HZ BEC7 6ZKB 6LVF 5TYM
/;
my @check = qw/
    27NA
/;
my @todo = qw/
    87E4
/;
push @todo, @check;

my %skip;
@skip{ @skip } = ();
my %todo;
@todo{ @todo } = ();

plan tests => scalar @dirs;

for my $dir (@dirs) {
    diag "\n------------------------------ $dir\n";
    open my $fh, "<", "$datadir/$dir/in.yaml" or die $!;
    my $yaml = do { local $/; <$fh> };
    close $fh;
    open $fh, "<", "$datadir/$dir/test.event" or die $!;
    chomp(my @test_events = <$fh>);
    close $fh;
    my $skip = exists $skip{ $dir };
    my $todo = exists $todo{ $dir };

    TODO: {
        local $TODO = $todo;
        SKIP: {
            skip "SKIP $dir", 1 if $skip;
            test($dir, $yaml, \@test_events);
        }
    }
}

sub test {
    my ($name, $yaml, $test_events) = @_;
    diag "YAML:\n$yaml";
    @$test_events = grep { m/DOC|STR/ } @$test_events;
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

#        if ($event =~ m/^\+DOC /) {
#            warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$event], ['event']);
#            warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$i], ['i']);
#            warn __PACKAGE__.':'.__LINE__.": !!! $#events\n";
#            if ($i < $#events and $events[ $i + 1 ] =~ m/^-DOC/) {
#            warn __PACKAGE__.':'.__LINE__.": !!!!! $events[ $i + 1 ]\n";
#                $i += 1;
#                next;
#            }
#        }
        push @squashed, $event;
    }

#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@squashed], ['squashed']);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@events], ['events']);
    @events = @squashed;
    my $ok = is_deeply(\@events, $test_events, "$name");
    unless ($ok) {
        diag "EVENTS:\n" . join '', map { "$_\n" } @$test_events;
        diag "GOT EVENTS:\n" . join '', map { "$_\n" } @events;
    }
}

done_testing;
