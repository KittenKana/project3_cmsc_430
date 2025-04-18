#include <cmath>
#include <cstring>
#include "values.h"
#include <iostream>
#include <functional>
#include <stdexcept>
#include <unordered_map>
#include <vector>
#include <string>

// External symbol table (declared in parser.y)
extern std::unordered_map<std::string, double> symbolTable;

#define LEFT 0
#define RIGHT 1

void printSymbolTable() {
    std::cout << "Symbol Table:\n";
    for (const auto& entry : symbolTable) {
        std::cout << entry.first << " = " << entry.second << "\n";
    }
}

// Operator helper
double applyOp(const std::string& func, double left, double right) {
    if (func == "ADD") return left + right;
    if (func == "SUB") return left - right;
    if (func == "MUL") return left * right;
    if (func == "DIV") return right != 0 ? left / right : 0;
    if (func == "MOD") return static_cast<int>(left) % static_cast<int>(right);
    if (func == "EXP") return pow(left, right);
    return 0.0;
}


double evaluateFold(int direction, int op, const std::vector<double>& list) {
    std::string opStr;
    switch (op) {
        case 0:  opStr = "ADD"; break;
        case 1:  opStr = "SUB"; break;
        case 2:  opStr = "MUL"; break;
        case 3:  opStr = "DIV"; break;
        case 4:  opStr = "MOD"; break;
        case 5:  opStr = "EXP"; break;
        default: opStr = "ADD"; break;
    }

    std::cout << "Operation: " << opStr << std::endl;

    if (list.empty()) {
        std::cout << "List is empty. Returning 0.0" << std::endl;
        return 0.0;
    }

    if (direction == LEFT) {
        double result = list[0];
        std::cout << "Initial result: " << result << std::endl;

        for (size_t i = 1; i < list.size(); ++i) {
            std::cout << "Applying " << opStr << " to result = " << result << " and list[" << i << "] = " << list[i] << std::endl;
            result = applyOp(opStr, result, list[i]);
            std::cout << "New result: " << result << std::endl;
        }
        return result;
    } else { // RIGHT fold: use recursion to apply operation from the right
        std::function<double(size_t)> foldRight;
        foldRight = [&](size_t index) -> double {
            if (index == list.size() - 1) {
                std::cout << "Base case reached, returning list[" << index << "] = " << list[index] << std::endl;
                return list[index];
            }
            double rightResult = foldRight(index + 1);
            std::cout << "Applying " << opStr << " to list[" << index << "] = " << list[index] << " and rightResult = " << rightResult << std::endl;
            return applyOp(opStr, list[index], rightResult);
        };

        return foldRight(0);
    }
}



// Relational operators
double evaluateRelop(const char* op, double left, double right) {
    if (strcmp(op, "=") == 0) return left == right;
    if (strcmp(op, "<>") == 0 || strcmp(op, "/=") == 0) return left != right;
    if (strcmp(op, "<") == 0) return left < right;
    if (strcmp(op, "<=") == 0) return left <= right;
    if (strcmp(op, ">") == 0) return left > right;
    if (strcmp(op, ">=") == 0) return left >= right;
    return 0.0;
}

// Arithmetic operators
double applyAdd(double left, double right) { return left + right; }
double applySub(double left, double right) { return left - right; }
double applyMul(double left, double right) { return left * right; }

double applyDiv(double left, double right) {
    if (right == 0) {
        std::cerr << "Runtime error: Division by zero.\n";
        return 0.0;
    }
    return left / right;
}

double applyMod(double left, double right) {
    int l = static_cast<int>(left);
    int r = static_cast<int>(right);
    if (r == 0) {
        std::cerr << "Runtime error: Modulus by zero.\n";
        return 0.0;
    }
    return l % r;
}

double applyExp(double left, double right) {
    return pow(left, right);
}

double applyNeg(double val) {
    return -val;
}
