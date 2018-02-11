CC = g++ 
CFLAGS = $(PFLAG) -O2 -g -c -std=c++11
OBJS = Ngrams.o WordList.o main.o
LFLAGS = $(PFLAG)

.C.o:
	$(CC) $(CFLAGS) $< -o $@

best:
	make NgramLinkedList

all:
	scl enable devtoolset-3 '/bin/bash --rcfile <(echo "make ngram; exit")'

NgramLinkedList:
	-rm Ngrams.C
	-rm Ngrams.h
	ln -s NgramLinkedList.C Ngrams.C
	ln -s NgramLinkedList.h Ngrams.h
	make all

ngram: Ngrams.o WordList.o main.o
	$(CC) $(LFLAGS) $(OBJS) -o ngram

main.o: WordList.h Ngrams.h

WordList.o: WordList.h

Ngrams.o: Ngrams.h WordList.h

clean:
	-rm -f *.o ngram gmon.out Ngrams.C Ngrams.h
