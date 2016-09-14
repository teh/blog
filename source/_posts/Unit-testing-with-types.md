---
title: Unit testing with types
date: 2016-04-22 16:28:40
tags: Haskell
---

I'm an incredibly sloppy programmer, and I lean on the compiler heavily to help me not be stupid. One of my favourite things is to use types to enforce properties of data.

The idea is to create a type that can only be constructed with a "smart" constructor that checks for validity on creation. In code:

<pre><code class="haskell">module GreenThing (GreenThing, makeGreenThing) where

newtype GreenThing = GreenThing String deriving (Show, Eq)

makeGreenThing :: String -> Maybe GreenThing
makeGreenThing s = case s of
  "green" -> Just (GreenThing "green")
  "lime -> Just (GreenThing "lime")
  "moss -> Just (GreenThing "moss")
   _ -> Nothing
</code></pre>

We're not exporting the *constructor* `GreenThing`, only the *type* `GreenThing`. To get a value of type `GreenThing` I need to go through `makeGreenThing` which makes it impossible to create an invalid value.

With this setup I **know** that `GreenThing` contains something green, no matter where I use it. This frees my mind for other tasks.

I use this in place of unit tests: Every time I have a new entity I create a type with a smart constructor, test it a bit in the repl, and then use it without ever writing a single test. It works surprisingly well!
