---
title: Load balancing via iptables
date: 2012-3-09
tags: Devops
---

Traditionally balancing between web workers has been implemented with a prefork server. I.e. the controlling process opens a socket, forks a few workers who then `accept` on that socket. The kernel will distribute the load accordingly.

Another way to implement this is to use iptables‘ connection tracking. It has the advantage that web workers can be started and shut down independently. It is also trivial to distribute the load via weigths. The following redirects 10% of the connections to port 9000 to port 9002, and 90% to port 9001.

<pre><code class="bash">#!/bin/sh

sudo iptables -t mangle -F
sudo iptables -t nat -F
sudo iptables -F

sudo iptables -t nat -A OUTPUT -p tcp -j CONNMARK --set-mark 43
sudo iptables -t nat -A OUTPUT -p tcp -m statistic --mode random --probability 0.1 -j CONNMARK --set-mark 42

sudo iptables -t nat -A OUTPUT -p tcp --dport 9000 -m connmark --mark 42 -j DNAT --persistent --to 192.168.1.71:9001
sudo iptables -t nat -A OUTPUT -p tcp --dport 9000 -m connmark --mark 43 -j DNAT --persistent --to 192.168.1.71:9002
</code></pre>


This enables you to start a new, experimental worker and redirect only a fraction of all traffic to it to see how it behaves. If everything is fine you can ramp up the traffic in steps until it serves all requests. You can then disable the old worker.
