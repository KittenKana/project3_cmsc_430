%{
#include <string>
#include <cmath>
#include <cstring>
using namespace std;

#include "listing.h"
#include "values.h"


int yylex();
void yyerror(const char* message);

double finalResult = 0;
%}

%define parse.error verbose

%union {
    int intVal;
    double realVal;
    char charVal;
    char* stringVal;
}

// Tokens
%token <stringVal> RELOP
%token <stringVal> IDENTIFIER
%token <intVal> INT_LITERAL HEX_LITERAL
%token <realVal> REAL_LITERAL
%token <charVal> CHAR_LITERAL

%token COMMA COLON SEMICOLON LPAREN RPAREN ARROW
%token BAD_IDENTIFIER BAD_CHARACTER BAD_HEX_LITERAL
%token ANDOP OROP NOTOP ADDOP SUBOP MULOP DIVOP REMOP EXPOP NEGOP MODOP
%token BEGIN_ CASE CHARACTER ELSE ELSIF END ENDCASE ENDFOLD ENDIF ENDSWITCH
%token FOLD FUNCTION IF INTEGER IS LEFT LIST OF OTHERS REAL RETURNS RIGHT SWITCH THEN WHEN

// Non-terminal types
%type <realVal> function function_header statement statement_ expressions list condition
%type <realVal> or_expr and_expr not_expr rel_expr rel_expr2 rel_expr3 rel_expr4 rel_expr5 primary
%type <realVal> variable_declaration

%%

function:
    function_header variable_declarations_opt body ;

function_header:
    FUNCTION IDENTIFIER parameters_opt RETURNS type SEMICOLON { $$ = 0; };

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
    IDENTIFIER COLON type IS statement SEMICOLON { $$ = $5; } |
    IDENTIFIER COLON LIST OF type IS list SEMICOLON { $$ = $7; } |
    error SEMICOLON { $$ = 0; };

list:
    LPAREN expressions RPAREN { $$ = $2; };

expressions:
    expressions COMMA or_expr { $$ = $3; } |
    or_expr { $$ = $1; };

body:
    BEGIN_ statements END SEMICOLON ;

statement_:
    statement SEMICOLON { $$ = $1; } |
    error SEMICOLON { $$ = 0; };

statements:
    statements statement_ |
    statement_ ;

statement:
   or_expr { finalResult = $1; $$ = $1; } |
   WHEN condition COMMA or_expr COLON or_expr {
        // Evaluate the condition and then compare the two expressions
        if ($2) {
            $$ = $6; // If the condition is true, select the first expression
        } else {
            $$ = $4; // If the condition is false, select the second expression
        }
        finalResult = $$;
    } |
    SWITCH or_expr IS cases OTHERS ARROW statement SEMICOLON ENDSWITCH { $$ = $7; } |
    SWITCH or_expr IS cases error SEMICOLON ENDSWITCH { $$ = 0; } |
    IF condition THEN statement_ elsif_clauses ELSE statement_ ENDIF { $$ = $7; } |
    FOLD direction operator list_choice ENDFOLD { $$ = 0; } |
    error { $$ = 0; } ;

elsif_clauses:
    elsif_clauses ELSIF condition THEN statement_ |
    %empty ;

cases:
    cases case_clause |
    case_clause ;

case_clause:
    case SEMICOLON |
    error SEMICOLON ;

case:
    CASE INT_LITERAL ARROW statement ;

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
    and_expr { $$ = $1; } ;

and_expr:
    and_expr ANDOP not_expr { $$ = $1 && $3; } |
    not_expr { $$ = $1; } ;

not_expr:
    NOTOP not_expr { $$ = !$2; } |
    rel_expr { $$ = $1; } ;

rel_expr:
    rel_expr RELOP rel_expr2 { $$ = evaluateRelop($2, $1, $3); } |
    rel_expr2 { $$ = $1; } ;

rel_expr2:
    rel_expr2 ADDOP rel_expr3 { $$ = applyAdd($1, $3); } |
    rel_expr2 SUBOP rel_expr3 { $$ = applySub($1, $3); } |
    rel_expr3 { $$ = $1; } ;

rel_expr3:
    rel_expr3 MULOP rel_expr4 { $$ = applyMul($1, $3); } |
    rel_expr3 DIVOP rel_expr4 { $$ = applyDiv($1, $3); } |
    rel_expr3 MODOP rel_expr4 { $$ = applyMod($1, $3); } |
    rel_expr4 { $$ = $1; } ;

rel_expr4:
    rel_expr4 EXPOP rel_expr5 { $$ = applyExp($1, $3); } |
    rel_expr5 { $$ = $1; } ;

rel_expr5:
    NEGOP rel_expr5 { $$ = applyNeg($2); } |
    primary { $$ = $1; } ;


primary:
    LPAREN or_expr RPAREN { $$ = $2; } |
    INT_LITERAL    { $$ = $1; } |
    REAL_LITERAL   { $$ = $1; } |
    CHAR_LITERAL   { $$ = $1; } |
    HEX_LITERAL    { $$ = $1; } |
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
    printf("Result = %.2f\n", finalResult);
    return 0;
}
