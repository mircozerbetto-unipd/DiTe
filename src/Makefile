include ../Makefile.in

# override for debugging
#COMPOPT=-g -O0 -DDEBUG

DiTe2: dite2.o
	$(CPP) $(COMPOPT) $(LL) dite2.o -o dite2 -std=c++11 $(LIBS)

dite2.o: dite2.cpp
	$(CPP) $(COMPOPT) $(II) $(LL) -c dite2.cpp -std=c++11

clean:
	rm -rf ./*.o ./dite2
