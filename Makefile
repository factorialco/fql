all: test lint

test:
	bundle exec rspec

lint: rubocop sorbet

rubocop:
	bundle exec rubocop

sorbet:
	bundle exec srb tc

parlour:
	bundle exec parlour

.PHONY: test lint rubocop sorbet
