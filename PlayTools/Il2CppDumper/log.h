#ifndef ZYGISK_IL2CPPDUMPER_LOG_H
#define ZYGISK_IL2CPPDUMPER_LOG_H

#include <cstdio>
#include <os/log.h>

#define LOGD(fmt, ...) \
    do { \
        std::printf("[Debug] " fmt "\n", ##__VA_ARGS__); \
        os_log_debug(OS_LOG_DEFAULT, fmt, ##__VA_ARGS__); \
    } while (0)

#define LOGW(fmt, ...) \
    do { \
        std::printf("[Warn] " fmt "\n", ##__VA_ARGS__); \
        os_log(OS_LOG_DEFAULT, fmt, ##__VA_ARGS__); \
    } while (0)

#define LOGE(fmt, ...) \
    do { \
        std::printf("[Error] " fmt "\n", ##__VA_ARGS__); \
        os_log_error(OS_LOG_DEFAULT, fmt, ##__VA_ARGS__); \
    } while (0)

#define LOGI(fmt, ...) \
    do { \
        std::printf("[Info] " fmt "\n", ##__VA_ARGS__); \
        os_log_info(OS_LOG_DEFAULT, fmt, ##__VA_ARGS__); \
    } while (0)

#endif
