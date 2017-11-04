SHELL=/bin/bash

PREFIX ?= /usr/local
ALTPREFIX ?= $(HOME)/.local
DESTDIR ?=
BINDIR ?= /bin
MANDIR ?= /share/man
TMPDIR := $(shell mktemp -d --tmpdir "passphrase.XXXXXXXXXX")

all:
	@echo "RePassh by HacKan (https://hackan.net)"
	@echo "Commands for this makefile:"
	@echo "	install altinstall uninstall altuninstall lint"

install:
	install -v -d "$(DESTDIR)$(PREFIX)$(BINDIR)/" && \
		install -m 0755 -v "repassh.bash" "$(DESTDIR)$(PREFIX)$(BINDIR)/repassh"

uninstall:
	@rm -vrf \
		"$(DESTDIR)$(PREFIX)$(BINDIR)/repassh"

altinstall:
	install -v -d "$(DESTDIR)$(ALTPREFIX)$(BINDIR)/" && \
		install -m 0755 -v "repassh.bash" "$(DESTDIR)$(ALTPREFIX)$(BINDIR)/repassh"

altuninstall:
	@rm -vrf \
		"$(DESTDIR)$(ALTPREFIX)$(BINDIR)/repassh"

lint:
	shellcheck repassh.bash

.PHONY: install altinstall uninstall altuninstall lint
