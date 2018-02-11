
class Ngrams 
{
   struct Ngram
   {
      std::string ngram;
      int count;
      struct Ngram * next;
   };

   typedef struct Ngram Ngram_t;

   private:
      Ngram_t * first;
      int ngramSz;
      void insertNgram(std::string s);
      std::string getNextNgram(WordList::const_iterator start, 
                               WordList::const_iterator end);
      void printList();
   public:
      Ngrams(int ngramSz, const WordList & wl);
      ~Ngrams();
      void sortByCount(bool reverse);
      void printIncreasing();
      void printDecreasing();
};

