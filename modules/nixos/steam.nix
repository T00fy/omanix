{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omanix;

  # Wrap Steam to strip PrefersNonDefaultGPU and X-KDE-RunOnDiscreteGpu
  # from its desktop entries. These properties cause Steam windows to fail
  # to render when launched via app launchers (Walker/Wofi/Rofi) on
  # Hyprland + XWayland. Terminal launches bypass the .desktop file and
  # are unaffected.
  # Ref: https://bbs.archlinux.org/viewtopic.php?id=300993
  steamBase = pkgs.steam.override {
    extraEnv = { };
  };

  steamPatched = steamBase.overrideAttrs (prev: {
    postInstall = (prev.postInstall or "") + ''
      find $out/share/applications -name '*.desktop' -exec \
        sed -i \
          -e '/^PrefersNonDefaultGPU/d' \
          -e '/^X-KDE-RunOnDiscreteGpu/d' \
          {} +
    '';
  });
in
{
  config = lib.mkIf (cfg.enable && cfg.steam.enable) {
    hardware.steam-hardware.enable = true;
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        package = steamPatched;
      };
      gamescope.enable = true;
      gamemode.enable = true;
    };

    environment.systemPackages = with pkgs; [
      mangohud
      protonup-qt
    ];
  };
}
