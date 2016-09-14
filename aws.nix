let
  region = "eu-west-1";
in {
  network = {
    enableRollback = true;
    network.description = "the-shortlog";
  };
  resources = {
    ec2KeyPairs.pair = { inherit region; };
    ec2SecurityGroups.http-ssh = {
      inherit region;
      rules = (map (port: { fromPort = port; toPort = port; sourceIp = "0.0.0.0/0"; }) [ 22 80 443 ]) ++
        [{ fromPort = 1194; toPort = 1194; sourceIp = "0.0.0.0/0"; protocol = "udp";}];
    };
  };

  theshortlog = { resources, pkgs, lib, config, ... }: {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        region = region;
        instanceType = "t2.nano"; # $5 / month
        keyPair = resources.ec2KeyPairs.pair;
        securityGroups = [ resources.ec2SecurityGroups.http-ssh ];
        elasticIPv4 = "52.210.186.237";
      };
      keys = {
        "ca.crt" = { text = builtins.readFile ./tom-vpn/keys/ca.crt; };
        "server.crt" = { text = builtins.readFile ./tom-vpn/keys/server.crt; };
        "server.key" = { text = builtins.readFile ./tom-vpn/keys/server.key; };
        "dh2048.pem" = { text = builtins.readFile ./tom-vpn/keys/dh2048.pem; };
      };
    };

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
          iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
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
}
