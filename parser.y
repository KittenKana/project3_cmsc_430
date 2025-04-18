%{
#include <string>
#include <cstdlib>
#include <cstring>   // Fix for strcmp
#include <cmath>     // Fix for pow
using namespace std;

#include "listing.h"

extern double realValue;
extern int intValue;
extern char* yytext;

int yylex();
void yyerror(const char* message);
%}

%define parse.error verbose
%define api.value.type {double}

%token COMMA COLON SEMICOLON LPAREN RPAREN ARROW
%token IDENTIFIER BAD_IDENTIFIER BAD_CHARACTER
%token INT_LITERAL REAL_LITERAL HEX_LITERAL CHAR_LITERAL BAD_HEX_LITERAL
%token ANDOP OROP NOTOP RELOP ADDOP SUBOP MULOP DIVOP REMOP EXPOP NEGOP MODOP
%token BEGIN_ CASE CHARACTER ELSE ELSIF END ENDCASE ENDFOLD ENDIF ENDSWITCH
%token FOLD FUNCTION IF INTEGER IS LEFT LIST OF OTHERS REAL RETURNS RIGHT SWITCH THEN WHEN

%%

function:
    function_header variable_declarations_opt body {
        printf("\nResult = %.2f\n", $3);  // Print result of the function (which comes from $3, the body)
    };

function_header:
    FUNCTION IDENTIFIER parameters_opt RETURNS type SEMICOLON ;

parameters_opt:
    parameters |
    %empty ;

parameters:
    parameters COMMA parameter |
    parameter ;

parameter:
    IDENTIFIER COLON type |
    IDENTIFIER error type { yyerrok; };

variable_declarations_opt:
    variable_declarations |
    %empty ;

variable_declarations:
    variable_declarations variable_declaration |
    variable_declaration ;

variable_declaration:
    IDENTIFIER COLON type IS statement SEMICOLON |
    IDENTIFIER COLON LIST OF type IS list SEMICOLON |
    error SEMICOLON ;

list:
    LPAREN expressions RPAREN ;

expressions:
    expressions COMMA or_expr |
    or_expr ;

body:
    BEGIN_ statements END SEMICOLON {
        $$ = $2;  // The body should return the result of the statements
    };

statements:
    statements statement SEMICOLON { $$ = $2; } |
    statement SEMICOLON { $$ = $1; };

statement:
    or_expr { $$ = $1; } |
    WHEN condition COMMA or_expr COLON or_expr {
    if ($2) $$ = $4;
    else $$ = $6;
    } |
    SWITCH or_expr IS cases OTHERS ARROW statement SEMICOLON ENDSWITCH |
    SWITCH or_expr IS cases error SEMICOLON ENDSWITCH |
    IF condition THEN statement ELSIF condition THEN statement ELSE statement ENDIF |
    FOLD direction operator list_choice ENDFOLD |
    error ;

cases:
    cases case_clause |
    case_clause ;

case_clause:
    case SEMICOLON |
    error SEMICOLON;

case:
    CASE INT_LITERAL ARROW statement |
    error ;

direction:
    LEFT |
    RIGHT ;

operator:
    ADDOP |
    SUBOP |
    MULOP |
    MODOP |
    EXPOP ;

list_choice:
    list |
    IDENTIFIER ;

condition:
    or_expr ;

or_expr:
    or_expr OROP and_expr { $$ = $1 || $3; } |
    and_expr ;

and_expr:
    and_expr ANDOP not_expr { $$ = $1 && $3; } |
    not_expr ;

not_expr:
    NOTOP not_expr { $$ = !$2; } |
    rel_expr ;

rel_expr:
    rel_expr RELOP rel_expr2 {
        if (strcmp(yytext, "=") == 0) $$ = ($1 == $3);
        else if (strcmp(yytext, "<") == 0) $$ = ($1 < $3);
        else if (strcmp(yytext, "<=") == 0) $$ = ($1 <= $3);
        else if (strcmp(yytext, ">") == 0) $$ = ($1 > $3);
        else if (strcmp(yytext, ">=") == 0) $$ = ($1 >= $3);
        else if (strcmp(yytext, "<>") == 0) $$ = ($1 != $3);
        else $$ = 0;
    } |
    rel_expr2 ;

rel_expr2:
    rel_expr2 ADDOP rel_expr3 { $$ = $1 + $3; } |
    rel_expr2 SUBOP rel_expr3 { $$ = $1 - $3; } |
    rel_expr3 ;

rel_expr3:
    rel_expr3 MULOP rel_expr4 { $$ = $1 * $3; } |
    rel_expr3 DIVOP rel_expr4 { $$ = $1 / $3; } |
    rel_expr3 MODOP rel_expr4 { $$ = (int)$1 % (int)$3; } |
    rel_expr4 ;

rel_expr4:
    rel_expr4 EXPOP rel_expr5 { $$ = pow($1, $3); } |
    rel_expr5 ;

rel_expr5:
    NEGOP rel_expr5 { $$ = -$2; } |
    primary ;

primary:
    REAL_LITERAL { $$ = realValue; } |
    HEX_LITERAL { $$ = intValue; } |
    INT_LITERAL { $$ = intValue; } |
    CHAR_LITERAL {
        // Handle escape sequences for character literals
        if (yytext[1] == '\\') {
            if (yytext[2] == 'n') $$ = '\n';    // Newline
            else if (yytext[2] == 'f') $$ = '\f'; // Form feed
            else if (yytext[2] == 't') $$ = '\t'; // Tab
            else if (yytext[2] == 'r') $$ = '\r'; // Carriage return
            else if (yytext[2] == '\\') $$ = '\\'; // Backslash
            else $$ = yytext[2];  // Handle other escape sequences
        } else {
            $$ = yytext[1];  // For non-escaped characters
        }
        printf("CHAR_LITERAL: %f\n", $$); // Corrected print format for char literal
    } |
    LPAREN or_expr RPAREN { $$ = $2; } |
    IDENTIFIER LPAREN or_expr RPAREN { $$ = $3; } |
    IDENTIFIER { $$ = 0; } ;

type:
    INTEGER |
    REAL |
    CHARACTER ;

%%

void yyerror(const char* message) {
    appendError(SYNTAX, message);
}

int main(int argc, char *argv[]) {
    firstLine();
    yyparse();
    lastLine();
    return 0;
}
