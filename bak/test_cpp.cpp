#include <iostream>
#include <vector>
#include <memory>

int main() {
    std::cout << "Hello from C++ program!" << std::endl;
    
    // 使用 C++11/14 特性
    auto vec = std::make_unique<std::vector<int>>();
    vec->push_back(1);
    vec->push_back(2);
    vec->push_back(3);
    
    for (const auto& val : *vec) {
        std::cout << "Value: " << val << std::endl;
    }
    
    return 0;
}
