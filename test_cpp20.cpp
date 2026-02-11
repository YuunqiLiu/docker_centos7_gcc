#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <pthread.h>
#include <math.h>

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

// 线程函数 - 测试 pthread（会使用 GLIBC）
void* thread_function(void* arg) {
    int* num = (int*)arg;
    printf("   线程运行中，参数: %d\n", *num);
    return NULL;
}

// 测试文件 I/O（会使用 GLIBC）
void test_file_io() {
    printf("7. File I/O (uses GLIBC):\n");
    const char* filename = "/tmp/test_file.txt";
    FILE* fp = fopen(filename, "w");
    if (fp) {
        fprintf(fp, "Hello from GCC 14!\n");
        fclose(fp);
        printf("   写入文件成功: %s\n", filename);
        
        // 读取文件
        fp = fopen(filename, "r");
        if (fp) {
            char buffer[100];
            if (fgets(buffer, sizeof(buffer), fp)) {
                printf("   读取内容: %s", buffer);
            }
            fclose(fp);
        }
        remove(filename);
    }
    printf("\n");
}

// 测试时间函数（会使用 GLIBC）
void test_time_functions() {
    printf("8. Time functions (uses GLIBC):\n");
    time_t current_time = time(NULL);
    struct tm* local_time = localtime(&current_time);
    printf("   当前时间: %04d-%02d-%02d %02d:%02d:%02d\n",
           local_time->tm_year + 1900,
           local_time->tm_mon + 1,
           local_time->tm_mday,
           local_time->tm_hour,
           local_time->tm_min,
           local_time->tm_sec);
    printf("\n");
}

// 测试数学函数（会使用 libm，可能需要 GLIBC）
void test_math_functions() {
    printf("9. Math functions (uses libm/GLIBC):\n");
    double x = 2.0;
    printf("   sqrt(%.1f) = %.4f\n", x, sqrt(x));
    printf("   sin(%.1f) = %.4f\n", x, sin(x));
    printf("   log(%.1f) = %.4f\n", x, log(x));
    printf("   pow(%.1f, 3) = %.4f\n", x, pow(x, 3.0));
    printf("\n");
}

// 测试字符串函数（会使用 GLIBC）
void test_string_functions() {
    printf("10. String functions (uses GLIBC):\n");
    char str1[100] = "Hello";
    char str2[] = " World";
    strcat(str1, str2);
    printf("   strcat result: %s\n", str1);
    printf("   strlen: %zu\n", strlen(str1));
    
    char* token = strtok(str1, " ");
    printf("   strtok tokens: ");
    while (token != NULL) {
        printf("%s ", token);
        token = strtok(NULL, " ");
    }
    printf("\n\n");
}

// 测试动态内存（会使用 GLIBC）
void test_dynamic_memory() {
    printf("11. Dynamic memory (uses GLIBC):\n");
    int* arr = (int*)malloc(10 * sizeof(int));
    if (arr) {
        for (int i = 0; i < 10; i++) {
            arr[i] = i * i;
        }
        printf("   动态数组: ");
        for (int i = 0; i < 10; i++) {
            printf("%d ", arr[i]);
        }
        printf("\n");
        free(arr);
    }
    printf("\n");
}

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
    
    // 测试文件 I/O（GLIBC 依赖）
    test_file_io();
    
    // 测试时间函数（GLIBC 依赖）
    test_time_functions();
    
    // 测试数学函数（GLIBC/libm 依赖）
    test_math_functions();
    
    // 测试字符串函数（GLIBC 依赖）
    test_string_functions();
    
    // 测试动态内存（GLIBC 依赖）
    test_dynamic_memory();
    
    // 测试线程（pthread/GLIBC 依赖）
    printf("12. Threads (uses pthread/GLIBC):\n");
    pthread_t thread;
    int thread_arg = 42;
    if (pthread_create(&thread, NULL, thread_function, &thread_arg) == 0) {
        pthread_join(thread, NULL);
        printf("   线程执行完成\n");
    } else {
        printf("   线程创建失败\n");
    }
    printf("\n");
    
    printf("=== All C++20 features and GLIBC-dependent functions working! ===\n");
    
    return 0;
}
