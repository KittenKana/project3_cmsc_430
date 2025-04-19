%{
#include <string>
#include <cmath>
#include <cstring>
#include <unordered_map>
#include <iostream>
#include <cstdlib>
#include <vector>
using namespace std;

#include "listing.h"
#include "values.h"

int yylex();
void yyerror(const char* message);

double finalResult = 0;
unordered_map<string, double> symbolTable;
unordered_map<string, vector<Value>> vectorTable; // NEW: separate table for vectors

double* paramValues = nullptr;
int     paramCount  = 0;
int     paramIndex  = 0;
%}

%code requires {
#include "values.h"
#include <vector>
}

%define parse.error verbose

%union {
  int    intVal;
  double realVal;
  char   charVal;
  char*  stringVal;
  std::vector<Value>* vecVal;
}

%left OROP
%left ANDOP
%nonassoc RELOP
%left ADDOP SUBOP
%left MULOP DIVOP MODOP
%right EXPOP
%right NEGOP

%token <stringVal> RELOP IDENTIFIER
%token <intVal>    INT_LITERAL HEX_LITERAL
%token <realVal>   REAL_LITERAL
%token <charVal>   CHAR_LITERAL

%token COMMA COLON SEMICOLON LPAREN RPAREN ARROW
%token BAD_IDENTIFIER BAD_CHARACTER BAD_HEX_LITERAL
%token ANDOP OROP NOTOP ADDOP SUBOP MULOP DIVOP REMOP EXPOP NEGOP MODOP
%token BEGIN_ CASE CHARACTER ELSE ELSIF END ENDCASE ENDFOLD ENDIF ENDSWITCH
%token FOLD FUNCTION IF INTEGER IS LEFT LIST OF OTHERS REAL RETURNS RIGHT SWITCH THEN WHEN

%token <intVal> Y_OP

%type <realVal> function function_header statement statement_ condition
%type <realVal> expression primary variable_declaration fold_expr
%type <intVal> direction fold_op

%type <vecVal> expressions list expr_list
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
      double val = 0.0;
      if (paramIndex < paramCount) val = paramValues[paramIndex++];
      symbolTable[$1] = val;
    }
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
    {
      // Initialize a new vector to store the list values
      vector<Value>* vec = new vector<Value>();

      for (const Value& val : *$7) {
          vec->push_back(val);  // Push each value from the list into the vector
      }

      // Store the vector in vectorTable using the identifier as the key
      vectorTable[$1] = *vec;
      $$ = 0;  // No return value for variable declaration
    }
  | error SEMICOLON
    { $$ = 0; }
  ;

list:
    LPAREN expressions RPAREN { $$ = $2; }
  ;

expressions:
    expressions COMMA expression {
        $$ = $1;
        $$->push_back(Value($3));  // Wrap $3 in a Value and add to vector
    }
  | expression {
        $$ = new std::vector<Value>();  // Start new vector
        $$->push_back(Value($1));       // Wrap $1 in a Value and add
    }
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
    IDENTIFIER COLON type IS expression SEMICOLON
    {
      symbolTable[$1] = $5;
      $$ = $5;
    }
  | expression
    {
      finalResult = $1;
      $$ = $1;
    }
  | WHEN condition COMMA expression COLON expression
    {
      $$ = $2 ? $4 : $6;
      finalResult = $$;
    }
  | SWITCH expression IS cases OTHERS ARROW statement SEMICOLON ENDSWITCH
    { $$ = $7; }
  | IF condition THEN statement_ ELSE statement_ ENDIF
    {
      $$ = $2 ? $4 : $6;
      finalResult = $$;
    }
  | IF condition THEN statement_
        ELSIF condition THEN statement_
        ELSE statement_ ENDIF
    {
      $$ = $2 ? $4 : ( $6 ? $8 : $10 );
      finalResult = $$;
    }
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
    | fold_expr                      { $$ = $1; }
  ;

fold_expr:
    FOLD direction fold_op expr_list ENDFOLD
    {
        vector<double> values;
        std::cout << "Folding with values: ";
        for (const Value& v : *$4) {
            values.push_back(v.realVal);  // Extract the real value from the Value object
            std::cout << v.realVal << " ";  // Print each value in the list
        }
        std::cout << std::endl;
        $$ = evaluateFold($2, $3, values);  // Call evaluateFold with the extracted values
        delete $4;  // Clean up the list
    }
  | FOLD direction fold_op IDENTIFIER ENDFOLD
    {
        string id($4);
        auto it = vectorTable.find(id);
        if (it != vectorTable.end()) {
            vector<double> values;
            std::cout << "Folding with values from identifier " << id << ": ";
            for (const Value& v : it->second) {
                values.push_back(v.realVal);  // Extract the real value from the Value object
                std::cout << v.realVal << " ";  // Print each value in the list
            }
            std::cout << std::endl;
            $$ = evaluateFold($2, $3, values);  // Call evaluateFold with the extracted values
        } else {
            $$ = 0.0;  // Default to 0.0 if not found
        }
    }
  ;

direction:
    LEFT     { $$ = LEFT; }
  | RIGHT    { $$ = RIGHT; }
  ;

fold_op:
    Y_OP     { $$ = $1; }
  | SUBOP    { $$ = SUBOP; }
  | ADDOP    { $$ = ADDOP; }
;

expr_list:
    expression {
        $$ = new std::vector<Value>();
        $$->push_back(Value($1));  // Store the evaluated expression as a Value object
    }
  | expr_list COMMA expression {
      $$ = $1;
      $$->push_back(Value($3));  // Add more Value objects to the list
  }
;


primary:
    LPAREN expression RPAREN             { $$ = $2; }
  | INT_LITERAL                          { $$ = $1; }
  | REAL_LITERAL                         { $$ = $1; }
  | CHAR_LITERAL                         { $$ = $1; }
  | HEX_LITERAL                          { $$ = $1; }
  | IDENTIFIER LPAREN expression RPAREN  {
      std::cerr << "Function calls not implemented.\n";
      $$ = 0;
    }
  | IDENTIFIER {
      std::string id($1);
      if (symbolTable.find(id) != symbolTable.end()) {
          $$ = symbolTable[id];
      } else if (vectorTable.find(id) != vectorTable.end()) {
          const std::vector<Value>& vec = vectorTable[id];
          if (vec.empty()) {
              std::cerr << "Error: Cannot use an empty list as a scalar expression.\n";
              $$ = 0;
          } else {
              $$ = vec[0].realVal;
          }
      } else {
          std::cerr << "Error: Undeclared identifier '" << id << "'.\n";
          $$ = 0;
      }
    }
  | list {
      std::vector<Value>* vecPtr = $1;
      if (vecPtr->empty()) {
          std::cerr << "Error: Cannot use an empty list literal as a scalar expression.\n";
          $$ = 0;
      } else {
          // Optional: store it as an anonymous variable if needed later
          static int tempListCounter = 0;
          std::string tempName = "__temp_list_" + std::to_string(tempListCounter++);
          vectorTable[tempName] = *vecPtr;

          $$ = (*vecPtr)[0].realVal;
      }
      delete vecPtr;
    }
  ;




type:
    INTEGER | REAL | CHARACTER
  ;

%%

void yyerror(const char* message) {
  appendError(SYNTAX, message);
  std::cerr << "Error: " << message << std::endl;
}

int main(int argc, char* argv[]) {
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
