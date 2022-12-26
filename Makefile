.DELETE_ON_ERROR:

# TODO: let's make the default 'testable' because we make 'combined' files which are time consumuing, but not necessary for testing purposes. Or, if we want to be persnickety, we might run a final test to double check that the combined files build correctly.
default: all

BUNDLES:=$(shell cd src && find . -name "*.*.sh") # e.g.: ./ui/colors.vars.sh
SRC_BUNDLES:=$(addprefix src/, $(BUNDLES)) # e.g.: dist/./ui/colors.vars.sh
DIST_BUNDLES:=$(addprefix dist/, $(BUNDLES)) # e.g.: dist/./ui/colors.vars.sh
PKG_BUNDLES:=$(addsuffix .pkg.sh, $(basename $(DIST_BUNDLES))) # e.g.: dist/./ui/colors.vars.pkg.sh

BASH_ROLLUP:=npm exec bash-rollup

all: $(DIST_BUNDLES) $(PKG_BUNDLES)

clean:
	rm -rf dist

# We could explicitly specify all the depenncies, but let's keep it simple. This will perform unecessary builds.
$(PKG_BUNDLES): dist/%.pkg.sh: src/%.sh $(SRC_BUNDLES)
	mkdir -p $(dir $@)
	$(BASH_ROLLUP) $< $@

$(DIST_BUNDLES): dist/%: src/%
	mkdir -p $(dir $@)
	cp $< $@

.PHONY: all clean
