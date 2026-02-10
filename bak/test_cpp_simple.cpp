#include <stdio.h>
#include <vector>
#include <memory>
#include <algorithm>

// 简单的 C++ 程序，使用新特性但避免 iostream
int main() {
    printf("Hello from C++ program!\n");
    
    // 使用 C++14 特性
    auto vec = std::make_unique<std::vector<int>>();
    vec->push_back(1);
    vec->push_back(2);
    vec->push_back(3);
    
    printf("Vector size: %zu\n", vec->size());
    
    for (const auto& val : *vec) {
        printf("Value: %d\n", val);
    }
    
    // 使用 lambda
    std::for_each(vec->begin(), vec->end(), [](int x) {
        printf("Lambda value: %d\n", x * 2);
    });
    
    return 0;
}
