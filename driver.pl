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
print "\nCreate a version of ngram without -pg compiler option.\n";
system("make clean; make ") == 0
    or die "$0: Could not execute make utility.\n";

system("mkdir $tmpdir") == 0
    or die "$0: Could not make scratch directory $tmpdir.\n";

(-e "./ngram" and -x "./ngram")
    or  die "$0: ERROR: No executable ngram binary.\n";

(-e "$shakespeare")
    or  die "$0: ERROR: No $shakespeare, which is needed to check for correctness .\n";

(-e "$short")
    or  die "$0: ERROR: No $short, which is needed to check for memory leaks.\n";

# Copy the student's work to the scratch directory
unless (system("cp ngram $tmpdir/ngram") == 0) { 
    clean($tmpdir);
    die "$0: Could not copy file ngram to scratch directory $tmpdir.\n";
}

print "\nCreate a version of ngram with -pg compiler option.\n";
system("make clean; make PFLAG='-pg'") == 0
    or die "$0: Could not execute make utility.\n";

# Copy the student's work to the scratch directory
unless (system("mv ngram $tmpdir/ngramp") == 0) { 
    clean($tmpdir);
    die "$0: Could not copy file ngram to scratch directory $tmpdir.\n";
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
print "\n1. Running valgrind to check for memory errors.\n";
system("valgrind --tool=memcheck --leak-check=full $tmpdir/ngram $tmpdir/short >& $tmpdir/valgrind.output"); 

open(my $fh, "$tmpdir/valgrind.output") or 
die("Unable to open $tmpdir/valgrind.output");
my @lines = <$fh>;
my $last  = pop (@lines);
close $fh;
my $errors = $1 if (($last =~ /ERROR SUMMARY: (\d+) errors/));

print "2. Running ngram on shakespeare9000Lines to check for correctness.\n";
system("$tmpdir/ngramcheck.sh > $tmpdir/ngramcheck.output"); 
open(my $fh, "$tmpdir/ngramcheck.output") or 
die("Unable to open $tmpdir/ngramcheck.output");
my @lines = <$fh>;
my $last  = pop (@lines);
close $fh;
my $correct = "no";
$correct = "yes" if ($last =~ /Test passed/);

print "3. Running gprof to collect timing.\n";
system("$tmpdir/ngramp  $tmpdir/shakespeare9000Lines > $tmpdir/ngramp.output"); 
system("gprof $tmpdir/ngramp > $tmpdir/gprof.output"); 
open(my $fh, "$tmpdir/gprof.output") or 
die("Unable to open $tmpdir/gprof.output");
my @lines = <$fh>;
my $seconds = "1000.0";
foreach (@lines)
{
   $seconds = $1 if /^granularity: .+ of (.+) seconds$/;
}
close $fh;

#calculate score
my $score = 0;

if ($seconds < 0.5)
{
   $score = 85;
} elsif ($seconds < 1.0)
{
   $score = 75;
} elsif ($seconds < 1.5)
{
   $score = 65;
} elsif ($seconds < 2.0)
{
   $score = 55;
} elsif ($seconds < 2.5)
{
   $score = 45;
} elsif ($seconds < 3.0)
{
   $score = 35;
} elsif ($seconds < 3.5)
{
   $score = 25;
} elsif ($seconds < 4.0)
{
   $score = 15;
} else
{
   $score = 5;
}

if ($errors == "0") { $score = $score + 15; }
if ($correct eq "no") { $score = 0; }


# 
# Print a table of results sorted by puzzle number
#

print "\n";
printf("%15s\t%15s\t%15s\t%15s\n", "Correct Output?", "Memory Errors", 
                             "Time (seconds)", "Score");
printf("%15s\t%15s\t%15s\t%15d\n", $correct, $errors, $seconds, $score);


#
# Update the scoreboard if asked
#
if ($ARGV[0] eq "-u") {
    my $name = $ARGV[1];
    # this sends all the information, only the name and time are displayed in the html
    send_score_to_server($name, $correct, $errors, $seconds, $score);
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

    my ($name, $correct_output, $mem_errors, $time, $score) = @_;

    
    my $socket = new IO::Socket::INET (
	PeerHost => 'localhost',
	PeerPort => '15006',
	Proto => 'tcp'
	);
    die "cannot connect to the server $!\n" unless $socket;
    # print "connected to the server\n";
    
    # data to send to a server
    my $req = "$name,$correct_output,$mem_errors,$time,$score";
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
