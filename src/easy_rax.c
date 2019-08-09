#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "easy_rax.h"


void *
radix_tree_new()
{
    return (void *)raxNew();
}


int
radix_tree_destroy(void *t)
{
    if (t == NULL) {
        return 0;
    }

    raxFree(t);
    return 0;
}


int
radix_tree_insert(void *t, const unsigned char *buf, size_t len, void *data)
{
    if (t == NULL) {
        return -1;
    }

    if (buf == NULL) {
        return -2;
    }

    return raxInsert((rax *)t, (unsigned char *)buf, len, data, NULL);
}


void *
radix_tree_find(void *t, const unsigned char *buf, size_t len)
{
    if (t == NULL) {
        return NULL;
    }

    if (buf == NULL) {
        return NULL;
    }

    return raxFind((rax *)t, (unsigned char *)buf, len);
}


void *
radix_tree_search(void *t, const unsigned char *buf, size_t len)
{
    raxIterator *it = malloc(sizeof(raxIterator));
    if (it == NULL) {
        return NULL;
    }

    raxStart(it, t);
    raxSeek(it, "<=", (unsigned char *)buf, len);
    return (void *)it;
}


void *
radix_tree_next(void *it, const unsigned char *buf, size_t len)
{
    raxIterator    *iter = it;

    int res = raxNext(iter);
    if (!res) {
        return NULL;
    }

    // fprintf(stderr, "it key len: %lu buf len: %lu, key: %.*s\n",
    //         iter->key_len, len, (int)iter->key_len, iter->key);

    if (iter->key_len > len ||
        memcmp(buf, iter->key, iter->key_len) != 0) {
        return NULL;
    }

    return iter->data;
}


void *
radix_tree_pcre(void *it, const unsigned char *buf, size_t len)
{
    raxIterator    *iter = it;
    int             res;

    while (1) {
        res = raxPrev(iter);
        if (!res) {
            return NULL;
        }

        if (iter->key_len > len ||
            memcmp(buf, iter->key, iter->key_len) != 0) {
            continue;
        }

        break;
    }

    return iter->data;
}


int
radix_tree_stop(void *it)
{
    raxStop(it);
    return 0;
}


int
is_valid_ipv4(const char *ipv4)
{
    struct      in_addr addr;

    if(ipv4 == NULL) {
        return -1;
    }

    if(inet_pton(AF_INET, ipv4, (void *)&addr) != 1) {
        return -1;
    }

    return 0;
}


int
is_valid_ipv6(const char *ipv6)
{
    struct in6_addr addr6;

    if(ipv6 == NULL) {
        return -1;
    }

    if(inet_pton(AF_INET6, ipv6, (void *)&addr6) != 1) {
        return -1;
    }

    return 0;
}

int
parse_ipv6(const char *ipv6, unsigned int *addr_32)
{
    unsigned int       addr6[4];
    int                i;

    if(ipv6 == NULL) {
        return -1;
    }

    if(inet_pton(AF_INET6, ipv6, (void *)addr6) != 1) {
        return -1;
    }

    for (i = 0; i < 4; i++) {
        addr_32[i] = ntohl(addr6[i]);
    }

    return 0;
}
