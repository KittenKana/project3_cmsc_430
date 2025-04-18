// values.cc
#include <cmath>
#include <cstring>
#include "values.h"

double evaluateRelop(const char* op, double left, double right) {
    if (strcmp(op, "=") == 0) return left == right;
    if (strcmp(op, "<>") == 0 || strcmp(op, "/=") == 0) return left != right;
    if (strcmp(op, "<") == 0) return left < right;
    if (strcmp(op, "<=") == 0) return left <= right;
    if (strcmp(op, ">") == 0) return left > right;
    if (strcmp(op, ">=") == 0) return left >= right;
    return 0.0;
}

double applyAdd(double left, double right) { return left + right; }
double applySub(double left, double right) { return left - right; }
double applyMul(double left, double right) { return left * right; }
double applyDiv(double left, double right) { return right != 0 ? left / right : 0; }
double applyMod(double left, double right) { return fmod(left, right); }
double applyExp(double left, double right) { return pow(left, right); }
double applyNeg(double val) { return -val; }