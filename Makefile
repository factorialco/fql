.DEFAULT_GOAL := help # Sets default action to be help

define PRINT_HELP_PYSCRIPT # start of Python section
import re, sys

output = []
# Loop through the lines in this file
for line in sys.stdin:
    # if the line has a command and a comment start with
    #   two pound signs, add it to the output
    match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
    if match:
        target, help = match.groups()
        output.append("%-10s %s" % (target, help))
# Sort the output in alphanumeric order
output.sort()
# Print the help result
print('\n'.join(output))
endef
export PRINT_HELP_PYSCRIPT # End of python section

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

test: ## Run the tests
	bundle exec rspec

lint: rubocop sorbet ## Run all linters

rubocop: ## Run style checking
	bundle exec rubocop

sorbet: ## Typecheck the project
	bundle exec srb tc

parlour: ## Regenerate the public RBI file for library users
	bundle exec parlour

.PHONY: test lint rubocop sorbet
