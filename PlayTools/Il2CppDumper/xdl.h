#ifndef ZYGISK_IL2CPPDUMPER_XDL_H
#define ZYGISK_IL2CPPDUMPER_XDL_H

#include <cstddef>

void *xdl_open(const char *filename, int flags);
void *xdl_sym(void *handle, const char *symbol, size_t *symbol_size);

#endif
