%{
#include "tokens.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int hexToInt(const char* text) {
    int value = 0;
    sscanf(text + 1, "%x", &value);  // Skip '#'
    return value;
}

int charLiteralToValue(const char* text) {
    if (text[1] == '\\') {
        switch (text[2]) {
            case 'n': return '\n';
            case 't': return '\t';
            case 'b': return '\b';
            case 'f': return '\f';
            case 'r': return '\r';
            case '\'': return '\''; 
            case '\"': return '\"'; 
            case '\\': return '\\'; 
            default: return text[2];
        }
    } else {
        return text[1];
    }
}
%}

%option noyywrap

%%




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

"<>"     { ECHO; yylval.stringVal = strdup(yytext); return RELOP; }
"="      { ECHO; yylval.stringVal = strdup(yytext); return RELOP; }
"/="     { ECHO; yylval.stringVal = strdup(yytext); return RELOP; }
">="     { ECHO; yylval.stringVal = strdup(yytext); return RELOP; }
">"      { ECHO; yylval.stringVal = strdup(yytext); return RELOP; }
"<="     { ECHO; yylval.stringVal = strdup(yytext); return RELOP; }
"<"      { ECHO; yylval.stringVal = strdup(yytext); return RELOP; }


"&"      { ECHO; return ANDOP; }
"|"      { ECHO; return OROP; }
"!"      { ECHO; return NOTOP; }

"+"      { ECHO; return ADDOP; }
"-"      { ECHO; return SUBOP; }
"*"      { ECHO; return MULOP; }
"/"      { ECHO; return DIVOP; }
"%"      { ECHO; return MODOP; }
"^"      { ECHO; return EXPOP; }
"~"      { ECHO; return NEGOP; }

","      { ECHO; return COMMA; }
":"      { ECHO; return COLON; }
";"      { ECHO; return SEMICOLON; }
"("      { ECHO; return LPAREN; }
")"      { ECHO; return RPAREN; }
"=>"     { ECHO; return ARROW; }

#[0-9a-fA-F]+ {
    ECHO;
    yylval.intVal = hexToInt(yytext);
    return HEX_LITERAL;
}

#[^0-9a-fA-F\n\r\t ]+[a-zA-Z0-9]* {
    ECHO;
    return BAD_HEX_LITERAL;
}

[0-9]*\.[0-9]+([eE][+-]?[0-9]+)? |
[0-9]+\.[0-9]*([eE][+-]?[0-9]+)? |
[0-9]+[eE][+-]?[0-9]+ {
    ECHO;
    yylval.realVal = atof(yytext);
    return REAL_LITERAL;
}

[0-9]+ {
    ECHO;
    yylval.intVal = atoi(yytext);
    return INT_LITERAL;
}

\'([^\\'\n]|\\[btnfr\'\"\\])\' {
    ECHO;
    yylval.charVal = charLiteralToValue(yytext);
    return CHAR_LITERAL;
}

\'([^']|\\.)[^']\' {
    ECHO;
    return BAD_CHARACTER;
}

[a-zA-Z]([a-zA-Z0-9]*(_{1,2}[a-zA-Z0-9]+)*[a-zA-Z0-9]*) {
    ECHO;
    return IDENTIFIER;
}

_{1,} |
[a-zA-Z0-9]*_{3,}[a-zA-Z0-9]* |
_[a-zA-Z0-9_]* |
[a-zA-Z0-9]*_ {
    ECHO;
    return BAD_IDENTIFIER;
}

[ \t\r\n]+    { ECHO; /* ignore whitespace */ }

.             { ECHO; return BAD_CHARACTER; }

%%
