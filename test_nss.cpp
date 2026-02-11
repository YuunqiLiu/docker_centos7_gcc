#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>
#include <dlfcn.h>

// 测试 NSS（Name Service Switch）- 这会导致无法完全静态链接
void test_getaddrinfo() {
    printf("1. 测试 getaddrinfo (使用 NSS，无法完全静态化):\n");
    
    struct addrinfo hints = {0};
    struct addrinfo *result = NULL;
    
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    
    // 尝试解析域名 - 这需要 NSS 库
    int ret = getaddrinfo("www.baidu.com", "80", &hints, &result);
    if (ret == 0) {
        printf("   ✓ getaddrinfo 成功解析域名\n");
        
        char ip[INET_ADDRSTRLEN];
        struct sockaddr_in *addr = (struct sockaddr_in *)result->ai_addr;
        inet_ntop(AF_INET, &addr->sin_addr, ip, sizeof(ip));
        printf("   IP 地址: %s\n", ip);
        
        freeaddrinfo(result);
    } else {
        printf("   ✗ getaddrinfo 失败: %s\n", gai_strerror(ret));
    }
    printf("\n");
}

// 测试 gethostbyname - 也依赖 NSS
void test_gethostbyname() {
    printf("2. 测试 gethostbyname (使用 NSS):\n");
    
    struct hostent *host = gethostbyname("www.baidu.com");
    if (host != NULL) {
        printf("   ✓ gethostbyname 成功\n");
        printf("   主机名: %s\n", host->h_name);
        
        if (host->h_addr_list[0] != NULL) {
            char ip[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, host->h_addr_list[0], ip, sizeof(ip));
            printf("   IP 地址: %s\n", ip);
        }
    } else {
        printf("   ✗ gethostbyname 失败\n");
    }
    printf("\n");
}

// 测试 dlopen - 动态加载库
void test_dlopen() {
    printf("3. 测试 dlopen (动态加载，静态链接时会失败):\n");
    
    // 尝试加载 libm.so
    void *handle = dlopen("libm.so.6", RTLD_LAZY);
    if (handle != NULL) {
        printf("   ✓ dlopen 成功加载 libm.so.6\n");
        
        // 尝试获取 sqrt 函数
        typedef double (*sqrt_func)(double);
        sqrt_func sqrt_ptr = (sqrt_func)dlsym(handle, "sqrt");
        if (sqrt_ptr != NULL) {
            printf("   ✓ dlsym 成功获取 sqrt 函数\n");
            printf("   sqrt(16.0) = %.2f\n", sqrt_ptr(16.0));
        }
        
        dlclose(handle);
    } else {
        printf("   ✗ dlopen 失败: %s\n", dlerror());
        printf("   （这是正常的，因为静态链接无法动态加载库）\n");
    }
    printf("\n");
}

// 测试基本 socket（这个通常可以静态链接）
void test_socket() {
    printf("4. 测试 socket 创建:\n");
    
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock >= 0) {
        printf("   ✓ socket 创建成功 (fd=%d)\n", sock);
        close(sock);
    } else {
        printf("   ✗ socket 创建失败\n");
    }
    printf("\n");
}

int main() {
    printf("=== 测试无法完全静态化的 GLIBC 功能 ===\n");
    printf("这些功能依赖 NSS (Name Service Switch) 和动态加载机制\n");
    printf("\n");
    
    test_getaddrinfo();
    test_gethostbyname();
    test_dlopen();
    test_socket();
    
    printf("=== 测试完成 ===\n");
    printf("\n");
    printf("说明:\n");
    printf("- getaddrinfo/gethostbyname 依赖 NSS 库 (libnss_*.so)\n");
    printf("- 静态链接后，这些功能可能无法工作或需要运行时的 .so 文件\n");
    printf("- 用 'ldd' 可能看不到依赖，但运行时仍会尝试加载 NSS 库\n");
    
    return 0;
}
