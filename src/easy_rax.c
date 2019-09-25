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
radix_tree_new_it()
{
    raxIterator *it = malloc(sizeof(raxIterator));
    if (it == NULL) {
        return NULL;
    }

    return (void *)it;
}


int
radix_tree_destroy_it(void *it)
{
    if (it) {
        free(it);
    }

    return 0;
}


void *
radix_tree_search(void *t, void *it, const unsigned char *buf, size_t len)
{
    raxIterator *iter = (raxIterator *)it;
    if (it == NULL) {
        return NULL;
    }

    raxStart(iter, t);
    raxSeek(iter, "<=", (unsigned char *)buf, len);
    return (void *)iter;
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
    if (!it) {
        return 0;
    }

    raxStop(it);
    return 0;
}
