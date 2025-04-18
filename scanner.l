%{
#include "tokens.h"
#include <stdio.h>

#include <cmath>
#include <cstdlib>
#include <string>
#include "listing.h"

using namespace std;

double realValue;
int intValue;

int convertHexToInt(const string& hexStr) {
    int value = 0;
    size_t i = 0;

    // Skip prefix like # or 0x if present
    if (hexStr[0] == '#' || hexStr.substr(0, 2) == "0x")
        i++;

    while (i < hexStr.size()) {
        char c = hexStr[i++];
        value *= 16;
        if (c >= '0' && c <= '9')
            value += c - '0';
        else if (c >= 'a' && c <= 'f')
            value += 10 + (c - 'a');
        else if (c >= 'A' && c <= 'F')
            value += 10 + (c - 'A');
        else
            return 0; // Invalid hex
    }
    return value;
}
%}

%option noyywrap

%%

[0-9]*\.[0-9]+([eE][+-]?[0-9]+)? {
    realValue = atof(yytext);
    ECHO;
    return REAL_LITERAL;
}

[0-9]+[eE][+-]?[0-9]+ {
    realValue = atof(yytext);
    ECHO;
    return REAL_LITERAL;
}

#[0-9a-fA-F]+ {
    intValue = convertHexToInt(yytext);
    ECHO;
    return HEX_LITERAL;
}

\/\/[^\n]*            { ECHO; /* Ignore // comments */ }
--[^\n]*              { ECHO; /* Ignore -- comments */ }

"function"            { ECHO; return FUNCTION; }
"returns"             { ECHO; return RETURNS; }
"integer"             { ECHO; return INTEGER; }
"real"                { ECHO; return REAL; }
"character"           { ECHO; return CHARACTER; }

"begin"               { ECHO; return BEGIN_; }
"end"                 { ECHO; return END; }

"if"                  { ECHO; return IF; }
"then"                { ECHO; return THEN; }
"else"                { ECHO; return ELSE; }
"elsif"               { ECHO; return ELSIF; }
"endif"               { ECHO; return ENDIF; }

"switch"              { ECHO; return SWITCH; }
"case"                { ECHO; return CASE; }
"when"                { ECHO; return WHEN; }
"others"              { ECHO; return OTHERS; }
"endswitch"           { ECHO; return ENDSWITCH; }

"fold"                { ECHO; return FOLD; }
"endfold"             { ECHO; return ENDFOLD; }
"left"                { ECHO; return LEFT; }
"right"               { ECHO; return RIGHT; }

"is"                  { ECHO; return IS; }
"list"                { ECHO; return LIST; }
"of"                  { ECHO; return OF; }

"<>"                  { ECHO; return RELOP; }
"="                   { ECHO; return RELOP; }
"/="                  { ECHO; return RELOP; }
">="                  { ECHO; return RELOP; }
">"                   { ECHO; return RELOP; }
"<="                  { ECHO; return RELOP; }
"<"                   { ECHO; return RELOP; }

"&"                   { ECHO; return ANDOP; }
"|"                   { ECHO; return OROP; }
"!"                   { ECHO; return NOTOP; }

"+"                   { ECHO; return ADDOP; }
"-"                   { ECHO; return SUBOP; }
"*"                   { ECHO; return MULOP; }
"/"                   { ECHO; return DIVOP; }
"%"                   { ECHO; return MODOP; }
"^"                   { ECHO; return EXPOP; }
"~"                   { ECHO; return NEGOP; }

","                   { ECHO; return COMMA; }
":"                   { ECHO; return COLON; }
";"                   { ECHO; return SEMICOLON; }
"("                   { ECHO; return LPAREN; }
")"                   { ECHO; return RPAREN; }
"=>"                  { ECHO; return ARROW; }

"#"[0-9a-fA-F]+       { ECHO; return HEX_LITERAL; }
"#"[0-9a-fA-F]*[g-zG-Z]+ { ECHO; return BAD_HEX_LITERAL; }

[0-9]+                { ECHO; return INT_LITERAL; }
[0-9]*\.[0-9]+([eE][+-]?[0-9]+)?  { ECHO; return REAL_LITERAL; }
[0-9]+[eE][+-]?[0-9]+            { ECHO; return REAL_LITERAL; }

\'([^\'\n\r\\]|\\[btnfr\'\"\\])\'  { 
    if (yytext[1] == '\\') {
        switch (yytext[2]) {
            case 'n': intValue = '\n'; break;
            case 'f': intValue = '\f'; break;
            case 'b': intValue = '\b'; break;
            case 't': intValue = '\t'; break;
            case 'r': intValue = '\r'; break;
            case '\'': intValue = '\''; break;
            case '\"': intValue = '\"'; break;
            case '\\': intValue = '\\'; break;
            default: intValue = yytext[2]; break;
        }
    } else {
        intValue = yytext[1];
    }
    ECHO;
    return CHAR_LITERAL;
}



[_]+                             { ECHO; return BAD_IDENTIFIER; }
[a-zA-Z0-9]*_{3,}[a-zA-Z0-9]*    { ECHO; return BAD_IDENTIFIER; }
_[a-zA-Z0-9_]*                   { ECHO; return BAD_IDENTIFIER; }
[a-zA-Z0-9]*_                    { ECHO; return BAD_IDENTIFIER; }

[a-zA-Z]([a-zA-Z0-9]*(_{1,2}[a-zA-Z0-9]+)*[a-zA-Z0-9]*) { ECHO; return IDENTIFIER; }

[ \t\r\n]+            { ECHO; /* Ignore whitespace */ }

.                     { ECHO; return BAD_CHARACTER; }

%%
