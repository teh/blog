let do = {
    network = {
      enableRollback = true;
      network.description = "the-shortlog";
    };
    resources.sshKeyPairs.ssh-key = {};

    theshortlog = { resources, pkgs, lib, config, ... }: {
      deployment = {
        targetEnv = "digitalOcean";
        digitalOcean.size = "512mb";
        digitalOcean.region = "ams2";
        keys = {
          "ca.crt" = { text = builtins.readFile ./tom-vpn/keys/ca.crt; };
          "server.crt" = { text = builtins.readFile ./tom-vpn/keys/server.crt; };
          "server.key" = { text = builtins.readFile ./tom-vpn/keys/server.key; };
          "dh2048.pem" = { text = builtins.readFile ./tom-vpn/keys/dh2048.pem; };
        };
        storeKeysOnMachine = false;
      };
      services.openssh.enable = true;
      security.grsecurity.enable = true;

      boot = {
        kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
        };
      };

      networking = {
        firewall = {
          enable = true;
          # openvpn:
          extraCommands = ''
          iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o enp0s3 -j MASQUERADE
        '';
          allowedUDPPorts = [ 1194 ]; # openvpn
          allowedTCPPorts = [ 80 443 ];
          trustedInterfaces = [ "tun0" ];
        };
      };

      services.fail2ban = {
        enable = true;
      };

      services.openvpn = {
        servers = {
          tom = {
            config = ''
            dev tun0
            server 10.8.0.0 255.255.255.0

            ca      /run/keys/ca.crt
            cert    /run/keys/server.crt
            key     /run/keys/server.key
            dh      /run/keys/dh2048.pem

            port 1194
            comp-lzo
            verb 3
          '';
          };
        };
      };

      services.nginx = {
        enable = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        recommendedProxySettings = true;
        virtualHosts = {
          "theshortlog.com" = {
            forceSSL = true;
            enableACME = true;
            locations."/" = {
              root = pkgs.callPackage ./blog.nix {};
            };
          };
        };
      };
    };
  };
in do
