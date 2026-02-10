#include <stdio.h>

// 一个简单的 C++ 类
class Calculator {
private:
    int value;
    
public:
    Calculator() : value(0) {}
    
    void add(int x) {
        value += x;
    }
    
    int getValue() const {
        return value;
    }
};

// 使用 C++14 特性：泛型 lambda
template<typename T>
T multiply(T a, T b) {
    return a * b;
}

int main() {
    printf("=== C++ 语言特性测试（无标准库依赖）===\n\n");
    
    // 测试类
    Calculator calc;
    calc.add(10);
    calc.add(20);
    printf("Calculator result: %d\n", calc.getValue());
    
    // 测试模板
    printf("Multiply 5 * 3 = %d\n", multiply(5, 3));
    printf("Multiply 2.5 * 4.0 = %.2f\n", multiply(2.5, 4.0));
    
    // 测试 auto 关键字 (C++11)
    auto x = 42;
    auto y = 3.14;
    printf("auto x = %d\n", x);
    printf("auto y = %.2f\n", y);
    
    // 测试数组遍历 (C++11)
    int arr[] = {1, 2, 3, 4, 5};
    printf("Array values: ");
    for (auto val : arr) {
        printf("%d ", val);
    }
    printf("\n");
    
    return 0;
}
