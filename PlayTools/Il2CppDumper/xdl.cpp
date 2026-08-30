#include "xdl.h"
#include <string>
#include <mach-o/dyld.h>
#include <dlfcn.h>

void *xdl_open(const char *filename, int flags) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; ++i) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, filename)) {
            return (void*)dlopen(name, RTLD_NOW);
        }
    }
    return NULL;
}

void *xdl_sym(void *handle, const char *symbol, size_t *symbol_size) {
    return dlsym(handle, symbol);
}
