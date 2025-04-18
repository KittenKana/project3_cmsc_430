// values.cc
#include <cmath>
#include <cstring>
#include "values.h"
#include <iostream>

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

double applyDiv(double left, double right) { 
    if (right == 0) {
        // Handle division by zero appropriately
        // You could throw an exception, return NaN, or print an error message
        std::cerr << "Error: Division by zero!" << std::endl;
        return NAN; // Return NaN (Not-a-Number) to indicate an invalid operation
    }
    return left / right;
}

double applyMod(double left, double right) { return fmod(left, right); }
double applyExp(double left, double right) { return pow(left, right); }
double applyNeg(double val) { return -val; }