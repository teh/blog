---
title: Purescript's c++ backend
date: 2016-11-10 09:25:32
tags:
    - Purescript
---

[Purescript](http://www.purescript.org/) describes itself like so:

> PureScript is a small strongly typed programming language that compiles to JavaScript.

It's written in Haskell and borrows many concepts as well. It's not the same though, and one distinguishing feature is that it compiles down to a small imperative core. It's relatively easy to implement new backends for this core - one of them is in c++ 11.

The c++ backend has virtually no ecosystem and running it still requires some manual labour.

First we clone the repository:

<pre><code class="bash">$ git clone https://github.com/pure11/pure11
$ cd pure11
</code></pre>

There is a `stack.yml` so you can use [stack](https://docs.haskellstack.org/en/stable/README/) to build. I use NixOS 16.09:

<pre><code class="bash">$ cabal2nix . --shell > shell.nix
$ nix-shell
$ cabal build
</code></pre>

The build will create a `pcc` binary. When you run it without inputs it will create a `Makefile`:

<pre><code class="bash">$ dist/build/pcc/pcc
Generating Makefile...
pcc executable location: /home/tom/src/pure11/dist/build/pcc/pcc
Done
Run 'make' or 'make release' to build an optimized release build.
The resulting binary executable will be located in output/bin (by default).
</code></pre>

`pure11` doesn't have a package manager so we need to clone a few c++ specific packages by hand:

<pre><code class="bash">mkdir packages
cd packages

git clone https://github.com/pure11/purescript-prelude
git clone https://github.com/pure11/purescript-eff
git clone https://github.com/pure11/purescript-console
git clone https://github.com/pure11/purescript-control
</code></pre>

We create a simple example program in `src/Main.purs`:

<pre><code class="purescript">module Main where

import Control.Monad.Eff.Console (log, CONSOLE)
import Prelude (Unit)
import Control.Monad.Eff (Eff)

main :: forall e. Eff ( console :: CONSOLE | e ) Unit
main = log "hello from pure11"
</code></pre>

and run `make`:

<pre><code class="bash">$ make
Compiling Data.NaturalTransformation
Compiling Data.Show
...
Creating output/Main/Main.o
...
Linking output/bin/main
make[1]: Leaving directory '/home/tom/src/pure11'
</code></pre>

which we can run:

<pre><code class="bash">$ output/bin/main
hello from pure11
</code></pre>

## Notes

This isn't anywhere close to ready for production, but it's amazing that this works in the first place.

In theory I can now use all the [Purescript libraries](https://pursuit.purescript.org/) that aren't targeting JavaScript explicitly. I say "in theory" because I haven't actually tried this.

In the near future Purescript will gain the ability to dump an [imperative core](https://github.com/purescript/purescript/issues/711) which will make it even easier to write backends.

I can totally imagine a world where people write the more important parts of their apps in Purescript, and then compile down whatever language they use in their own ecosystem.
