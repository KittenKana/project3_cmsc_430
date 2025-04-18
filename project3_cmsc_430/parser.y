%{
#include <string>
#include <cmath>
#include <cstring>
#include <unordered_map>
#include <iostream>
#include <cstdlib>         // for atof
using namespace std;

#include "listing.h"
#include "values.h"

int yylex();
void yyerror(const char* message);

double finalResult = 0;
unordered_map<string,double> symbolTable;

// parameter support:
double* paramValues = nullptr;
int     paramCount  = 0;
int     paramIndex  = 0;
%}

%define parse.error verbose

%union {
  int    intVal;
  double realVal;
  char   charVal;
  char*  stringVal;
}

// precedences
%left OROP
%left ANDOP
%nonassoc RELOP
%left ADDOP SUBOP
%left MULOP DIVOP MODOP
%right EXPOP
%right NEGOP

// tokens
%token <stringVal> RELOP IDENTIFIER
%token <intVal>    INT_LITERAL HEX_LITERAL
%token <realVal>   REAL_LITERAL
%token <charVal>   CHAR_LITERAL

%token COMMA COLON SEMICOLON LPAREN RPAREN ARROW
%token BAD_IDENTIFIER BAD_CHARACTER BAD_HEX_LITERAL
%token ANDOP OROP NOTOP ADDOP SUBOP MULOP DIVOP REMOP EXPOP NEGOP MODOP
%token BEGIN_ CASE CHARACTER ELSE ELSIF END ENDCASE ENDFOLD ENDIF ENDSWITCH
%token FOLD FUNCTION IF INTEGER IS LEFT LIST OF OTHERS REAL RETURNS RIGHT SWITCH THEN WHEN

%type <realVal> function function_header statement statement_ expressions list condition
%type <realVal> expression primary variable_declaration

%%

function:
    function_header variable_declarations_opt body
  ;

function_header:
    FUNCTION IDENTIFIER parameters_opt RETURNS type SEMICOLON
  ;

parameters_opt:
    parameters
  | /* empty */
  ;

parameters:
    parameters COMMA parameter
  | parameter
  ;

parameter:
    IDENTIFIER COLON type
    {
      // fetch next parameter from paramValues
      double val = 0.0;
      if (paramIndex < paramCount) val = paramValues[paramIndex++];
      symbolTable[$1] = val;
    }
  | IDENTIFIER error type { yyerrok; }
  ;

variable_declarations_opt:
    variable_declarations
  | /* empty */
  ;

variable_declarations:
    variable_declarations variable_declaration
  | variable_declaration
  ;

variable_declaration:
    IDENTIFIER COLON type IS statement SEMICOLON
    {
      symbolTable[$1] = $5;
      $$ = $5;
    }
  | IDENTIFIER COLON LIST OF type IS list SEMICOLON
    { $$ = $7; }
  | error SEMICOLON
    { $$ = 0; }
  ;

list:
    LPAREN expressions RPAREN { $$ = $2; }
  ;

expressions:
    expressions COMMA expression { $$ = $3; }
  | expression                { $$ = $1; }
  ;

body:
    BEGIN_ statements END SEMICOLON
  ;

statement_:
    statement SEMICOLON { $$ = $1; }
  | error     SEMICOLON { $$ = 0; }
  ;

statements:
    statements statement_
  | statement_
  ;

statement:
    /* assignment */
    IDENTIFIER COLON type IS expression SEMICOLON
    {
      symbolTable[$1] = $5;
      $$ = $5;
    }

  /* plain expression */
  | expression
    {
      finalResult = $1;
      $$ = $1;
    }

  /* when cond , e1 : e2 */
  | WHEN condition COMMA expression COLON expression
    {
      $$ = $2 ? $4 : $6;
      finalResult = $$;
    }

  /* switch … others */
  | SWITCH expression IS cases OTHERS ARROW statement SEMICOLON ENDSWITCH
    { $$ = $7; }

  /* if‐then‐else */
  | IF condition THEN statement_ ELSE statement_ ENDIF
    {
      $$ = $2 ? $4 : $6;
      finalResult = $$;
    }

  /* if‐elsif‐else */
  | IF condition THEN statement_
        ELSIF condition THEN statement_
        ELSE statement_ ENDIF
    {
      $$ = $2 ? $4 : ( $6 ? $8 : $10 );
      finalResult = $$;
    }

  /* if‐elsif‐elsif‐else */
  | IF condition THEN statement_
        ELSIF condition THEN statement_
        ELSIF condition THEN statement_
        ELSE statement_ ENDIF
    {
      $$ = $2 ? $4 : ( $6 ? $8 : ( $10 ? $12 : $14 ) );
      finalResult = $$;
    }
  ;

cases:
    cases case_clause
  | case_clause
  ;

case_clause:
    case SEMICOLON
  | error SEMICOLON
  ;

case:
    CASE INT_LITERAL ARROW statement
  ;

condition:
    expression
  ;

expression:
      NOTOP   expression             { $$ = !$2; }
    | SUBOP   expression %prec NEGOP { $$ = -$2; }
    | NEGOP   expression %prec NEGOP { $$ = applyNeg($2); }
    | expression OROP expression     { $$ = $1 || $3; }
    | expression ANDOP expression    { $$ = $1 && $3; }
    | expression RELOP expression    { $$ = evaluateRelop($2,$1,$3); }
    | expression ADDOP expression    { $$ = applyAdd($1,$3); }
    | expression SUBOP expression    { $$ = applySub($1,$3); }
    | expression MULOP expression    { $$ = applyMul($1,$3); }
    | expression DIVOP expression    { $$ = applyDiv($1,$3); }
    | expression MODOP expression    { $$ = applyMod($1,$3); }
    | expression EXPOP expression    { $$ = applyExp($1,$3); }
    | primary
  ;

primary:
    LPAREN expression RPAREN         { $$ = $2; }
  | INT_LITERAL                     { $$ = $1; }
  | REAL_LITERAL                    { $$ = $1; }
  | CHAR_LITERAL                    { $$ = $1; }
  | HEX_LITERAL                     { $$ = $1; }
  | IDENTIFIER LPAREN expression RPAREN { $$ = $3; }
  | IDENTIFIER {
      string id($1);
      auto it = symbolTable.find(id);
      $$ = (it!=symbolTable.end() ? it->second : 0.0);
    }
  ;

type:
    INTEGER | REAL | CHARACTER
  ;

%%

void yyerror(const char* message) {
  appendError(SYNTAX, message);
}

int main(int argc, char* argv[]) {
  // grab command‐line parameters
  paramCount = argc - 1;
  if (paramCount > 0) {
    paramValues = new double[paramCount];
    for (int i = 1; i < argc; i++)
      paramValues[i-1] = atof(argv[i]);
  }

  firstLine();
  yyparse();
  lastLine();
  printf("Result = %.2f\n", finalResult);
  return 0;
}
