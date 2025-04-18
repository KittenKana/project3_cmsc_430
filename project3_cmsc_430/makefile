# Define the compiler
CXX = g++
CXXFLAGS = -std=c++11

# Define the object files
OBJ = scanner.o parser.o listing.o values.o

# Target for compiling the program
compile: $(OBJ)
	$(CXX) -o compile $(OBJ)

# Compile scanner.o from scanner.c
scanner.o: scanner.c listing.h tokens.h values.h
	$(CXX) $(CXXFLAGS) -c scanner.c

# Generate scanner.c from scanner.l using Flex
scanner.c: scanner.l
	flex scanner.l
	mv lex.yy.c scanner.c

# Compile parser.o from parser.c
parser.o: parser.c listing.h values.h
	$(CXX) $(CXXFLAGS) -c parser.c

# Generate parser.c and tokens.h from parser.y using Bison
parser.c tokens.h: parser.y
	bison -d -v parser.y
	mv parser.tab.c parser.c
	cp parser.tab.h tokens.h

# Compile listing.o from listing.cc
listing.o: listing.cc listing.h values.h
	$(CXX) $(CXXFLAGS) -c listing.cc

# Compile values.o from values.cc
values.o: values.cc values.h
	$(CXX) $(CXXFLAGS) -c values.cc

# Clean up object files and executables
clean:
	rm -f *.o compile scanner.c parser.c tokens.h
