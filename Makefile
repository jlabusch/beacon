README.md: beacon
	@echo Updating README.md
	@MARKDOWN=Y ./$< -h | \
        perl -p -e 's/^([A-Z][A-Z]+.*)$$/# $$1\n/'  | \
        sed 's/^    //' | \
        perl -pe 's/(.*\[.*\[.*\[.*)/    $$1/'| \
        perl -0pe 's/-\R([a-zA-Z0-9])/-$$1/gms' > $@

