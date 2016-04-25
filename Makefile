
# Some utility functions stolen from the Linux kernel build system,
# and slightly modified.

TMPDIR ?= /tmp

try-run = $(shell set -e;               \
        TMP="$(TMPDIR)/.$$$$.tmp";      \
        TMPO="$(TMPDIR)/.$$$$.o";       \
        if ($(1)) >/dev/null 2>&1;      \
        then echo "$(2)";               \
        else echo "$(3)";               \
        fi;                             \
        rm -f "$$TMP" "$$TMPO")

# Unknown warning options are not fatal be default with clang, so use -Werror.
cc-option = $(call try-run,\
        $(CC) $(CPPFLAGS) -Werror $(1) -c -x c /dev/null -o "$$TMPO",$(1),$(2))



CWARN := -Wall -Wextra
CWARN += -Wmissing-prototypes
CWARN += -Wunused-parameter 
CWARN += -Wfloat-equal
CWARN += -Wpointer-arith
CWARN += -Wshadow

CWARN += $(call cc-option,-Wlogical-op,)
CWARN += $(call cc-option,-Wmissing-parameter-type,)
CWARN += $(call cc-option,-Wsuggest-attribute=pure,)
CWARN += $(call cc-option,-Wsuggest-attribute=const,)
CWARN += $(call cc-option,-Wsuggest-attribute=format,)
CWARN += $(call cc-option,-Wnewline-eof,)

CPPFLAGS := -D_GNU_SOURCE
CFLAGS = -std=gnu99 -O2 -g $(CWARN)

LDFLAGS = 
LDLIBS = 

depssuffix := deps

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MF $(dir $*).$(notdir $*).$(depssuffix) -c -o $@ $<

%: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $^ $(LDFLAGS)


all: cident

cident: LDFLAGS += -lsparse
cident: CWARN += $(call cc-option,-Wno-override-init,)
cident: CWARN += $(call cc-option,-Wno-initializer-overrides,)

