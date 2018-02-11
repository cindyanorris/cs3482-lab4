
class WordList : public std::vector<std::string>
{
   private:
   public:
      WordList();
      void addWord(std::string s);
};

std::ostream& operator<<(std::ostream& os, const WordList & wl);

