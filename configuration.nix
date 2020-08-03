# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  nixos-unstable = import <nixos-unstable> {};

in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./identifying.nix

      ./cachix.nix
    ];

  boot.cleanTmpDir = true;

  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelPackages = nixos-unstable.linuxPackages_latest;
  boot.kernel = {
    sysctl = {
      "kernel.sysrq" = 1;
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
    };
  };

  networking.networkmanager.enable = true;
  networking.dhcpcd.enable = false;

  networking.hostName = "vulpix";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  console = {
    font = "ter-118n";
    packages = with pkgs.kbdKeymaps; [ dvp neo pkgs.terminus_font ];
    keyMap = "uk";
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # Miscellaneous
    wget git gnupg file jq nmap patchelf
    xxd dex htop vimHugeX bat reptyr unzip

    # System administration
    acpi efibootmgr pciutils usbutils lshw parted gparted glxinfo

    # General untitled category #2
    brightnessctl pavucontrol libimobiledevice usbmuxd
    sshfs archivemount

    # Larger programs
    wireshark firefox wireguard ffmpeg-full

    # Virtual machines
    virt-manager spice-gtk
  ];

  virtualisation.libvirtd.enable = true;

  security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";

  programs.tmux.enable = true;
  programs.tmux.keyMode = "vi";

  environment.variables = { EDITOR = "vim"; };

  programs.zsh.enable = true;

  # List services that you want to enable:

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

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;

    extraModules = [ pkgs.pulseaudio-modules-bt ];

    package = pkgs.pulseaudioFull;

    support32Bit = true;
  };

  # Enable bluetooth.
  hardware.bluetooth.enable = true;

  hardware.opengl.driSupport32Bit = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "gb,no";
  services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable touchpad support.
  services.xserver.libinput = {
    enable = true;

    clickMethod = "clickfinger";
  };

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;
    groups = { nixadm = { }; };

    users.user = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "lxd" ];
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
    controlSocket.enable = true;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03"; # Did you read the comment?

  nixpkgs.config = {
    firefox.enablePlasmaBrowserIntegration = true;
  };

  nix.useSandbox = true;
}
