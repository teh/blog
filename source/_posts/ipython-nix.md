---
title: Quick IPython shells with nix-shell
date: 2016/2/11
tags:
  - Nix
  - Python
---

I often want to quickly experiment with a Python package without the
whole virtualenv shenanigans. For that I have an `ipython-nix` command
in my `.bashrc`:


<pre><code class="bash">function ipython-nix {
    packages=""
    for arg in $@; do
        packages="$packages $arg"
    done

    nix-shell -p "with pythonPackages; [ ipython $packages ]" --command ipython
}
</code></pre>


Using it requires knowledge of the nix-names for Python packages, but
those are generally very predictable. E.g.

<pre><code class="console">$ ipython-nix scikitlearn
these paths will be fetched (21.26 MiB download, 175.19 MiB unpacked):
  /nix/store/cgj5h0q0rwigcw4lb669y19l4swmvkxm-openblas-0.2.17
[...]
IPython 5.1.0 -- An enhanced Interactive Python.
?         -> Introduction and overview of IPython's features.
%quickref -> Quick reference.
help      -> Python's own help system.
object?   -> Details about 'object', use 'object??' for extra details.

In [1]: import sklearn.dummy as dummy

In [2]:
</code></pre>
