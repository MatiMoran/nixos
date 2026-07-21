{
  username = {
    nixos = "matias";
    darwin = "matmoran";
  };

  pipewire = {
    headset = "alsa_output.usb-Kingston_Technology_Company_HyperX_Cloud_Flight_Wireless-00.analog-stereo";
    speakers = "alsa_output.pci-0000_00_1f.3.analog-stereo";
    headsetMic = "alsa_input.usb-Kingston_Technology_Company_HyperX_Cloud_Flight_Wireless-00.mono-fallback";
  };

  sharedPackages = [
    "git"
    "ripgrep"
    "fd"
    "fzf"
    "bat"
    "zoxide"
  ];
}
