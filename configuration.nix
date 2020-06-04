# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  nixos-unstable = import <nixos-unstable> {};
  nixos-unstable-small = import <nixos-unstable-small> {};

in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./identifying.nix

      ./cachix.nix

      ./libinput.nix
    ];

  disabledModules = [ "services/x11/hardware/libinput.nix" ];

  boot.cleanTmpDir = true;

  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelPackages = nixos-unstable.linuxPackages_latest;
  boot.kernel = {
    sysctl = {
      "kernel.sysrq" = 1;
    };
  };

  #boot.blacklistedKernelModules = [ "evdev" ];

  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
    };
    grub = {
      enable = false;
      efiSupport = true;
      device = "nodev";
      extraEntries = ''
        menuentry "UEFI Setup" {
          fwsetup
        }
      '';
      extraEntriesBeforeNixOS = true;
      default = "1";
    };
  };

  networking.networkmanager = {
    #unmanaged = [ "enp3s0f0" ];
    enable = true;
  };
  networking.dhcpcd.enable = false;

  networking.hostName = "jakob-lenovo-nixos";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_GB.UTF-8";
  };

  console = {
    font = "ter-118n"; # Terminus 16
    packages = with pkgs.kbdKeymaps; [ dvp neo pkgs.terminus_font ];
    keyMap = "uk";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vimHugeX tmux firefox git
    pavucontrol
    wireshark
    reptyr
    libimobiledevice
    kate
    direnv
    gnupg

    sshfs

    archivemount dex diffoscope ffmpeg-full file
    jq nmap patchelf xxd usbutils

    wireguard

    virt-manager spice-gtk
  ];

  #virtualisation.virtualbox.host.enable = true;
  #virtualisation.lxc.enable = true;
  #virtualisation.lxd.enable = true;

  virtualisation.libvirtd.enable = true;

  security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";

  programs.tmux.enable = true;
  programs.tmux.keyMode = "vi";

  #programs.vim.defaultEditor = true;
  environment.variables = { EDITOR = "vim"; };

  programs.zsh.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  services.httpd = {
    enable = true;

    virtualHosts =
      let
        addDefault = _: host:
          host // {
            addSSL = true;
            sslServerCert = "/etc/letsencrypt/live/domain-name.xyz/fullchain.pem";
            sslServerKey = "/etc/letsencrypt/live/domain-name.xyz/privkey.pem";

            adminAddr = "jakobrs100@gmail.com";
          };

      in lib.mapAttrs addDefault {
        "domain-name.xyz" = {
          serverAliases = [ "srv.domain-name.xyz" "www.domain-name.xyz" ];

          enableUserDir = true;
          documentRoot = "/srv/www/main";

          extraConfig = ''
            <Directory "/srv/www/main">
              AllowOverride All
            </Directory>
            <Directory "/home/*/public_html">
              AllowOverride All
            </Directory>
          '';
        };
        "mcstatus.domain-name.xyz" = {
          extraConfig = ''
            ProxyPass / http://localhost:8081/
            ProxyPassReverse / http://localhost:8081/
          '';
        };
      };
  };

  # General Purpose Mouse
  # enables mouse in the virtual terminal
  services.gpm.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.forwardX11 = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 80 443 8008 8118 8080 8448 8888 9050 51111 ];
  networking.firewall.allowedUDPPorts = [ ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;

  /*
  Starting Nmap 7.80 ( https://nmap.org ) at 2020-03-12 07:41 CET
  mass_dns: warning: Unable to determine any DNS servers. Reverse DNS is disabled. Try using --system-dns or specify valid servers with --dns-servers
  Nmap scan report for localhost (127.0.0.1)
  Host is up (0.000016s latency).
  Other addresses for localhost (not scanned): ::1
  Not shown: 65528 closed ports
  PORT     STATE SERVICE
  22/tcp   open  ssh
  80/tcp   open  http
  443/tcp  open  https
  631/tcp  open  ipp
  8118/tcp open  privoxy
  9050/tcp open  tor-socks
  9063/tcp open  unknown
  
  Nmap done: 1 IP address (1 host up) scanned in 1.84 seconds
  */
  networking.nat = {
    enable = true;
    externalInterface = "wlp2s0";
    internalInterfaces = [ "ve-+" ];
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;

    extraModules = [ pkgs.pulseaudio-modules-bt ];

    package = pkgs.pulseaudioFull;

    support32Bit = true;

    /*
    tcp = {
      enable = true;
      anonymousClients.allowAll = true;
    };
    */
  };

  # Enable bluetooth.
  hardware.bluetooth = {
    enable = true;
  };

  hardware.opengl = {
    driSupport32Bit = true;
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "gb,no";
  services.xserver.xkbOptions = "eurosign:e,caps:escape";

  #services.logind.lidSwitch = "ignore"; # Appears to do nothing for whatever reason.

  /*
  services.xserver.enableTCP = true;
  services.xserver.displayManager.sddm.extraConfig = ''
    [X11]
    ServerArguments=-listen tcp
  '';
  */

  # Enable touchpad support.
  services.xserver.libinput = {
    enable = true;

    clickMethod = "clickfinger";

    #package = nixos-19-09.libinput;
    package = nixos-unstable.libinput;
    #package = pkgs.callPackage ./libinput { graphviz = pkgs.graphviz-nox; };
    #package = pkgs.libinput.overrideAttrs (old: {
    #  patches = old.patches ++ [ ./85707.patch ]; /*
    #    (pkgs.fetchpatch {
    #      name = "dont-override-udev.patch";
    #      url = "https://gitlab.freedesktop.org/libinput/libinput/-/merge_requests/384.patch";
    #      sha256 = "184z9awskbs19qmlngqzvp5hp43g6lkxrzzqqpppb16j1y4gs45r";
    #    })
    #  ]; */
    #});
    #xf86inputlibinput.package = nixos-19-09.xorg.xf86inputlibinput;
  };

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  #services.xserver.displayManager.startx.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.lorri.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;
    groups = { nixadm = { }; };

    users.jakob = {
      isNormalUser = true;
      extraGroups = [ "wheel" "nixadm" "dialout" "lxd" ];

      initialPassword = "password";
    };
  };

  nix = {
    trustedUsers = [ "root" "@wheel" ];
  };

  # Tor
  services.tor = {
    enable = true;
    client.enable = true;

    #hiddenServices."main".map = [ { port = 22; } { port = 80; } ];

    controlSocket.enable = true;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

  nixpkgs.overlays = [
    (self: super: {
      nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
    })
  ];

  nix.useSandbox = true;
}
