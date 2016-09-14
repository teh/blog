---
title: Deep-learning Python environment with Nix
date: 2016-08-10
tags: ML
---

Getting the deep learning environment with all NVidia libaries set up is a bit fiddly. Thankfully I can lean on Nix for that as well. I have a package definition like this (`dl.nix`):

<pre><code class="nix">{ python, pythonPackages, gcc, cudatoolkit75, cudnn5_cudatoolkit75 }:

python.buildEnv.override {
  extraLibs = with pythonPackages; [
    (Keras.override { propagatedBuildInputs = [ Theano-cuda six pyyaml future ];  })
    ipython
    notebook
  ];
  extraPaths = [ gcc cudatoolkit75 cudnn5_cudatoolkit75 ];
  ignoreCollisions = true;
}
</code></pre>

(Note that this needs [this branch](https://github.com/NixOS/nixpkgs/pull/18273) in your nixpkgs. I'm hoping it'll be merged soon.)

With that in place it's trivial to drop into a nix-shell that then has a python to run your nix code:

<pre><code class="bash">$ nix-shell -p "callPackage ./dl.nix {}"
</code></pre>

I'm also still on Theano rather than Tensorflow because I find it easier to debug. Tensorflow available in nixpkgs though if you prefer that.
