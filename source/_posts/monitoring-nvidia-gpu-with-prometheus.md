---
title: Monitoring your NVidia GPU with Prometheus
date: 2016/08/25
tags:
    - Devops
    - Haskell
---

I have a [deep learning box](https://pcpartpicker.com/user/pahLa6fi/saved/) that runs various computations on both CPU and GPU. The ability to off-load expensive computations from my laptop is fantastic.

I deploy my deep lerning box using [NixOps](https://github.com/NixOS/nixops), running Nix 16.09 and monitor it with [prometheus](https://prometheus.io).

I created a small tool, [nvidia-smi-prometheus](https://github.com/teh/nvidia-smi-prometheus) which runs as a service and reads the NVidia system stats every 10 seconds, and then exports them for prometheus.

(insert image from next time)
