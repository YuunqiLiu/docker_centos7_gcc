#include <stdio.h>

// C++20 Concepts - 简单的概念定义
template<typename T>
concept Numeric = requires(T t) {
    t + t;
    t * t;
    t - t;
    t / t;
};

template<Numeric T>
T multiply(T a, T b) {
    return a * b;
}

template<Numeric T>
T add(T a, T b) {
    return a + b;
}

// C++20 constexpr 增强
constexpr int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

// C++20 constexpr 计算
constexpr int compute_sum(int n) {
    int sum = 0;
    for (int i = 1; i <= n; ++i) {
        sum += i;
    }
    return sum;
}

// C++20 指定初始化
struct Config {
    int width;
    int height;
    const char* title;
};

// C++20 Lambda 捕获改进
void test_lambda_capture() {
    int x = 10;
    auto lambda = [=, y = x * 2]() {
        printf("   Lambda capture: x=%d, y=%d\n", x, y);
    };
    lambda();
}

// C++20 模板参数自动推导
template<auto N>
struct FixedSize {
    static constexpr auto value = N;
};

// C++20 consteval - 强制编译期求值
consteval int square(int n) {
    return n * n;
}

// C++20 constinit - 编译期初始化
constinit int global_value = factorial(5);

int main() {
    printf("=== C++20 Features Test ===\n\n");
    
    // 测试 Concepts - Numeric
    printf("1. Concepts:\n");
    printf("   multiply(5, 3) = %d\n", multiply(5, 3));
    printf("   multiply(2.5, 4.0) = %.2f\n", multiply(2.5, 4.0));
    printf("   add(10, 20) = %d\n", add(10, 20));
    printf("\n");
    
    // 测试 constexpr
    printf("2. Constexpr:\n");
    constexpr int fact5 = factorial(5);
    constexpr int sum = compute_sum(10);
    printf("   factorial(5) = %d (compile-time)\n", fact5);
    printf("   sum(1..10) = %d (compile-time)\n", sum);
    printf("\n");
    
    // 测试 consteval
    printf("3. Consteval (compile-time only):\n");
    constexpr int sq5 = square(5);
    constexpr int sq10 = square(10);
    printf("   square(5) = %d (consteval)\n", sq5);
    printf("   square(10) = %d (consteval)\n", sq10);
    printf("\n");
    
    // 测试 constinit
    printf("4. Constinit:\n");
    printf("   global_value = %d (constinit)\n", global_value);
    printf("\n");
    
    // 测试指定初始化
    printf("5. Designated initializers:\n");
    Config cfg = {
        .width = 1920,
        .height = 1080,
        .title = "Test Window"
    };
    printf("   Config: %dx%d, title='%s'\n", cfg.width, cfg.height, cfg.title);
    printf("\n");
    
    // 测试 Lambda 捕获
    printf("6. Lambda init-capture:\n");
    test_lambda_capture();
    printf("\n");
    
    // 测试模板参数 auto
    printf("7. Template parameter auto:\n");
    printf("   FixedSize<42>::value = %d\n", FixedSize<42>::value);
    printf("   FixedSize<'A'>::value = %c\n", FixedSize<'A'>::value);
    printf("\n");
    
    // 测试 auto 类型推导
    printf("8. Auto type deduction:\n");
    auto x = 42;
    auto y = 3.14;
    auto z = "Hello";
    printf("   auto x = %d\n", x);
    printf("   auto y = %.2f\n", y);
    printf("   auto z = %s\n", z);
    printf("\n");
    
    printf("=== All C++20 features working! ===\n");
    
    return 0;
}
