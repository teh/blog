---
title: Prepare NixOS disk image for another computer
date: 2016-06-29
tags: Nix
---

When installing my deep-learning box I didn't have a monitor so I had to blast the disk-image straight onto a disk with `dd`.

nixpkgs has a few convenient functions to create images so that the final command becomes:

<pre><code class="bash">nix-build mkimage.nix
qemu-img convert -f qcow2 -O raw result/nixos.qcow2 /dev/sdXXX
</code></pre>


I set up my image with my SSH key, network-manager, a home directory and `wheel` access:

<pre><code class="nix">with (import <nixpkgs> {}).pkgs;
let
    key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtq8LpgrnFQWpIcK5YdrQNzu22sPrbkHKD83g8v/s7Nu3Omb7h5TLBOZ6DYPSorGMKGjDFqo0witXRagWq95HaA9epFXmhJlO3NTxyTAzIZSzql+oJkqszNpmYY09L00EIplE/YKXPlY2a+sGx3CdJxbglGfTcqf0J2DW4wO2ikZSOXRiLEbztyDwc+TNwYJ3WtzTFWhG/9hbbHGZtpwQl6X5l5d2Mhl2tlKJ/zQYWV1CVXLSyKhkb4cQPkL05enguCQgijuI/WsUE6pqdl4ypziXGjlHAfH+zO06s6EDMQYr50xgYRuCBicF86GF8/fOuDJS5CJ8/FWr16fiWLa2Aw== tom@leto";

    config = (import <nixpkgs/nixos> { configuration = {
    fileSystems."/".device = "/dev/disk/by-label/nixos";
    boot.loader.grub.device = "/dev/sda";

    users.users.root = {
      openssh.authorizedKeys.keys = [ key  ];
    };
    users.extraUsers.tom = {
      description = "tom";
      createHome = true;
      useDefaultShell = true;
      home = "/home/tom";
      password = "tom";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ key ];
    };
    services.openssh.enable = true;
    networking.networkmanager = {
      enable = true;
      insertNameservers = [ "8.8.8.8" ];
    };
  };
}).config;
in
import <nixpkgs/nixos/lib/make-disk-image.nix> {
      inherit config pkgs lib;
      partitioned = true;
      diskSize = 2048;
      format = "qcow2";

      configFile = pkgs.writeText "configuration.nix" ''
        # nothing
      '';
}
</code></pre>
