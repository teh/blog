---
title: Nix hackathon March 2017
date: 2017-03-17
tags: Nix
---

Earlier this month [Smarkets](https://smarkets.com/) was being awesome and hosted our 2nd Nix hackathon. We had a fantasic crowd of smart people, and the Smarkets office was downright amazing. We had standing desks with extra monitors. The coffee was so thick that it was still strong in homeopathic doses. We even had smarties on tap.

## Ideas

With all the basics sorted we set up a whiteboard to collect a few ideas:

{% img "img-thumbnail" /images/Nix-hackathon-March-2017/whiteboard.jpg 400 "Hackathon Whiteboard" %}

We also created a [matrix](http://matrix.org/) channel, with most people using [riot.im](https://riot.im/app/#/) to access that. matrix has come a very long way, and it was useful to share snippets and links. No one needed to install an IRC client.

## Work

Nix attracts people from many different backgrounds with many different goals. Despite that I think one theme that emerged is that getting started is really terrible. A lot of examples from the docs don't work as advertised, sometimes because of Darwin, sometimes not at all.

A related problem is that the docs are unnecessarily cryptic. Alexander is going to fix some of that by expanding the short command line flags like `-r` with the long ones like `--realise`. [See his PR](https://github.com/NixOS/nix/pull/1280) for more details.

Josef [created a new issue (already fixed)](https://github.com/NixOS/nixpkgs/issues/23794) for fixing a current Haskell/Darwin issue, and he made good progress on getting a working environment on his laptop. He's saved the next set of people a lot of time!

I was trying to fix at least one of our two broken Emacs modes, but the only thing I managed to produce is an [issue update](https://github.com/matthewbauer/nix-mode/issues/9). Emacs is not an easy tool.

## Again!

Everyone stayed quite late so it probably wasn't boring! We're aiming for another hackathon in 8-10 weeks, hopefully again at Smarkets.
