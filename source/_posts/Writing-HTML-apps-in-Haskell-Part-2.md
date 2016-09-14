---
title: Writing HTML apps in Haskell - Part 2
date: 2016-12-01
tags: Haskell
---

In [part 1](/2016/11/26/Writing-HTML-apps-in-Haskell-Part-1/) I described the basic two-process setup for accessing the DOM from within Haskell.

In this instalment I will walk through several other crucial ingredients for a proper Haskell HTML app.

## Motivation

First, here's a GIF of an animated DOM rendered in Haskell that can be modified with developer tools.

{% img "img-thumbnail" /images/Writing-HTML-apps-in-Haskell-Part-2.md/motivation.gif %}


## Serving local content

Browsers usually fetch data form the network via HTTP or one of its successors (http2, quic). The URL looks like `http://localhost/resource`. WebKit supports registering custom URL schemes so we don't have to hit the network and run a server. We instead register a `haskell://` schema with a `IO ()` callback which gets executed each time the rendering engine loads a resource.

It's important to register this URI schema **before** creating an actual render view but the code itself is pretty simple:

{% codeblock lang:haskell line_number:false %}
webContextRegisterUriScheme context "haskell" $ \request -> do
  uri <- uRISchemeRequestGetUri request
  print uri -- prints e.g. "haskell://hello.html"
  -- [omitted]
-- [omitted]
webViewLoadUri view "haskell://hello.html"
{% endcodeblock %}


## A virtual DOM

Relative to JavaScript speeds DOM updates in browsers are slow. That's why all modern frameworks try to minimise DOM access. The most common technique is to keep a DOM-like data structure in memory. After changes we diff that DOM-like structure against its previous version, and generate a set of "patches" that then modify the real, in-browser DOM. Find a longer and nicer [description here](https://medium.com/cardlife-app/what-is-virtual-dom-c0ec6d6a925c#.w87ns97hq).

I adapted [some code](https://github.com/bodil/purescript-vdom/blob/master/src/Data/VirtualDOM.purs) from Bodil Stokke to implement a virtual DOM.

The code for the GIF above can now be written like this:

{% codeblock lang:haskell line_number:false %}
testVNode :: Int -> VNode
testVNode n =
  GE.div_ [onClick printCoordinates, GA.class_ "container"]
  [ GE.h1_ [] [GE.text_ "Hello"]
  , GE.div_ []
    [ GE.button_ [GA.class_ "btn btn-primary"]
      [GE.text_ (show n)]
    ]
  ]
{% endcodeblock %}

And at some later point you call `patch` to blast the virtual tree from `testVNode` into the real DOM:

<pre><code class="haskell">patch api body oldDom newDom
</code></pre>

## CSS

CSS preprocessors are another important component of modern web development. These preprocessors like [less](http://lesscss.org/) and [sass](http://sass-lang.com/) take away some of the pain of CSS. They allow e.g. defining variables for common colours, or take care of writing the correct browser-specific prefixes for some CSS properties.

I added a simple sass reader to the example code that uses [hsass](https://hackage.haskell.org/package/hsass) to render the [bootstrap V4 sass code](https://github.com/twbs/bootstrap).

Including the sass file works as usual, except that we're using the `haskell://` scheme, and that hsass is re-processing on every reload.


{% codeblock lang:html line_number:false %}
<link rel="stylesheet" type="text/css" href="haskell://bootstrap.css">
{% endcodeblock %}


## Other notes

* The current code can be [found here](https://github.com/teh/haskell-webkit2gtk).
* GObject and also WebKit require running code that modifies the DOM in the GObject main loop. So you can use all of Haskell's runtime but DOM modifications have to be run via `idleAdd`.
* Building the separate-process plugin requires manual linking against the Haskell runtime, e.g with `-lHSrts_thr_l-ghc8.0.1`. Note the `_thr` and the `_l`. Those two mean that we're linking against the runtime that supports threading and [event logging](https://www.well-typed.com/blog/2014/02/ghc-events-analyze/). The normal `-threaded` and `-eventlog` flags don't work for some reason.
* I want to use hpack but it [doesn't support](https://github.com/sol/hpack/issues/139) enough Cabal features yet.
* The compile & link times are crushing.
* The function names are auto-camel-cased from the GTK names which often leads to weird capitalisation, e.g. `uri_scheme_request_get_uri` becomes `uRISchemeRequestGetUri`.


## What next?

I'm going to clean up the code to make it more like a library with a few entry points. If someone with stack-knowledge wanted to stackify it I'd be eager to help.

I'm surprised how well this works. Writing a UI to render some home automation data took me less than an hour. I hope I can convince others to join in to make this a more generally useful project!
