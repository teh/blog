---
title: seccomp filters for NGINX
date: 2017-01-01
tags:
  - Linux
  - NGINX
---

Linux' BPF based [seccomp sandbox](https://en.wikipedia.org/wiki/Seccomp) is a reasonably powerful way to stop processes from running arbitrary syscalls when owned (or by accident).

sysemd supports setting seccomp filters with the [SystemCallFilter](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#SystemCallFilter=) attribute.

To figure out the exact list of calls that we need to white-list we can first use strace to record some data:


<pre><code class="bash">$ strace -qcf -p $(pgrep -f "nginx: work")

^C% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
100.00    0.000686           8        84           epoll_wait
  0.00    0.000000           0        93         4 write
[...]
  0.00    0.000000           0        13           pwritev
------ ----------- ----------- --------- --------- ----------------
100.00    0.000686                   576        65 total
</code></pre>

This list is usually not complete and we'll need some additional trial and error. NGINX will segfault when it uses a system call that isn't white-listed, and we'll see this in the logs via `journalctl -f`:

<pre><code class="bash">Jan 01 21:16:15 api audit[10102]: SECCOMP auid=4294967295 uid=0 gid=0 ses=4294967295 pid=10102 comm="nginx" exe="/nix/store/rsivvngv306f1dfyl3yq3pffvlnhisaj-nginx-1.10.1/bin/nginx" sig=31 arch=c000003e syscall=12 compat=0 ip=0x7f7796690f79 code=0x0
</code></pre>

We look up `syscall=12` in a [syscall table](https://filippo.io/linux-syscall-table/), and after some fairly mechanical updates I arrived at the following, long list:

<pre><code class="bash">SystemCallFilter=epoll_wait read write open close ioctl pread64 readv writev socket connect sendto recvfrom setsockopt getsockopt unlink gettimeofday epoll_ctl accept4 pwritev brk mmap access stat fstat mprotect arch_prctl set_tid_address set_robust_list rt_sigaction rt_sigprocmask getrlimit lseek uname geteuid poll recvmsg epoll_create futex getuid bind listen getsockname munmap mkdir fcntl pwrite64 socketpair clone setgid rt_sigsuspend setgroups wait4 setuid prctl eventfd2 io_setup io_destroy io_getevents io_submit io_cancel sendmsg setitimer shutdown sendfile
</code></pre>

It's still a pretty large attack surface, but better 65 calls than 313 calls!
