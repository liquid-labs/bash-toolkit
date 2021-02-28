.DELETE_ON_ERROR:

default: all

BUNDLES:=$(shell cd src && find . -name "*.*.sh") # BUNDLES is a list with items like './ui/colors.vars.sh'
DIST_BUNDLES:=$(addprefix dist/, $(BUNDLES)) # DIST_BUNDLES like 'dist/./ui/colors.vars.sh'
SRC_BUNDLES:=$(addprefix src/, $(BUNDLES)) # DIST_BUNDLES like 'dist/./ui/colors.vars.sh'

BASH_ROLLUP:=$(shell npm bin)/bash-rollup

all: $(DIST_BUNDLES)

clean: rm -rf dist

# dist/%: src/% $(SRC_BUNDLES)
#	mkdir -p $(dir $@)
#	$(BASH_ROLLUP) $< $@

# We could explicitly specify all the depenncies, but let's keep it simple.
$(DIST_BUNDLES): dist/%: src/%
	mkdir -p $(dir $@)
	$(BASH_ROLLUP) $< $@

# include $(DIST_BUNDLES)

.PHONY: all clean
