/*
 * Name:
 *
 * Name:
 *
 */

#include <cstdlib>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cstring>
#include "WordList.h"
#include "Ngrams.h"

/*
 * usage: ngram [-n ngramsize] [-r|-b] filename
 *
 * opens the text file provided as input and builds
 * ngrams out of the words in the file. An ngram is 
 * a sequence of words that are not separated by
 * punctuation such as , . ! ? ; :
 * The size of the ngrams to be built is provided by
 * the optional ngramsize parameter; the default is 2.
 * The program also keeps a count of unique ngrams
 * and sorts the ngrams by count. At the end, the
 * ngrams and their counts are output to standard out.
 * If the -r option was provided, the list is printed
 * in reverse. If the -b option was provided, the list
 * is printed first in increasing order of count and then
 * in decreasing order
 */

void usage(int argc, char * argv[], int & ngrams, 
           bool & reverse, bool & both, std::string & filename);
void printUsage();

/*
 * main
 *
 * drives the ngram building process
 *
 * param: int argc - number of command line arguments (either 2 or 4)
 * param: char * argv[] - command line arguments
 *        argv[0] - name of executable
 *        Remainder of arguments array contain the command line arguments.
 *        -n, if used, is followed by the ngram size
 *        -r, if used, indicates the output should be displayed in reverse
 *            (largest number of ngrams first)
 *        -b, if used, indicates the output should be displayed first
 *            in forward direction and then in backward direction
 *        The last argument is always the input file name 
 */
int main(int argc, char * argv[])
{
   std::string filename;
   std::string word;
   int ngrams;
   bool reverse = false;
   bool both = false;
   WordList wl;

   //parse the command line arguments
   usage(argc, argv, ngrams, reverse, both, filename);

   //open and read file
   std::ifstream wordfile(filename);
   while (wordfile >> word)
   {
      wl.addWord(word);
   }

   //build ngrams, sort, and print
   Ngrams nglst(ngrams, wl);
   if (both)  // -b option
   {
      nglst.printIncreasing();
      nglst.printDecreasing();
   } else if (reverse) // -r option
   {
      nglst.printDecreasing();
   } else //neither -b nor -r
   {
      nglst.printIncreasing();
   }
}

/*
 * usage
 *
 * Parses the command line arguments.  Calls printUsage and exits
 * if invalid command line arguments.
 *
 * param: int argc - number of command line arguments
 * param: char * argv[] - command line arguments
 * param: int & ngrams - set to the size of the ngrams to be built (default 2)
 * param: int & reverse - set to true if -r option given
 * param: int & both - set to true if -b option given
 * param: std::string & filename - set to the name of the text file to be 
 *                            used for input
 */
void usage(int argc, char * argv[], int & ngrams, bool & reverse,
           bool & both, std::string & filename)
{
   int i;
   ngrams = 2;
   reverse = both = false;
   if (argc < 2) printUsage();
   for (i = 1; i < argc - 1; i++)
   {
      if (strcmp(argv[i], "-n") == 0)
      {
         ngrams = atoi(argv[i+1]); 
         i++;
         if (ngrams == 0) printUsage();
      } else if (strcmp(argv[i], "-r") == 0)
      {
         reverse = true;
      } else if (strcmp(argv[i], "-b") == 0)
      {
         both = true;
      } else
         printUsage();
   }
   if (reverse && both) printUsage();
   filename = argv[argc - 1];
   std::ifstream wordfile(filename);
   if (!wordfile.is_open()) 
   {
      std::cout << "could not open: " << filename << std::endl;
      printUsage();
   }
   wordfile.close();
}

/*
 * printUsage
 * Prints usage information and then exits
*/
void printUsage()
{
   std::cout << "usage: [-n <ngram size>] [-r | -b] <filename>\n";
   std::cout << "  <ngram size> indicates the size of the ngrams to build\n";
   std::cout << "  -r print ngrams in reverse order (largest number first)\n";
   std::cout << "  -b print ngrams first in forward direction and then in reverse\n";
   std::cout << "  default: 2 ngrams are built and output in increasing order\n";
   std::cout << "  <filename> name of file to build ngrams from\n";
   exit(1);
}
