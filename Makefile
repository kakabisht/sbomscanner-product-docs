.PHONY: all
all:
	@echo "Available targets:"
	@echo "  product-local            Build the local product docs site for local workstation test"
	@echo "  product-remote           Build the remote product docs site (as would happen on GH)"
	@echo "  preview                    Preview the local product docs site"
	@echo "  clean                      Clean build artifacts"
	@echo "  checkmake                  Check Makefile for common issues"
	@echo "  environment                Set up the Node.js environment"
	@echo "  tmpdir                     Create temporary directories"

.PHONY: product-local
product-local: tmpdir environment
	npx antora --version | tee tmp/build.log
	npx antora --stacktrace --log-format=pretty --log-level=info \
		sboms-playbook-local.yml \
		2>&1 | tee -a tmp/build.log
	@echo ""
	@echo "If your build was successful, you can preview the site with"
	@echo "'make preview'."
	@echo ""

.PHONY: product-remote
product-remote: tmpdir environment
	npx antora --version | tee tmp/build.log
	npx antora --stacktrace --log-format=pretty --log-level=info \
		sboms-playbook-remote.yml \
		2>&1 | tee -a tmp/build.log	
	@echo ""
	@echo "If your build was successful, you can preview the site with"
	@echo "'make preview'."
	@echo ""
	
.PHONY: clean
clean:
	rm -rf build*
	rm -rf tmp/*.log

NPM_FLAGS = --no-color --no-progress
.PHONY: environment
environment:
	npm $(NPM_FLAGS) ci || npm $(NPM_FLAGS) install

.PHONY: tmpdir
tmpdir:
	mkdir -p tmp

.PHONY: checkmake
checkmake:
	@if [ $$(which checkmake 2>/dev/null) ]; then \
		checkmake --config=tmp/checkmake.ini Makefile; \
		if [ $$? -ne 0 ]; then echo "checkmake failed"; exit 1; \
		else echo "checkmake passed"; \
		fi; \
	else echo "checkmake not available"; fi

.PHONY: preview
preview:
	npx http-server build/site -c-1

.PHONY: test
test:
