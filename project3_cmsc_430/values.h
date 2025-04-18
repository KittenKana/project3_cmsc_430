// values.h
#ifndef VALUES_H
#define VALUES_H

#include <unordered_map>
#include <string>
#include <vector>

extern std::unordered_map<std::string, double> symbolTable;
extern std::unordered_map<std::string, std::vector<double>> listTable;

void printSymbolTable();

double applyOp(const std::string& func, double left, double right);
double applyFoldLeft(const std::vector<double>& list, const std::string& func);
double applyFoldRight(const std::vector<double>& list, const std::string& func);

double evaluateFold(int direction, int op, const std::vector<double>& list);

double evaluateRelop(const char* op, double left, double right);
double applyAdd(double left, double right);
double applySub(double left, double right);
double applyMul(double left, double right);
double applyDiv(double left, double right);
double applyMod(double left, double right);
double applyExp(double left, double right);
double applyNeg(double val);

class Value {
    public:
        double realVal;
        int intVal;
        char charVal;
        std::vector<double> listVal;  // Store list values here
        bool isList;                  // Flag to indicate if it's a list
    
        Value(double val) : realVal(val), intVal(0), charVal(0), isList(false) {}
        Value(int val) : realVal(0), intVal(val), charVal(0), isList(false) {}
        Value(char val) : realVal(0), intVal(0), charVal(val), isList(false) {}
        Value(const std::vector<double>& list) : listVal(list), realVal(0), intVal(0), charVal(0), isList(true) {}
    
        std::vector<double> getListValues() const {
            return listVal;
        }
    };
    

#endif