---
title: 'IPython shells with nix, updated'
date: 2016-11-03
tags:
  - Nix
  - Python
---

I've written about IPython shells with Nix [previously](https://theshortlog.com/2016/02/11/ipython-nix/).

One downside of relying on the nix-shell mechanism is that it uses environment variables, specifically `PYTHONPATH` which tends to be fragile when so much software insists on doing custom imports (e.g. gunicorn or Django).

Below is an alternative version for your `.bashrc` which builds something like a Python virtualenv and then sets `PYTHONHOME`. So far I've had less trouble with this new version:

<pre><code class="bash">function nix-ipython {
    packages=""
    for arg in $@; do
        packages="$packages $arg"
    done

    nix-shell -p "(python.buildEnv.override { extraLibs = with pythonPackages; [ ipython $packages ]; ignoreCollisions = true;})" --command ipython
}
</code></pre>
