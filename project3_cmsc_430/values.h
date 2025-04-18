// values.h
#ifndef VALUES_H
#define VALUES_H

#include <unordered_map>
#include <string>

extern std::unordered_map<std::string, double> symbolTable;

void printSymbolTable();


double evaluateRelop(const char* op, double left, double right);
double applyAdd(double left, double right);
double applySub(double left, double right);
double applyMul(double left, double right);
double applyDiv(double left, double right);
double applyMod(double left, double right);
double applyExp(double left, double right);
double applyNeg(double val);

#endif