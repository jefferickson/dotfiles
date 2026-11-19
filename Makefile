.PHONY: nvim-install-tools nvim-lint-format

nvim-install-tools:
	brew install stylua selene

nvim-lint-format:
	cd nvim && stylua . && selene .
