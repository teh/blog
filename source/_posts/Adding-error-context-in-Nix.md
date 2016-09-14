---
title: Adding error context in Nix
date: 2016-10-03
tags:
---

I always have a tough time debugging Nix stack traces, especially when they occur deep in the module system.

Luckily there's a nice way to add error annotations to the stack trace to help debugging:

<pre><code class="bash">$ nix-instantiate \
    -E '(builtins.addErrorContext "Blame the assert!" (assert false; 10))' \
    --show-trace
error: Blame the assert!
assertion failed at (string):1:48
</code></pre>

or

<pre><code class="bash">$ nix-instantiate \
    -E '(builtins.addErrorContext "Blame the assert!" (throw "not this time"))' \
    -show-trace
error: Blame the assert!
not this time
</code></pre>


We're not using this a lot in in *nixpkgs*. Maybe we should use it more often!

<pre><code class="bash">$ git grep addErrorContext | wc -l
6
</code></pre>
