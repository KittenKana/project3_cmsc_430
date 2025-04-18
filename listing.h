// CMSC 430 Compiler Theory and Design
// UMGC
// Kana Coen
// 17 April 2025
// Project 3

// This file contains the function prototypes for the functions that produce
// the compilation listing

#include <string>
using namespace std;

// Enum for categorizing errors
enum ErrorCategories {
    LEXICAL,              // Lexical errors (invalid tokens, bad literals, etc.)
    SYNTAX,               // Syntax errors (incorrect grammar, missing semicolons, etc.)
    GENERAL_SEMANTIC,     // General semantic errors (misuse of language constructs)
    DUPLICATE_IDENTIFIER, // Duplicate variable/function declarations
    UNDECLARED            // Use of undeclared identifiers/variables
};

// Function prototypes
void firstLine();               // Set up the first line of the listing with line number
void nextLine();                // Move to the next line, display errors, and increment line number
int lastLine();                 // Final output showing error counts and success or failure

// Append an error message of a specified category to the error log
void appendError(ErrorCategories errorCategory, string message);

// Additional helper functions for lexical analysis and error validation
bool isValidRealLiteral(const string& str);   // Check if a real literal is valid
bool isValidHexLiteral(const string& str);    // Check if a hexadecimal literal is valid
bool isValidIntLiteral(const string& str);    // Check if an integer literal is valid
