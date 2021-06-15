# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./identifying.nix
    ];

  boot.cleanTmpDir = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.initrd.kernelModules = [ "vfio-pci" "i915" ];
  boot.kernelModules = [ "kvmgt" ];
  boot.kernelParams = [
    "intel_iommu=on" "i915.enable_gvt=1"
    "snd-intel-dspcfg.dsp_driver=1"
  ];
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

  services.fwupd.enable = true;

  networking.networkmanager.enable = true;
  networking.dhcpcd.enable = false;
  networking.useDHCP = false;
  networking.hostName = "girafarig";

  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  console = {
    font = "ter-118n";
    packages = [ pkgs.terminus_font ];
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
  programs.dconf.enable = true;

  security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";

  programs.tmux.enable = true;
  programs.tmux.keyMode = "vi";

  environment.variables = {
    EDITOR = "vim";
    MOZ_ENABLE_WAYLAND = "1";
  };

  programs.zsh.enable = true;

  # List services that you want to enable:

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

  hardware.steam-hardware.enable = true;

  # Enable bluetooth.
  hardware.bluetooth.enable = true;

  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver
  ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "gb,no,trans";
  services.xserver.xkbOptions = "eurosign:e,caps:escape,lv5:rwin_switch_lock";

  services.xserver.exportConfiguration = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.prime = {
    offload.enable = true;

    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  /* NVIDIA Optimus PRIME sync configuration
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.dpi = 96;
  hardware.nvidia.optimus_prime = {
    enable = true;

    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
  */

  # Enable touchpad support.
  services.xserver.libinput = {
    enable = true;

    touchpad.clickMethod = "clickfinger";
  };

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;
    groups = { nixadm = { }; };

    users.user = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" ];
      initialPassword = "password";
    };
  };

  nix = {
    trustedUsers = [ "root" "@wheel" ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03"; # Did you read the comment?

  nixpkgs.config = {
    allowUnfree = true;

    firefox.enablePlasmaBrowserIntegration = true;
  };

  nix.useSandbox = true;
}
