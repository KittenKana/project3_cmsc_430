%{
#include <string>
using namespace std;

#include "listing.h"

int yylex();
void yyerror(const char* message);
%}

%define parse.error verbose

%token COMMA COLON SEMICOLON LPAREN RPAREN ARROW
%token IDENTIFIER BAD_IDENTIFIER BAD_CHARACTER
%token INT_LITERAL REAL_LITERAL HEX_LITERAL CHAR_LITERAL BAD_HEX_LITERAL
%token ANDOP OROP NOTOP RELOP ADDOP SUBOP MULOP DIVOP REMOP EXPOP NEGOP MODOP
%token BEGIN_ CASE CHARACTER ELSE ELSIF END ENDCASE ENDFOLD ENDIF ENDSWITCH
%token FOLD FUNCTION IF INTEGER IS LEFT LIST OF OTHERS REAL RETURNS RIGHT SWITCH THEN WHEN

%%

function:
    function_header variable_declarations_opt body ;

function_header:
    FUNCTION IDENTIFIER parameters_opt RETURNS type SEMICOLON ;

parameters_opt:
    parameters |
    %empty ;

parameters:
    parameters COMMA parameter |
    parameter ;

parameter:
    IDENTIFIER COLON type
    | IDENTIFIER error type { yyerrok; }
    ;

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
    BEGIN_ statements END SEMICOLON ;

statement_:
    statement SEMICOLON |
    error SEMICOLON ;

statements:
    statements statement_ |
    statement_ ;

statement:
    or_expr |
    WHEN condition COMMA or_expr COLON or_expr |
    SWITCH or_expr IS cases OTHERS ARROW statement SEMICOLON ENDSWITCH |
    SWITCH or_expr IS cases error SEMICOLON ENDSWITCH  |
    IF condition THEN statement_ elsif_clauses ELSE statement_ ENDIF |
    FOLD direction operator list_choice ENDFOLD |
    error ;

elsif_clauses:
    elsif_clauses ELSIF condition THEN statement_ |
    %empty ;

cases:
    cases case_clause |
    case_clause ;

case_clause:
    case SEMICOLON |
    error SEMICOLON;

case:
    CASE INT_LITERAL ARROW statement;

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
    or_expr OROP and_expr |
    and_expr ;

and_expr:
    and_expr ANDOP not_expr |
    not_expr ;

not_expr:
    NOTOP not_expr |
    rel_expr ;

rel_expr:
    rel_expr RELOP rel_expr2 |
    rel_expr2 ;

rel_expr2:
    rel_expr2 ADDOP rel_expr3 |
    rel_expr2 SUBOP rel_expr3 |
    rel_expr3 ;

rel_expr3:
    rel_expr3 MULOP rel_expr4 |
    rel_expr3 DIVOP rel_expr4 |
    rel_expr3 MODOP rel_expr4 |
    rel_expr4 ;

rel_expr4:
    rel_expr4 EXPOP rel_expr5 |
    rel_expr5 ;

rel_expr5:
    NEGOP rel_expr5 |
    primary ;

primary:
    LPAREN or_expr RPAREN |
    INT_LITERAL |
    REAL_LITERAL |
    CHAR_LITERAL |
    HEX_LITERAL |
    IDENTIFIER LPAREN or_expr RPAREN |
    IDENTIFIER ;

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
