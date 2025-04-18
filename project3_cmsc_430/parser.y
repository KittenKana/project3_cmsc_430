%{
#include <string>
#include <cmath>
#include <cstring>
#include <unordered_map>
#include <iostream>
using namespace std;

#include "listing.h"
#include "values.h"

int yylex();
void yyerror(const char* message);

double finalResult = 0;
unordered_map<string, double> symbolTable;
%}

%define parse.error verbose

%union {
    int intVal;
    double realVal;
    char charVal;
    char* stringVal;  // For IDENTIFIER and RELOP
}

// Precedence and associativity
%left OROP
%left ANDOP
%nonassoc RELOP
%left ADDOP SUBOP
%left MULOP DIVOP MODOP
%right EXPOP
%right NEGOP  // Modified to handle unary negation for '~'

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
    IDENTIFIER COLON type IS statement SEMICOLON {
        symbolTable[$1] = $5;  // Insert declared variable into symbol table
        printf("Variable declaration: %s = %f\n", $1, $5);
        $$ = $5;
    }
  | IDENTIFIER COLON LIST OF type IS list SEMICOLON {
        $$ = $7;  // You can also handle list initialization here if needed
    }
  | error SEMICOLON {
        $$ = 0;
    };


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
    IDENTIFIER COLON type IS expression SEMICOLON {
        printf("Assigning value to %s: %f\n", $1, $5);
        symbolTable[$1] = $5;
        $$ = $5;
    }
  | expression {
        finalResult = $1;
        $$ = $1;
    }
  | WHEN condition COMMA expression COLON expression {
        printf("Evaluating condition: value = %f\n", $2);
        if ($2) {
            $$ = $4;
            printf("Condition true: Selected %f\n", $$);
        } else {
            $$ = $6;
            printf("Condition false: Selected %f\n", $$);
        }
        finalResult = $$;
    }
  | SWITCH expression IS cases OTHERS ARROW statement SEMICOLON ENDSWITCH {
        $$ = $7;
    }
;

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
      NOTOP expression {
          printf("Evaluating NOT operation: !%f\n", $2);
          $$ = !$2;
      }
    | SUBOP expression %prec NEGOP {
          printf("Evaluating unary minus: -%f\n", $2);
          $$ = -$2;
      }
    | NEGOP expression %prec NEGOP {
          printf("Evaluating unary negation: ~%f\n", $2);
          $$ = applyNeg($2);  // Now handles unary negation as arithmetic
      }
    | expression OROP expression {
          printf("Evaluating OR operation: %f || %f\n", $1, $3);
          $$ = $1 || $3;
      }
    | expression ANDOP expression {
          printf("Evaluating AND operation: %f && %f\n", $1, $3);
          $$ = $1 && $3;
      }
    | expression RELOP expression {
          printf("Evaluating Relop: %f %s %f\n", $1, $2, $3);
          $$ = evaluateRelop($2, $1, $3);
      }
    | expression ADDOP expression {
          printf("Evaluating ADD operation: %f + %f\n", $1, $3);
          $$ = applyAdd($1, $3);
      }
    | expression SUBOP expression {
          printf("Evaluating SUB operation: %f - %f\n", $1, $3);
          $$ = applySub($1, $3);
      }
    | expression MULOP expression {
          printf("Evaluating MUL operation: %f * %f\n", $1, $3);
          $$ = $1 * $3;
      }
    | expression DIVOP expression {
          printf("Evaluating DIV operation: %f / %f\n", $1, $3);
          $$ = $1 / $3;
      }
    | expression MODOP expression {
          printf("Evaluating MOD operation: fmod(%f, %f)\n", $1, $3);
          $$ = fmod($1, $3);
      }
    | expression EXPOP expression {
          printf("Evaluating EXPOP operation: pow(%f, %f)\n", $1, $3);
          $$ = pow($1, $3);
      }
    | primary {
          printf("Evaluating primary: %f\n", $1);
          $$ = $1;
      };


primary:
    LPAREN expression RPAREN { $$ = $2; }
  | INT_LITERAL              { $$ = $1; }
  | REAL_LITERAL             { $$ = $1; }
  | CHAR_LITERAL             { $$ = $1; }
  | HEX_LITERAL              { $$ = $1; }
  | IDENTIFIER LPAREN expression RPAREN { $$ = $3; }
  | IDENTIFIER {
        string id($1);
        if (symbolTable.find(id) != symbolTable.end()) {
            $$ = symbolTable[id];
        } else {
            printf("Warning: Variable %s not found. Defaulting to 0.\n", $1);
            $$ = 0;
        }
    }
;

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
