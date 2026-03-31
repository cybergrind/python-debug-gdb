NAME := python-debug
.PHONY: image run test

image:
	docker build -t $(NAME) .

run:
	docker run -it --rm --name $(NAME) --cap-add=SYS_PTRACE $(NAME) /bin/bash

test: image
	@echo "=== Starting container ==="
	docker rm -f $(NAME)-test 2>/dev/null || true
	docker run -d --name $(NAME)-test --cap-add=SYS_PTRACE $(NAME)
	@echo "=== Waiting for server ==="
	@for i in $$(seq 1 30); do \
		if docker exec $(NAME)-test curl -sf http://localhost:8000/health >/dev/null 2>&1; then \
			echo "Server ready"; \
			break; \
		fi; \
		if [ $$i -eq 30 ]; then \
			echo "ERROR: Server did not start"; \
			docker logs $(NAME)-test; \
			docker rm -f $(NAME)-test; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@echo "=== Dumping backtrace ==="
	docker exec $(NAME)-test /script/dump_trace.sh
	@echo "=== Verifying server still works after detach ==="
	docker exec $(NAME)-test curl -sf http://localhost:8000/health
	@echo ""
	@echo "=== SUCCESS: Server survived GDB detach ==="
	docker rm -f $(NAME)-test
