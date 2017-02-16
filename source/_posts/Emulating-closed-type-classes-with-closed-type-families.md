---
title: Emulating closed type classes with closed type families
date: 2017-01-18
tags: Haskell
---

Haskell actually implements two languages: The value-level language, and a more limited type-level language that is evaluated at compile time. GHC's support for type-level programming is quite powerful. [This recent post](https://kseo.github.io/posts/2017-01-16-type-level-functions-using-closed-type-families.html) e.g. shows how to do a type-level `if` amongst things.

## Closed type families

One useful property of closed type families is that they are evaluated in order, like pattern matching in function bodies. We start with a simple example that matches a type to a colour:

{% codeblock lang:haskell line_number:false %}
{-# LANGUAGE TypeFamilies #-}

import GHC.Base (Type)

data Blue
data Yellow
data Grey

type family Colour (ty :: Type) = (color :: Type) where
  Colour String = Blue
  Colour Int = Yellow
  Colour ty = Grey
{% endcodeblock %}

After loading this code into ghci I can test the explicitly specified `Int` type:

{% codeblock lang:haskell line_number:false %}
λ  :load closed.hs
λ  :kind! (Colour Int)
(Colour Int) :: *
= Yellow
{% endcodeblock %}

But, and this is the important property, if no type matches `Colour` falls through to the general `ty` type, Grey:

{% codeblock lang:haskell line_number:false %}
λ  :kind! (Colour Bool)
(Colour Bool) :: *
= Grey  -- fall-through
{% endcodeblock %}



## Type classes are open

In Haskell type classes are *open*, i.e. anyone can implement a new instance for their type. This means that the compiler always needs to be able to decide which instance to pick. There is no way of "falling through" to a most generic instance like we did in the closed type family. We can try specifing a  generic instance matching all types `a`, e.g.

{% codeblock lang:haskell line_number:false %}
{-# LANGUAGE FlexibleInstances #-}

class NoOverlap a
instance NoOverlap Int
instance NoOverlap a

hello :: NoOverlap a => String
hello = "hello"
{% endcodeblock %}

When loading the code above we get:

{% codeblock lang:text line_number:false %}
source/flex.hs:7:10: error:
    • Overlapping instances for NoOverlap a0
{% endcodeblock %}

GHC supports `OVERLAPPING` [pragmas](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/glasgow_exts.html#overlapping-instances) that allow for some limited ambiguity but it's not pretty.


## Closing the type classes

We can combine the closed type families with type classes to implement a generic fall-through. We add a new class `Overlap` that takes one of our three possible colours:

{% codeblock lang:haskell line_number:false %}
class Overlap a where colour :: String
instance Overlap Blue where colour = "blue"
instance Overlap Yellow where colour = "yellow"
instance Overlap Grey where colour = "grey"

hello :: forall x a. (a ~ Colour x, Overlap a) => String
hello = "hello " ++ (colour @a)
{% endcodeblock %}

And we can now greet for any type without any overlapping instances:

{% codeblock lang:haskell line_number:false %}
λ  hello @Int
"hello yellow"
λ  hello @Bool
"hello grey"
λ  hello @(Maybe Int)
"hello grey"
{% endcodeblock %}


## Adding this to GHC?

Type classes are the easiest way to map from types to values so I think having "closed type classes" would make a great addition to GHC though I appreciate it's a non-trivial undertaking, and currently beyond my skills. Edward Yang [pointed me](https://twitter.com/ezyang/status/810871284431208448) to a paper on [instance chains](http://web.cecs.pdx.edu/~mpj/pubs/instancechains.pdf) which is pretty close to what I had in mind.
