#!/usr/bin/perl
#######################################################################
# driver.pl - Tool Lab driver
#
# This code calculates the score on the tool lab, -u <name> 
#   option to submit to scoreboard
#######################################################################
use strict 'vars';
#use Getopt::Std;
#use IO::Socket::INET;

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
my $shakespeare = $inputDir."shakespeare9000Lines";


if ($ARGV[0] eq undef) {
   die "fail: make target is required (example: make V1)";
}

system("mkdir $tmpdir") == 0
    or die "$0: Could not make scratch directory $tmpdir.\n";

(-e "$shakespeare")
    or  die "$0: ERROR: No $shakespeare, which is needed to check for correctness .\n";

print "\nCreate a version of ngram with -pg compiler option.\n";
system("make clean; make PFLAG='-pg' $ARGV[0]") == 0
    or die "$0: Could not execute make utility.\n";

unless (system("cp ngram $tmpdir/ngramp") == 0) { 
    clean($tmpdir);
    die "$0: Could not copy 'profiling' ngram to scratch directory $tmpdir.\n";
}

# Copy the input files to the scratch directory
unless (system("cp $shakespeare $tmpdir") == 0) {
    clean($tmpdir);
    die "$0: Could not copy file $shakespeare to scratch directory $tmpdir.\n";
}

# Change the current working directory to the scratch directory
unless (chdir($tmpdir)) {
    clean($tmpdir);
    die "$0: Could not change directory to $tmpdir.\n";
}

#
# Run the test
#
print "Running gprof with ngram and $shakespeare to collect timing.\n";
system("$tmpdir/ngramp  $shakespeare > $tmpdir/ngramp.output"); 
system("gprof $tmpdir/ngramp > $tmpdir/gprof.output"); 
open(my $fh, "$tmpdir/gprof.output") or die("Unable to open $tmpdir/gprof.output");
my @lines = <$fh>;
my $seconds = "1000.0";
foreach (@lines)
{
   $seconds = $1 if /^granularity: .+ of (.+) seconds$/;
}
close $fh;
print "\n";
printf("Time: %s seconds\n", $seconds);

# Clean up and exit
#clean ($tmpdir);
exit;

##################
# Helper function
#
#
# clean - remove the scratch directory
#
#
sub clean {
    my $tmpdir = shift;
    system("rm -rf $tmpdir");
}

