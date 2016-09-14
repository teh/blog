---
title: NixOS security-updates update
date: 2016-10-01
tags: Nix
---

This weekend Nicolas Pierron ([nbp](http://github.com/nbp) on GitHub) came to London for a NixOS hackathon. He's been working on improving security updates in NixOS for a while. He's the author of the [NixOS module system](http://nixos.org/nixos/manual/index.html#sec-modularity) amongst other things. He has a successful track record of complex, tree-wide changes so if anyone can nail this, it's him.

The main output of our weekend is this blog post with his ideas.


## Problem description

**Problem tl;dr:** It takes too damn long before security updates arrive on end-user machines or servers.



A quick recap of how NixOS currently works. Let's work in a small universe with just *libc*, *openssl* and *nginx* in it. *openssl* depends on *libc*, and *nginx* depends on *openssl*, and *nginx* also depends on *libc* via *openssl*:

{% img "img-thumbnail" /images/nixos-security-updates-upadate/base-case.svg "Normal case" %}


Now lets assume that we have a critical bug in *libc*:

{% img "img-thumbnail" /images/nixos-security-updates-upadate/libc-bug.svg  "libc bug" %}


In Nix each package specifies *all* dependecies explicitly. There is no shared library in `/lib`, but instead one in

`/nix/store/gwl3ppqj4i730nhd4f50ncl5jc4n97ks-glibc-2.23`

In a global-state system like Debian all one needs to do is replace *libc* in `/lib`. All programs read `/lib` and will therefore be fixed after the next restart.

In Nix we need to update **all dependencies** to point to the fixed *libc*. This is done via a full re-build. I.e. every downstream dependency is re-compiled:

{% img "img-thumbnail" /images/nixos-security-updates-upadate/libc-bug-rebuilds.svg "" %}

**This is a problem.** A full rebuild of our 30k+ packages takes several days. If you want the critical security fix faster you need to compile on your local machine.


## Solution constraints

Before we describe Nicolas' solution let's enumerate some constraints:

* Must be transparent to end-users
* Must be much faster than full rebuild
* Must work on Hydra
* Must work for nix-env and nix-shell, not just nix-channels
* No overhead for package maintainers


## Current solution

Right now NixOS has `replaceDependencies` and `replaceRuntimeDependencies` which are not easy to understand, and therefore rarely used by maintainers. I won't go into details because the adaption shows that this is a non-solution.

As a result there now is a [nixos-small](https://github.com/NixOS/nixpkgs/blob/master/nixos/release-small.nix) channel that contains a small subset of packages that rebuild quickly.


## Proposed solution

The problem is that recompiling all packages takes a long time. Therefore the solution must be to avoid re-compiling all packages! Security updates are usually ABI compatible which makes this a reasonable idea. Otherwise Debian could not work.

In order to avoid re-compilation we can copy a package, and then adjust all pointers within it. Pointers follow a rigid naming scheme, namely `$hash-$name`, e.g. `/nix/store/f4gxsj6pn4ygqadwyk2m6xg1ywhfwxg1-openssl-1.0.2h`. For this rigid naming a regular expression replacement does the job.

The scheme looks like this:

{% img "img-thumbnail" /images/nixos-security-updates-upadate/what-we-want.svg "" %}

If you only care about using this new tech then you can stop reading here.


# Implementation details

It took Nicolas an entire afternoon to explain this one so get buckled in. I am using my own words and understanding of his ideas in the hope that the translation requires less brain power than Nicolas has at his disposal.

First, we need to rebuild all buggy packages. In our example above that's just *libc*, but the solution needs to work for more than one package.

For this specific example: We have to rebuild *libc* somehow while avoiding rebuilding anything else immediately.

### Fixed-point digression

Fixed-points are used extensively in NixOS. A fixpoint is a mathematical concept that means "apply a function to its own output until the output no longer changes". I.e. `f(x) == x`. Computers can use fixed points in combination with lazy evaluation. If nothing is left to evaluate then we have reached the fixed point.

The trivial example is the constant function *f(x) = x*:

<pre><code class="js">f("hello") = "hello"
</code></pre>


A Nix example taken [from here](http://lethalman.blogspot.co.uk/2014/11/nix-pill-17-nixpkgs-overriding-packages.html) is the following function of one argument, `x`:

<pre><code class="nix">f = x: { a = 3; b = 4; c = x.a + x.b; }
</code></pre>


By filling in `x` with the output of f(x) we get (not valid Nix syntax):

<pre><code class="nix">f = x: { a = 3; b = 4; c = f(x).a + f(x).b; }
=> f = x: { a = 3; b = 4; c = { a = 3; b = 4; c = x.a + x.b; }.a  # [2]
                            + { a = 3; b = 4; c = x.a + x.b; }.b; }
=> f = x: { a = 3; b = 4; c = 3 + 4; }
=> f = x: { a = 3; b = 4; c = 7; }
</code></pre>


Crucially, in line 2 the `.a` and `.b` accessors no longer reference `c`. That means the evaluator can return a value without looking at `x`. And because `x` really is `f(x)` the evaluator doesn't have to evaluate `f(x)` again, thus breaking the loop.

In a strict language the evaluator would try to calculate `x` again and loop forever.

<hr>

*nixpkgs* is a giant function that describes all packages in Nix - returning nested attribute sets. We can change an individual package via [`packageOverrides`](https://nixos.org/nixpkgs/manual/#sec-modify-via-packageOverrides).

`packageOverrides` is a fixpoint of *nixpkgs*. To see why this is the case we go back to our small universe:

{% img "img-thumbnail" /images/nixos-security-updates-upadate/base-case.svg "Normal case" %}

The *nixpkgs* attribute set would be a function:

<pre><code class="nix">nixpkgs: {
  libc = { ... };
  openssl = { nixpkgs.libc }: { ... };
  nginx = { nixpkgs.openssl }: { ... };
}
</code></pre>

If I replace *libc* with *libc-fixed* in this attribute set then *openssl* will still be getting the old *libc* via the *nixpkgs* argument.

<pre><code class="nix">nixpkgs: {
  libc = libc-fixed;
  openssl = { nixpkgs.libc }: { ... }; # nixpkgs does not yet contain nixpkgs.libc-fixed
  nginx = { nixpkgs.openssl }: { ... };
}
</code></pre>


If we calculate the fixed point, then in the next iteration *nixpks* will contain *libc-fixed*, updating *openssl*. The final iteration will update *nginx* because now *nixpkgs* contains an updated *openssl*. So the updates steps are:

1. *libc*
2. *libc*, *openssl*
3. *libc*, *openssl*, *nginx*

This is the end of the fixpoint digression. Apart from an intuition for fixpoints there is one more takeaway: Our fixpoint evaluation operates one step at a time

### One step a time

As we just saw fixed point evaluation in *nixpkgs* proceeds one "step" at a time. If you imagine the tree of dependencies, then the depth of that tree is the total number of steps.

Going back to our initial problem:

> We have to rebuild *libc* somehow while avoiding rebuilding anything else immediately.

The solution is easy: We run only a single step of our fixed point iteration. By running only one step we only rebuild *libc-fixed*.

Two notes:

* This also works for updating N packages.
* We will run this step on Hydra as well, so *libc-fixed* will be available in binary form very quickly.


### Copy & fixup instead of rebuild

We can now rebuild individual, buggy packages without rebuilding everything. But we still need to adjust the dependency pointers in the remaining packages. E.g. replace *gwl3ppqj4i730nhd4f50ncl5jc4n97ks-glibc-2.23* with *yxkk1j7h8kyglippv2df0gcx8yknhirb-glibc-2.23*.

Once again we're going to evaluate a fixpoint of *nixpkgs*, but this time we're inserting a new derivation called [patchDependencies](https://github.com/NixOS/nixpkgs/pull/10851/files#diff-017a38a631b06991d33857f7681874b3R343) that depends on the already-fully-built package. This new derivation

1. Copies the package contents
2. Patches the dependencies with an `sed` expression. Yep, that's right. We're using sed to patch binary files!


This concludes the high-level overview. There are more icky details in Nicolas' [pull request]((https://github.com/NixOS/nixpkgs/pull/10851)).


## Random notes

* A side-effect of using sed to patch arbitrary binary and text files is that we have to keep the same string length. If something changes from `glibc-2.23` to `glibc-2.23.1` then a simple replace will break offsets in shared libraries. This is handled in Nicolas' patch by renaming the package if the lengths don't match.

* We're not building the copy & fixup packages on Hydra. As a result we're saving time by not downloading the full binaries again. Instead they're built locally "from source". Building is just copy & fixup though, so roughly as fast as your disk IO.


## Current state & links

* Nicolas has an [open pull-request here](https://github.com/NixOS/nixpkgs/pull/10851)
* [Slides from NixCon 2015](https://github.com/nbp/slides/tree/master/NixCon/2015.ShippingSecurityUpdates)
* [Video from NixCon 2015](https://www.youtube.com/watch?v=RhcKXS00zEE)


## What you can do now

In the nixpkgs git repo run:

<pre><code class="bash">git fetch
git checkout -t -b security-updates origin/security-updates
nix-instantiate ./pkgs/test/security/static-analysis.nix --eval-only --show-trace |& tee analysis.log | less
</code></pre>

This will run a static analysis to identify packages that would break with this scheme. The output looks like this:

<pre><code class="plain">trace: List of 19568 potential issues:

389-ds-base: error: unpatched-inputs: generation 0, inputs: (2, /nix/store/5x3wdjl1fj2xj72k8w9hlwmlq9jxmylp-perl-Mozilla-Ldap-1.5.3), (2, /nix/store/f86dgl1mx
5rzrmwd2ikwxa5hvqakwv2h-perl-NetAddr-IP-4.079), (2, /nix/store/jzwpx242735k0530jrqnlnqdiak5rk77-perl-DB_File-1.831)
389-ds-base: warning: static-linking: generation 0, inputs: (0, /nix/store/i142rpgf0kq5x8qz9pj33vcqkg9i6x9b-libkrb5-1.14.3)
</code></pre>


Once you finished the analysis you can have a look at the monumental task of making all packages compatible! I think Nicolas will update his PR to explain how each of these issues can be fixed.

<pre><code class="plain">$ bash  ./pkgs/test/security/static-analysis-stats.sh ./analysis.log
(8249 alias, 8545 unpatched, 2774 recompile)
</code></pre>
