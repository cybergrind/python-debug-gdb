NAME := python-debug
.PHONY: image run test test-gil

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

test-gil: image
	@echo "=== Starting container ==="
	docker rm -f $(NAME)-gil 2>/dev/null || true
	docker run -d --name $(NAME)-gil --cap-add=SYS_PTRACE $(NAME) sleep infinity
	@echo "=== Launching GIL demo ==="
	docker exec -d $(NAME)-gil python /script/gil_demo.py
	@echo "=== Waiting for GIL contention ==="
	@for i in $$(seq 1 20); do \
		if docker exec $(NAME)-gil test -f /tmp/gil_demo_ready; then \
			echo "GIL demo ready, waiting for contention to build …"; \
			break; \
		fi; \
		if [ $$i -eq 20 ]; then \
			echo "ERROR: GIL demo did not start"; \
			docker logs $(NAME)-gil; \
			docker rm -f $(NAME)-gil; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@sleep 3
	@echo "=== Dumping backtrace ==="
	docker exec $(NAME)-gil bash -c '/script/dump_trace.sh $$(pgrep -of "python.*gil_demo")'
	@echo "=== Verifying process survived detach ==="
	@docker exec $(NAME)-gil pgrep -f gil_demo > /dev/null && echo "Process still alive"
	@echo "=== SUCCESS: GIL contention test passed ==="
	docker rm -f $(NAME)-gil
