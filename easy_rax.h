#ifndef LUA_RESTY_RADIXTREE_H
#define LUA_RESTY_RADIXTREE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>
#include <ctype.h>
#include "rax.h"


#ifdef BUILDING_SO
    #ifndef __APPLE__
        #define LSH_EXPORT __attribute__ ((visibility ("protected")))
    #else
        /* OSX does not support protect-visibility */
        #define LSH_EXPORT __attribute__ ((visibility ("default")))
    #endif
#else
    #define LSH_EXPORT
#endif

/* **************************************************************************
 *
 *              Export Functions
 *
 * **************************************************************************
 */

void *radix_tree_new();
int radix_tree_destroy(void *t);
int radix_tree_insert(void *t, const unsigned char *buf, size_t len,
    void *data);
void *radix_tree_search(void *t, const unsigned char *buf, size_t len);
void *radix_tree_pcre(void *it, const unsigned char *buf, size_t len);
void *radix_tree_next(void *it, const unsigned char *buf, size_t len);
int radix_tree_stop(void *it);

typedef struct {
    unsigned int   val;
    int            bit;
} ip_addr_item;

int is_valid_ipv4(const char *ipv4);
int is_valid_ipv6(const char *ipv6);
int parse_ipv6(const char *ipv6, ip_addr_item *addr_items);

#ifdef __cplusplus
}
#endif

#endif
