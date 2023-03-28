ifneq (grouped-target, $(findstring grouped-target,$(.FEATURES)))
ERROR:=$(error This version of make does not support required 'grouped-target' (4.3+).)
endif

.DELETE_ON_ERROR:

# TODO: let's make the default 'testable' because we make 'combined' files which are time consumuing, but not necessary for testing purposes. Or, if we want to be persnickety, we might run a final test to double check that the combined files build correctly.
default: all

BUNDLES:=$(shell cd src && find . -name "*.*.sh") # e.g.: ./ui/colors.vars.sh
SRC_BUNDLES:=$(addprefix src/, $(BUNDLES)) # e.g.: dist/./ui/colors.vars.sh
DIST_BUNDLES:=$(addprefix dist/, $(BUNDLES)) # e.g.: dist/./ui/colors.vars.sh
PKG_BUNDLES:=$(addsuffix .pkg.sh, $(basename $(DIST_BUNDLES))) # e.g.: dist/./ui/colors.vars.pkg.sh

JS_SRC:=js
TEST_STAGING:=test-staging
TEST_JS_SRC_FILES:=$(shell find js -type f)
TEST_JS_BUILT_FILES:=$(patsubst js/%, $(TEST_STAGING)/%, $(TEST_JS_SRC_FILES))

SH_SRC_FILES:=$(shell find src -name "*.sh")

CATALYST_SCRIPTS:=npx catalyst-scripts
BASH_ROLLUP:=npx bash-rollup

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

# test
$(TEST_JS_BUILT_FILES) &: $(TEST_JS_SRC_FILES)
	JS_SRC=$(VERSIONING_SRC) $(CATALYST_SCRIPTS) pretest

last-test.txt: $(TEST_JS_BUILT_FILES) $(SH_SRC_FILES)
	# JS_SRC=$(TEST_STAGING) $(CATALYST_SCRIPTS) test | tee last-test.txt
	( set -e; set -o pipefail; \
		JS_SRC=$(TEST_STAGING) $(CATALYST_SCRIPTS) test 2>&1 | tee last-test.txt; )

test: last-test.txt

# lint rules
last-lint.txt: $(ALL_SRC_FILES)
	( set -e; set -o pipefail; \
		JS_LINT_TARGET=$(JS_SRC) $(CATALYST_SCRIPTS) lint | tee last-lint.txt; )

lint: last-lint.txt	

lint-fix:
	JS_LINT_TARGET=$(JS_SRC) $(CATALYST_SCRIPTS) lint-fix

qa: test lint

.PHONY: all clean lint lint-fix qa test
