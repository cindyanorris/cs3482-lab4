#!/bin/bash

#usage: ngramcheck.sh <filename>
#if no filename provided, it defaults to shakespeare9000Lines
#This script checks to see if your program produces
#correct output on the input file, forming ngrams of length two.
#It does not check for time.  It invokes
#ngram like this: ./ngram -b <filename>
#
# possible inputs are: short, shakespeare1000Lines, shakespeare5000Lines
#                      shakespeare9000Lines
#
dir="/u/csd/can/classes/3482/spring18/Labs/toollab/Inputs/"
if [ "$1" != "" ]; then
   input="$dir$1"
else
   input="$dir$1shakespeare9000Lines"
fi

if [ ! -e "ngram" ]
then
   printf "Unable to perform check.\n"
   printf "ngram executable is missing.\n"
   exit
fi

if [ ! -e "$input" ]
then
   printf "Unable to perform check.\n"
   printf "$input is missing.\n"
   exit
fi

filename="/var/tmp/ngram_`echo $USER`.out"

if [ -e $filename ] 
then
   #printf "removing: $filename\n"
   `rm $filename`
fi

if [ -e "$filename.sorted" ] 
then
   #printf "removing: $filename.sorted\n"
   `rm $filename.sorted`
fi

#printf "./ngram -b $input > $filename\n"
`./ngram -b $input > $filename`

exec 4< $filename
IFS=''
prevcount=-1

#skip the first two lines
read -u 4 line
read -u 4 line
read -u 4 line

increasing=true
#check to make sure that the output lines are
#in descending order by count
regexp='^(.+)\s(.+),\s+([0-9]+)$'
while read -u 4 line      # : is the NULL command
do
   #printf "line: %s, prev count: %s count: %s, increasing: %s\n" "$line" "$prevcount" "$count" "$increasing"; 
   if [[ ! $line ]]; then
      #reached the second half of the file
      #output is now in decreasing order
      read -u 4 line
      read -u 4 line
      read -u 4 line
      increasing=false
      prevcount=10000
   fi
   
   if [[ "$line" =~ $regexp ]]; then
      count="${BASH_REMATCH[3]}";
   else
      printf "Output not in form: <word1> <word2>, <count>\n";
      printf "Current line: %s\n" $line;
      exit;
   fi
   if [[ "$increasing" = "true" && $prevcount -gt $count ]]; then
      printf "Output file not in increasing order by count\n";
      printf "Current line: %s\n" $line;
      exit;
   elif [[ "$increasing" = "false" && $prevcount -lt $count ]]; then
      printf "Output file not in decreasing order by count\n";
      printf "Current line: %s\n" $line;
      exit;
   fi;
   prevcount=$count;
done 

#now sort the file and make sure it is identical
#to the correct output that has been sorted
#printf "sort $filename > $filename.sorted\n"
sort $filename > "$filename.sorted"

#printf "diff $filename.sorted $input.2grams.sorted > diffs\n"
diff "$filename.sorted" "$input.2grams.sorted" > diffs
if [ -s diffs ]; then
  printf "There are differences between your output and the correct output\n";
  cat diffs
  rm diffs
else
  rm diffs
  printf "Test passed\n";
fi
#rm $filename
#rm $filename.sorted
