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

// Define precedence rules for operators
%left ADDOP SUBOP     // Left-associative for + and -
%left MULOP DIVOP MODOP // Left-associative for *, /, and %
%left RELOP           // Left-associative for relational operators
%right EXPOP          // Right-associative for exponentiation (if you want this as right-associative)
%left ANDOP           // Left-associative for logical AND
%left OROP            // Left-associative for logical OR

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
%type <realVal> expression primary variable_declaration

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
    expressions COMMA expression { $$ = $3; } |
    expression { $$ = $1; };

body:
    BEGIN_ statements END SEMICOLON ;

statement_:
    statement SEMICOLON { $$ = $1; } |
    error SEMICOLON { $$ = 0; };

statements:
    statements statement_ |
    statement_ ;

statement:
   expression { finalResult = $1; $$ = $1; } |
   WHEN condition COMMA expression COLON expression {
        if ($2) {
            $$ = $6;
        } else {
            $$ = $4;
        }
        finalResult = $$;
    } |
    SWITCH expression IS cases OTHERS ARROW statement SEMICOLON ENDSWITCH { $$ = $7; } |
    SWITCH expression IS cases error SEMICOLON ENDSWITCH { $$ = 0; } |
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
    expression ;

expression:
      expression OROP expression         { $$ = $1 || $3; }
    | expression ANDOP expression        { $$ = $1 && $3; }
    | expression RELOP expression        { $$ = evaluateRelop($2, $1, $3); }
    | expression ADDOP expression        { $$ = applyAdd($1, $3); }
    | expression SUBOP expression        { $$ = applySub($1, $3); }
    | expression MULOP expression        { $$ = applyMul($1, $3); }
    | expression DIVOP expression        { $$ = applyDiv($1, $3); }
    | expression MODOP expression        { $$ = applyMod($1, $3); }
    | expression EXPOP expression        { $$ = applyExp($1, $3); }
    | NOTOP expression %prec NOTOP       { $$ = !$2; }
    | NEGOP expression %prec NEGOP       { $$ = applyNeg($2); }
    | primary                            { $$ = $1; }
    ;

primary:
    LPAREN expression RPAREN { $$ = $2; } |
    INT_LITERAL    { $$ = $1; } |
    REAL_LITERAL   { $$ = $1; } |
    CHAR_LITERAL   { $$ = $1; } |
    HEX_LITERAL    { $$ = $1; } |
    IDENTIFIER LPAREN expression RPAREN { $$ = $3; } |
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
