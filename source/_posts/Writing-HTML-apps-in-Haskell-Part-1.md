---
title: Writing HTML apps in Haskell - Part 1
date: 2016-11-26
tags: Haskell
---

Recently I wanted to to build a user interface in Haskell that runs on my Gnome desktop, not in the cloud (the audience gasps).

The obvious choice was to use a toolkit, so I tried [qtah-qt5](http://khumba.net/docs/qtah-qt5-0.1.0/index.html), [gtk3](https://hackage.haskell.org/package/gtk3) and [gi-gtk](https://hackage.haskell.org/package/gi-gtk). [ ... ]. I had a fairly long section here on my experience but it was unnecessarily mean, so I replaced it with a representative image:

{% img "img-thumbnail" "/images/User-interfaces-in-Haskell/picard.jpg" %}


## Alternatives considererd

I played with [Electron](http://electron.atom.io/) but having written a [large app](https://proppy.io/) in TypeScript already I decided that I don't want to give up my Haskell data structures again. The problem I'm trying to solve is too complex to be coded without QuickCheck and types.

## Back to Haskell & WebKit

The summary: It works! - but it's not yet straight forward.

{% img "img-thumbnail" "/images/User-interfaces-in-Haskell/hello-world.png" 150 %}

The handler that renders the content above looks like this:

{% codeblock lang:haskell line_number:false %}
testClosure2 :: DOMElement -> DOMMouseEvent -> IO ()
testClosure2 doc ev = do
  x <- dOMMouseEventGetClientX ev
  y <- dOMMouseEventGetClientY ev
  set doc [#innerHtml := ("<h2>Mouse</h2>x: " <> toS (show x) <> ", y: " <> toS (show y))]
  pure ()
{% endcodeblock %}

## Technical details

To combine Haskell & WebKit I'm relying on WebKit bindings for Haskell generate via [GObject's introspection](https://wiki.gnome.org/Projects/GObjectIntrospection). The libraries are available [on hackage](https://hackage.haskell.org/packages/#cat:Bindings) with a `gi-` prefix. E.g. `gi-gtk` or `gi-webkit2`.

The dependencies are non-trivial, so I set up a project with a nix-shell. You can find the intermediate, messy state [here](https://github.com/teh/haskell-webkit2gtk/tree/part-1).

### Multi-process

The [WebKit2Gtk API](https://webkitgtk.org/reference/webkit2gtk/stable/) implements multi-process support. I.e. each frame runs in its own, sandboxed process. That means the main Haskell process cannot directly access the DOM. Only code in worker processes can do that. However, the main process can do some high-level things like navigating to a URL, or injecting some JavaScript.

To access the DOM however we need to run in the worker process. The only way this can be done is by exporting a symbol with the name `webkit_web_extension_initialize_with_user_data`. I implemented a [small c shim](https://github.com/teh/haskell-webkit2gtk/blob/part-1/plugin/cbits/test.c) for that.

The full flow now is:

1. Implement a [main process](https://github.com/teh/haskell-webkit2gtk/blob/part-1/web/Main.hs) that opens a window and embeds WebKit.
2. Implement a shared library that connects to the `page-created` event and hands off the flow to a Haskell function that we implement.
3. In the main process point to the directory that contains our `test.so` library from step 2.

Now when we run our main binary each new frame loads and runs our plugin code.

### Rough edges

* The GObject introspection support is very thorough, but AFAICT it doesn't support callbacks for DOM events. The callback code currently [requires a bouncing through c code](https://github.com/teh/haskell-webkit2gtk/blob/master/plugin/TestPlugin.hs#L21).
* The compile is slow
* I have not looked at the JavaScript integration


## Long term motivation

The setup looks complicated but I think it's worth the effort. UI development with CSS, a web inspector, and retained-mode, virtual-dom libraries like React and Vue is vastly superior to the toolkit-style development. These UI libraries have a gigantic mind-share compared to classic desktop development.

On top of that enormous resources are spent on development and optimisation of web engines. In the not-too-distant future we might see a Gtk-Servo backend that uses 3x less memory and is 5x faster.

Eventually I want to get to a place where I can code the "hard" backend code in Haskell & then run a UI on top of that with JavaScript & React.
