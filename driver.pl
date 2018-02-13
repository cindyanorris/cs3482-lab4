#!/usr/bin/perl
#######################################################################
# driver.pl - Tool Lab driver
#
# This code calculates the score on the tool lab, -u <name> 
#   option to submit to scoreboard
#######################################################################
use strict 'vars';
use Getopt::Std;
use IO::Socket::INET;

# Generic settings 
$| = 1;      # Flush stdout each time, also on socket
umask(0077); # Files created by the user in tmp readable only by that user
$ENV{PATH} = "/usr/local/bin:/usr/bin:/bin";

##############
# Main routine
##############
my $login = (getpwuid($<))[0] || "unknown";
my $tmpdir = "/var/tmp/toollab.$login.$$";
my $diemsg = "The files are in $tmpdir.";
my $infile = "ngram";
my $inputDir = "/u/csd/can/classes/3482/spring18/Labs/toollab/Inputs/";
my $short = $inputDir."short";
my $shakespeare = $inputDir."shakespeare9000Lines";

################################################
# Compute the correctness and performance scores
################################################
#

system("mkdir $tmpdir") == 0
    or die "$0: Could not make scratch directory $tmpdir.\n";

system("make clean; make V1") == 0
    or die "$0: Could not execute make utility.\n";

(-e "./ngram" and -x "./ngram")
    or  die "$0: ERROR: No executable ngram for 'make V1'.\n";

unless (system("cp ngram $tmpdir/ngramV1") == 0) { 
    clean($tmpdir);
    die "$0: Could not copy 'V1' ngram to scratch directory $tmpdir.\n";
}

system("make clean; make V2") == 0
    or die "$0: Could not execute make utility.\n";

(-e "./ngram" and -x "./ngram")
    or  die "$0: ERROR: No executable ngram for 'make V2'.\n";

unless (system("cp ngram $tmpdir/ngramV2") == 0) { 
    clean($tmpdir);
    die "$0: Could not copy 'V2' ngram to scratch directory $tmpdir.\n";
}

(-e "$shakespeare")
    or  die "$0: ERROR: No $shakespeare, which is needed to check for correctness .\n";

(-e "$short")
    or  die "$0: ERROR: No $short, which is needed to check for memory leaks.\n";

print "\nCreate a version of ngram with -pg compiler option.\n";
system("make clean; make PFLAG='-pg' V1") == 0
    or die "$0: Could not execute make utility.\n";

unless (system("cp ngram $tmpdir/ngramV1p") == 0) { 
    clean($tmpdir);
    die "$0: Could not copy 'profiling' ngram to scratch directory $tmpdir.\n";
}

system("make clean; make PFLAG='-pg' V2") == 0
    or die "$0: Could not execute make utility.\n";

unless (system("cp ngram $tmpdir/ngramV2p") == 0) { 
    clean($tmpdir);
    die "$0: Could not copy 'profiling' ngram to scratch directory $tmpdir.\n";
}

# Copy the input files to the scratch directory
unless (system("cp $shakespeare $tmpdir") == 0) {
    clean($tmpdir);
    die "$0: Could not copy file $shakespeare to scratch directory $tmpdir.\n";
}

unless (system("cp $short $tmpdir") == 0) {
    clean($tmpdir);
    die "$0: Could not copy file $short to scratch directory $tmpdir.\n";
}

# Copy the checker to the scratch directory
unless (system("cp ./ngramcheck.sh $tmpdir") == 0) { 
    clean($tmpdir);
    die "$0: Could not copy file ngramcheck.sh to scratch directory $tmpdir.\n";
}

# Change the current working directory to the scratch directory
unless (chdir($tmpdir)) {
    clean($tmpdir);
    die "$0: Could not change directory to $tmpdir.\n";
}

#
# Run the tests
#
print "\n1. Running valgrind with 'V1' ngram and short to check for memory errors.\n";
system("cp $tmpdir/ngramV1 $tmpdir/ngram");
system("valgrind --tool=memcheck --leak-check=full $tmpdir/ngram $tmpdir/short >& $tmpdir/valgrind.output"); 
open(my $fh, "$tmpdir/valgrind.output") or 
die("Unable to open $tmpdir/valgrind.output");
my @lines = <$fh>;
my $last  = pop (@lines);
close $fh;
my $V1errors = $1 if (($last =~ /ERROR SUMMARY: (\d+) errors/));

print "2. Running 'V1' ngram on shakespeare9000Lines to check for correctness.\n";
system("cp $tmpdir/ngramV1 $tmpdir/ngram");
system("$tmpdir/ngramcheck.sh > $tmpdir/ngramcheck.output"); 
open(my $fh, "$tmpdir/ngramcheck.output") or 
die("Unable to open $tmpdir/ngramcheck.output");
my @lines = <$fh>;
my $last  = pop (@lines);
close $fh;
my $V1correct = "no";
$V1correct = "yes" if ($last =~ /Test passed/);

print "3. Running gprof with 'V1' ngram to collect timing.\n";
system("$tmpdir/ngramV1p  $shakespeare > $tmpdir/ngramV1p.output"); 
system("gprof $tmpdir/ngramV1p > $tmpdir/gprofV1.output"); 
open(my $fh, "$tmpdir/gprofV1.output") or 
die("Unable to open $tmpdir/gprofV1.output");
my @lines = <$fh>;
my $V1seconds = "1000.0";
foreach (@lines)
{
   $V1seconds = $1 if /^granularity: .+ of (.+) seconds$/;
}
close $fh;

print "4. Running valgrind with 'V2' ngram and short to check for memory errors.\n";
system("cp $tmpdir/ngramV2 $tmpdir/ngram");
system("valgrind --tool=memcheck --leak-check=full $tmpdir/ngram $tmpdir/short >& $tmpdir/valgrind.output"); 
open(my $fh, "$tmpdir/valgrind.output") or 
die("Unable to open $tmpdir/valgrind.output");
my @lines = <$fh>;
my $last  = pop (@lines);
close $fh;
my $V2errors = $1 if (($last =~ /ERROR SUMMARY: (\d+) errors/));

print "5. Running 'V2' ngram on shakespeare9000Lines to check for correctness.\n";
system("cp $tmpdir/ngramV2 $tmpdir/ngram");
system("$tmpdir/ngramcheck.sh > $tmpdir/ngramcheck.output"); 
open(my $fh, "$tmpdir/ngramcheck.output") or 
die("Unable to open $tmpdir/ngramcheck.output");
my @lines = <$fh>;
my $last  = pop (@lines);
close $fh;
my $V2correct = "no";
$V2correct = "yes" if ($last =~ /Test passed/);

print "6. Running gprof with 'V2' ngram to collect timing.\n";
system("$tmpdir/ngramV2p  $shakespeare > $tmpdir/ngramV2p.output"); 
system("gprof $tmpdir/ngramV2p > $tmpdir/gprofV2.output"); 
open(my $fh, "$tmpdir/gprofV2.output") or 
die("Unable to open $tmpdir/gprofV2.output");
my @lines = <$fh>;
my $V2seconds = "1000.0";
foreach (@lines)
{
   $V2seconds = $1 if /^granularity: .+ of (.+) seconds$/;
}
close $fh;

#calculate score
my $score = 0;

if ($V1correct eq "yes" and $V1seconds < 0.5)
{
   $score = 45;
} elsif ($V1correct eq "yes" and $V1seconds < 1.0)
{
   $score = 40;
} elsif ($V1correct eq "yes" and $V1seconds < 1.5)
{
   $score = 35;
} elsif ($V1correct eq "yes" and $V1seconds < 2.0)
{
   $score = 30;
} elsif ($V1correct eq "yes")
{
   $score = 25;
}

if ($V2correct eq "yes" and $V2seconds < 0.5)
{
   $score = $score + 45;
} elsif ($V2correct eq "yes" and $V2seconds < 1.0)
{
   $score = $score + 40;
} elsif ($V2correct eq "yes" and $V2seconds < 1.5)
{
   $score = $score + 35;
} elsif ($V2correct eq "yes" and $V2seconds < 2.0)
{
   $score = $score + 30;
} elsif ($V2correct eq "yes")
{
   $score = $score + 25;
}

if ($V1errors == "0") { $score = $score + 5; }
if ($V2errors == "0") { $score = $score + 5; }


# 
# Output results

print "\n";
printf("Version 1\n");
printf("%15s\t%15s\t%15s\t%15s\n", "Correct Output?", "Memory Errors", 
                             "Time (seconds)");
printf("%15s\t%15s\t%15s\t%15d\n", $V1correct, $V1errors, 
                                   $V1seconds);
printf("\nVersion 2\n");
printf("%15s\t%15s\t%15s\t%15s\n", "Correct Output?", "Memory Errors", 
                             "Time (seconds)");
printf("%15s\t%15s\t%15s\t%15d\n", $V2correct, $V2errors, 
                                   $V2seconds) ;

print "\n";

printf("\nSCORE: %d\n", $score);

#
# Update the scoreboard if asked
#
if ($ARGV[0] eq "-u") {
    my $name = $ARGV[1];
    # send the name and seconds to the scoreboard
    my $seconds = $V1seconds;
    if ($V2seconds < $seconds) { $seconds = $V2seconds; }
    send_score_to_server($name, $seconds);
}

# Clean up and exit
clean ($tmpdir);
exit;

##################
# Helper functions
#
#
# clean - remove the scratch directory
#
# send_score_to_server - creates the socket and parses the data
#   so the server correctly parses it
#
sub clean {
    my $tmpdir = shift;
    system("rm -rf $tmpdir");
}

sub send_score_to_server {

    my ($name, $seconds) = @_; 
    
    my $socket = new IO::Socket::INET (
	PeerHost => 'localhost',
	PeerPort => '15006',
	Proto => 'tcp'
	);
    die "cannot connect to the server $!\n" unless $socket;
    # print "connected to the server\n";
    
    # data to send to a server
    my $req = "$name,$seconds";
    my $size = $socket->send($req);
    # print "sent data of length $size\n";
    
    # notify server that request has been sent
    shutdown($socket, 1);
    
    # receive a response of up to 1024 characters from server
    my $response = "";
    $socket->recv($response, 32);
    print "$response";
    
    $socket->close();   
}
