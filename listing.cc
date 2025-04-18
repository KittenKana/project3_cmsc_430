// CMSC 430 Compiler Theory and Design
// UMGC
// Kana Coen
// 17 April 2025
// Project 3

#include <cstdio>
#include <string>
#include <iostream>
#include <fstream>
#include <cctype>
#include "tokens.h"
#include "listing.h"  // Include to bring in ErrorCategories enum and updated prototype

using namespace std;

// External declarations for yylex() and yytext
extern int yylex();
extern char* yytext;

// Error tracking variables
static int lineNumber;
static string error = "";
static int totalErrors = 0;
static int lexicalErrors = 0;
static int syntaxErrors = 0;
static int semanticErrors = 0;

// Forward declarations
static void displayErrors();
void appendError(ErrorCategories errorCategory, string message);
void firstLine();
void nextLine();
int lastLine();

// Set up the first line output (line number 1)
void firstLine() {
    lineNumber = 1;
    printf("\n%4d  ", lineNumber);
}

// Set up for the next line output (display errors, move to next line number)
void nextLine() {
    displayErrors();
    lineNumber++;
    printf("%4d  ", lineNumber);
}

// Final output, show error counts
int lastLine() {
    printf("\r");
    displayErrors();
    printf("     \n");

    if (0 == totalErrors) {
        printf("Compiled Successfully \n");
    }
    else {
        printf("Lexical Errors %d\n", lexicalErrors);
        printf("Syntax Errors %d\n", syntaxErrors);
        printf("Semantic Errors %d\n", semanticErrors);
    }

    return totalErrors;
}

// Append errors to the error message (using enum and single message)
void appendError(ErrorCategories errorCategory, string message) {
    string errorMsg;

    switch (errorCategory) {
        case LEXICAL:
            lexicalErrors++;
            errorMsg = "Lexical Error: " + message;
            break;
        case SYNTAX:
            syntaxErrors++;
            errorMsg = "Syntax Error: " + message;
            break;
        case GENERAL_SEMANTIC:
        case DUPLICATE_IDENTIFIER:
        case UNDECLARED:
            semanticErrors++;
            errorMsg = "Semantic Error: " + message;
            break;
    }

    totalErrors++;

    // Print errors in red if syntax error
    if (errorCategory == SYNTAX) {
        // Print red text using ANSI escape codes
        printf("\n \033[1;31m%s\033[0m\n", errorMsg.c_str());
    } else {
        error += errorMsg + "\n";
    }
}

// Display errors for the current line
void displayErrors() {
    if (error != "") {
        printf("%s", error.c_str());
    }
    error = "";
}

// Process input from stdin and perform lexical analysis
void parseInput() {
    int token;
    while ((token = yylex()) != 0) {
        string tokenText = yytext;

        switch (token) {
            case BAD_HEX_LITERAL:
                appendError(LEXICAL, "BAD_HEX_LITERAL: " + tokenText);
                break;
            case BAD_IDENTIFIER:
                appendError(LEXICAL, "BAD_IDENTIFIER: " + tokenText);
                break;
            case REAL_LITERAL:
                // Handle invalid real literals
                if (!isValidRealLiteral(tokenText)) {
                    appendError(LEXICAL, "INVALID_REAL_LITERAL: " + tokenText);
                }
                break;
            case HEX_LITERAL:
                // Handle invalid hex literals
                if (!isValidHexLiteral(tokenText)) {
                    appendError(LEXICAL, "INVALID_HEX_LITERAL: " + tokenText);
                }
                break;
            case INT_LITERAL:
                // Handle invalid integer literals
                if (!isValidIntLiteral(tokenText)) {
                    appendError(LEXICAL, "INVALID_INT_LITERAL: " + tokenText);
                }
                break;
            default:
                if (token < 256 && !isspace(token)) {
                    appendError(LEXICAL, "INVALID_CHARACTER: " + string(1, yytext[0]));
                }
                break;
        }
    }

    lastLine();
}

// Check if a real literal is valid
bool isValidRealLiteral(const string& str) {
    // Basic check for valid real literal (simplified version)
    return str.find_first_not_of("0123456789.-") == string::npos;
}

// Check if a hexadecimal literal is valid
bool isValidHexLiteral(const string& str) {
    // Basic check for valid hexadecimal literal (simplified version)
    return str.find_first_not_of("0123456789ABCDEFabcdef") == string::npos;
}

// Check if an integer literal is valid
bool isValidIntLiteral(const string& str) {
    // Basic check for valid integer literal (simplified version)
    return str.find_first_not_of("0123456789") == string::npos;
}
