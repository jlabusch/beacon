README.md: beacon
	@echo Updating README.md
	@./$< -h | \
        perl -p -e 's/^([A-Z][A-Z]+.*)$$/# $$1\n/'  | \
        sed 's/^    //' | \
        perl -p -e 's/(.*\[.*\[.*\[.*)/    $1/' > $@

