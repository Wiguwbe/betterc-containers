DMD := dmd

CONTAINERS := dlist slist tstree

SOURCES := $(patsubst %,containers/%.d,$(CONTAINERS))
BINS := $(patsubst %,bin/%,$(CONTAINERS))

.PHONY: tests docs coverage clean

tests: $(BINS)
	@mkdir -p cov
	@for file in $(BINS); do \
		./$$file --DRT-covopt="dstpath=cov"; \
	done

docs: $(SOURCES)
	$(DMD) -D -Dd=docs -main -unittest -o- $^

coverage: tests
	@for file in $(CONTAINERS); do \
		tail -1 cov/containers-$$file.lst; \
	done

bin/dlist: containers/dlist.d
bin/slist: containers/slist.d

bin/%: containers/%.d
	$(DMD) -g -unittest -cov -main $< -od=bin/ -of=$@

clean:
	rm -rf bin cov docs
