
#include <iostream>
#include <string>
#include <vector>
#include <cstring>
#include "WordList.h"

/*
 * WordList
 *
 * WordList inherits from the vector class
 * Construction is performed in the vector class
 */
WordList::WordList() { }

/*
 * addWord 
 *
 * lower case the alphabetic characters in the string
 * and add it to the WordList vector
 *
 * param: std:string s - string to add to vector
 * return: none
 */
void WordList::addWord(std::string s)
{
   for (int i = 0; i < s.length(); i++)
      if (isalpha(s[i])) s[i] = tolower(s[i]);
   push_back(s);
}

/*
 * operator<<
 *
 * outputs the WordList vector to the output stream
 *
 * param: std::ostream & os - output stream
 * param: const WordList & ws - WordList vector
 * return: ostream & os - output stream
 */   
std::ostream& operator<<(std::ostream& os, const WordList & wl)
{
   // WordList inherits from the vector class
   // vector class provides an iterator 
   WordList::const_iterator p;
   p = wl.begin();
   while (p != wl.end())
   {
      std::cout << (*p) << std::endl;
      p++;
   }
   return os;
}
