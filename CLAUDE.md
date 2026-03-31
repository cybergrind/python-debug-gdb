

I want to create container to debug python with gdb.
Put all scripts into `script/` directory

- it should have gdb installed
- it should have python debug symbols already inside
- it should have uv installed
- it should have script that has `uv` header that install dependencies, that starts simple fastapi server, we want to run our server with gunicorn, number of workers=1
- it should have script that connects to the worker (not master gunicorn) and dump backtrace of ALL threads to stdout and then detaches from the process
- process should work after the detach
- backtrace must have python stracktrace alongside with C stacktrace
- image should already have all required symbols embedded during build process
- image should already have all required python libraries embedded during build process
- docker probably should be started with capability to ptrace


#### work process

We want to follow agentic mode with minimal user intrusion. So, try to make working loop relaying on the calling commands from `Makefile`, to avoid many requests for permissions to perform some actions
Try to make end-to-end test functions inside `Makefile` and improve tests step-by-step

