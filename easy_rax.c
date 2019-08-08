#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include "rax.h"


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
radix_tree_search(void *t, const unsigned char *buf, size_t len)
{
    raxIterator *it = malloc(sizeof(raxIterator));
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

    fprintf(stderr, "it key len: %lu buf len: %lu, key: %s\n",
            iter->key_len, len, iter->key);

    if (iter->key_len > len ||
        memcmp(buf, iter->key, iter->key_len) != 0) {
        return NULL;
    }

    return iter->data;
}


int
radix_tree_stop(void *it)
{
    raxStop(it);
    return 0;
}
