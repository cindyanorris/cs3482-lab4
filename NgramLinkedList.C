
#include <iostream>
#include <string>
#include <vector>
#include "WordList.h"
#include "Ngrams.h"

/*
 * Ngrams
 *
 * takes as input the size of the ngrams to be built and the list  
 * of words to build the ngrams from and builds a linked list of 
 * ngrams.
 *
 * param: int ngramSz - size of the ngram
 * param: const WordList & wl - list of the words use
 */
Ngrams::Ngrams(int ngramSz, const WordList & wl)
{
   this->ngramSz = ngramSz;
   WordList::const_iterator p;
   first = NULL;
   p = wl.begin();
   while (p != wl.end())
   {
      std::string ngram = getNextNgram(p, wl.end());
      p++;
      if (!ngram.empty()) insertNgram(ngram);
   }
}

/*
 * Ngrams destructor
 *
 * automatically called when Ngrams object goes out of scope
 * deletes the linked list
 */
Ngrams::~Ngrams()
{
   Ngram_t * nextNgram;
   while (first != NULL)
   {
      nextNgram = first->next;
      free(first);
      first = nextNgram;
   }
}

/*
 * getNextNgram
 *
 * takes as input an iterator that points to the word to start the
 * ngram and an iterator that points to the end of the word list
 * and builds and returns the ngram. returns empty string if no
 * ngram can be built, for example, if there are insufficient words
 * to build one.
 *
 * param: WordList::const_iterator start - points to first word in ngram
 * param: WordList::const_iterator end - points to end of word list
 * return: std::string - returns ngram or empty string
 */
std::string Ngrams::getNextNgram(WordList::const_iterator start, 
                                 WordList::const_iterator end)
{
   int i, len;
   std::string ngram = "";
   for (i = 0; i < ngramSz && start != end; i++)
   {
      std::string word = (*start);
      //see if the string ends with punctuation
      //don't create ngrams that continue after punctuation
      if (!isalpha(word[word.length()-1]) && i < ngramSz - 1) return "";

      //take off all ending punctuation
      len = word.length() - 1;
      while (len >= 0 && !isalpha(word[len])) 
      {
         //remove last character
         word = word.substr(0, word.length() - 1);
         len--;
      }
      if (len < 0) return "";  //give up

      //is the first word in the ngram?
      if (ngram == "") ngram = word;
      else ngram = ngram + " " + word;

      start++;
   }

   //could we build a long enough ngram?
   if (i < ngramSz) return "";

   //take off beginning punctuation
   while (ngram.length() > 0 && !isalpha(ngram[0])) 
      ngram = ngram.substr(1, ngram.length());
   return ngram;
}

/*
 * insertNgram
 *
 * looks for the ngram to be inserted. If it is already in
 * the linked list,  it increments the count. If not, it 
 * inserts it into the linked list.
 *
 * param: std::string s - ngram to be inserted
 * return: none
 */
void Ngrams::insertNgram(std::string s)
{
   Ngram_t * ptr = first;
   Ngram_t * newNode = new Ngram_t();
   newNode->ngram = s;
   newNode->count = 1;

   while (ptr != NULL)
   {
      //s already in list
      if (ptr->ngram == s) 
      {
         ptr->count++;
         return;
      }
      ptr = ptr->next;
   }
   //insert in front of list
   newNode->next = first;
   first = newNode;
}


/*
 * sortByCount
 *
 * performs a bubble sort on the linked list of ngrams, sorting the
 * nodes in the list by the count in increasing or decreasing
 * order of count depending upon the value of reverse
 *
 * param: reverse - true if sort should be decreasing
 * return: none (modfied private linked list)
 */
void Ngrams::sortByCount(bool reverse)
{
   Ngram_t * ptr = first;
   Ngram_t * ptr1;
   Ngram_t * ptr2;
   int tcount;
   bool switchNodes;
   std::string tngram;

   while (ptr != NULL)
   {
      ptr1 = first; 
      ptr2 = ptr1->next;
      while (ptr2 != NULL) 
      {
         switchNodes = (reverse == true && ptr2->count > ptr1->count) ||
                       (reverse == false && ptr2->count < ptr1->count);
         if (switchNodes)
         {
            tcount = ptr1->count;
            tngram = ptr1->ngram;
            ptr1->count = ptr2->count;
            ptr1->ngram = ptr2->ngram; 
            ptr2->count = tcount;
            ptr2->ngram = tngram;
         }
         ptr1 = ptr2; 
         ptr2 = ptr2->next;
      }
      ptr = ptr->next;
   }
}

/*
 * printIncreasing
 *
 * Prints the list of ngrams in increasing order. First
 * calls sortByCount passing it the value of false, which indicates
 * that the nodes are to be sorted in increasing order of count.
 *
 */  
void Ngrams::printIncreasing()
{
   sortByCount(false);
   std::cout << "\nIncreasing list of " << ngramSz << " word ngrams and counts\n";
   std::cout << "-------------------------------------------\n";
   printList();
}

/*
 * printList
 *
 * Prints the nodes in the Ngrams linked list.
 */
void Ngrams::printList()
{
   Ngrams::Ngram_t * ptr = first;
   while (ptr != NULL)
   {
      std::cout << ptr->ngram << ", " << ptr->count << std::endl;
      ptr = ptr->next;
   } 
}

/*
 * printDecreasing
 *
 * Prints the list of ngrams in decreasing order. First
 * calls sortByCount passing it the value of true, which indicates
 * that the nodes are to be sorted in decreasing order of count.
 *
 */  
void Ngrams::printDecreasing()
{
   sortByCount(true);
   std::cout << "\nDecreasing list of " << ngramSz << " word ngrams and counts\n";
   std::cout << "-------------------------------------------\n";
   printList();
}
