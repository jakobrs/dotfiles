# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./identifying.nix

      ./cachix.nix
    ];

  boot.cleanTmpDir = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader = {
    systemd-boot.enable = false;
    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      efiInstallAsRemovable = true;
      efiSupport = true;
      version = 2;
      device = "nodev";
      extraConfig = ''
        insmod lvm
      '';
      useOSProber = false;
      extraEntries = ''
        menuentry "UEFI Setup" {
          fwsetup
        }
      '';
      extraEntriesBeforeNixOS = true;
      default = "1";
      /*
      extraEntries = ''
        menuentry "Ubuntu" {
          search.fs_uuid 0c0c3417-ef95-4d1f-915b-2d0beba6b10d root lvmid/VlXJvq-4u1L-42Wt-yAeq-EqpQ-cpcm-ZtToDK/apAM50-qZB0-SIYC-lRQR-1AQd-dwCS-Kh4tfm 
          configfile ($root)/boot/grub/grub.cfg
        }
      '';
      */
    };
  };

  swapDevices = [
    {
      device = "/dev/vgmain/swap";
    }
  ];

  networking.hostName = "jakob-acer-nixos"; # Define your hostname.
  networking.networkmanager.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp3s0f0.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "uk";
    defaultLocale = "en_GB.UTF-8";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim tmux firefox git
    pavucontrol
    wireshark
    reptyr
    libimobiledevice
    kate
  ];

  virtualisation.virtualbox.host.enable = true;

  programs.tmux.enable = true;
  programs.tmux.keyMode = "vi";

  programs.vim.defaultEditor = true;

  programs.zsh.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  services.httpd = {
    enable = true;
    adminAddr = "jakobrs100@gmail.com";
    virtualHosts = [
      {
        adminAddr = "jakobrs100@gmail.com";
        enableUserDir = true;
        documentRoot = "/srv/www";
      }
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  #networking.firewall.allowedTCPPorts = [ 80 4713 ];
  #networking.firewall.allowedUDPPorts = [ ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  /*
  networking.nat = {
    enable = true;
    externalInterface = "wlan0";
    internalInterfaces = [ "vboxnet0" ];
    internalIPs = [ "192.168.56.0/24" ];
  };
  */

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;

    extraModules = [ pkgs.pulseaudio-modules-bt ];

    package = pkgs.pulseaudioFull;

    support32Bit = true;
    
    tcp = {
      enable = true;
      anonymousClients.allowAll = true;
    };
  };

  # Enable bluetooth.
  hardware.bluetooth.enable = true;

  hardware.opengl = {
    driSupport32Bit = true;
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "gb,no";
  services.xserver.xkbOptions = "eurosign:e,caps:escape";

  /*
  services.xserver.enableTCP = true;
  services.xserver.displayManager.sddm.extraConfig = ''
    [X11]
    ServerArguments=-listen tcp
  '';
  */

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;
    groups = { nixadm = { }; };

    users.jakob = {
      isNormalUser = true;
      extraGroups = [ "wheel" "nixadm" ];
    };
  };

  nix = {
    trustedUsers = [ "root" "@wheel" ];
  };

  # Tor
  services.tor.enable = true;
  services.tor.client.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

  nix.useSandbox = true;
}
