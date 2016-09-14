---
title: Nginx in NixOS 16.09
date: 2016-09-11 11:28:03
tags: Nix
---

The beta release of [NixOS 16.09](http://lists.science.uu.nl/pipermail/nix-dev/2016-September/021658.html) comes with a very cool config generator for your NGINX configuration. It makes it easy to:

* Use [Let's Encrypt](https://letsencrypt.org/) for certificates
* Configure virtualhosts
* Have good default configurations for SSL and headers
* Avoid mistakes

Here's a simple setup for serving SSL-only content on `example.com`:

<pre><code class="nix">{
  "example.com" = {
    forceSSL = true;  # 3
    enableACME = true;  # 4
    locations."/" = {
      root = "/var/www";
    };
  };
}
</code></pre>

**Line 3** forces traffic from unsecured HTTP (port 80) to HTTPS (port 443).

**Line 4** tells NixOS to get a certificate from Let's Encrypt (via the ACME protocol). This line does two things: NixOS generates a self-signed certificate to use as a placeholder until the ACME certificate arrives. It also enables a weekly systemd timer to renew the certificates in time - Let's Encrypt certs are valid for only three months.

Lastly we want to enable NGINX with good default settings:

<pre><code class="nix">services.nginx = {
  enable = true;
  recommendedOptimisation = true;
  recommendedTlsSettings = true;
  recommendedGzipSettings = true;
  recommendedProxySettings = true;
  virtualHosts = import ./conf/example.com.nix;
};
</code></pre>


This gives us a grade B on [ssllabs.com](https://www.ssllabs.com/ssltest/analyze.html) (as of September 2016) which is a good compromise between supporting older browsers and being secure.
