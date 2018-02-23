.PHONY: all graphs install

all: index.html graphs data.tar.gz

index.html: index.rst graphs
	rst2html $< $@

graphs: graphs.gp
	gnuplot graphs.gp

data.tar.gz: defconfig.out $(wildcard locstat*.txt)
	tar czf $@ $^

install: all
	scp index.html data.tar.gz $(wildcard *.png) \
	wildmoose@wildmoose.dk:~/public_html/header-bloat/
