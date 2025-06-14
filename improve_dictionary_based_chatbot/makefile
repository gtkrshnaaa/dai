

# Target to print a readable summary of all project files
resume:
	@find . -type f | sort | while read file; do \
		echo "===== $$file ====="; \
		if [ "$$file" = "./store/dictionary.json" ]; then \
			head -n 25 "$$file"; \
			echo "... (truncated)"; \
		else \
			cat "$$file"; \
		fi; \
		echo ""; \
	done
