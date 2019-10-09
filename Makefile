INST_PREFIX ?= /usr
INST_LIBDIR ?= $(INST_PREFIX)/lib/lua/5.1
INST_LUADIR ?= $(INST_PREFIX)/share/lua/5.1
INSTALL ?= install
UNAME ?= $(shell uname)

CFLAGS := -O2 -g -Wall -fpic -std=c99 -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast

C_SO_NAME := librestyradixtree.so
LDFLAGS := -shared

# on Mac OS X, one should set instead:
# for Mac OS X environment, use one of options
ifeq ($(UNAME),Darwin)
	LDFLAGS := -bundle -undefined dynamic_lookup
	C_SO_NAME := librestyradixtree.dylib
endif

MY_CFLAGS := $(CFLAGS) -DBUILDING_SO
MY_LDFLAGS := $(LDFLAGS) -fvisibility=hidden

OBJS := src/rax.o src/easy_rax.o

.PHONY: default
default: compile

### test:         Run test suite. Use test=... for specific tests
.PHONY: test
test: compile
	TEST_NGINX_LOG_LEVEL=info \
	prove -I../test-nginx/lib -r -s t/


### clean:        Remove generated files
.PHONY: clean
clean:
	rm -f $(C_SO_NAME) $(OBJS) ${R3_CONGIGURE}


### compile:      Compile library
.PHONY: compile

compile: ${R3_FOLDER} ${R3_CONGIGURE} ${R3_STATIC_LIB} $(C_SO_NAME)

${OBJS} : %.o : %.c
	$(CC) $(MY_CFLAGS) -c $< -o $@

${C_SO_NAME} : ${OBJS}
	$(CC) $(MY_LDFLAGS) $(OBJS) -o $@


### install:      Install the library to runtime
.PHONY: install
install:
	$(INSTALL) -d $(INST_LUADIR)/resty/
	$(INSTALL) lib/resty/*.lua $(INST_LUADIR)/resty/
	$(INSTALL) $(C_SO_NAME) $(INST_LIBDIR)/


### dev:          Create a development ENV
.PHONY: dev
dev:
ifeq ($(UNAME),Darwin)
	luarocks install --lua-dir=$(LUA_JIT_DIR) rockspec/lua-resty-radixtree-dev-1.0-0.rockspec --only-deps
else ifneq ($(LUAROCKS_VER),'luarocks 3.')
	luarocks install rockspec/lua-resty-radixtree-dev-1.0-0.rockspec --only-deps
else
	luarocks install --lua-dir=/usr/local/openresty/luajit rockspec/lua-resty-radixtree-dev-1.0-0.rockspec --only-deps
endif


### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
