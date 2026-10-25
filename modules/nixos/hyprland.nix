{ config, lib, pkgs, ... }:
let
  cfg = config.omanix;
in
{
  config = lib.mkIf cfg.enable {
    # withUWSM = false prevents programs.uwsm.enable from being set,
    # but hyprland-uwsm.desktop is baked into the hyprland package itself
    # (upstream ships it in systemd/hyprland-uwsm.desktop via CMake).
    # We replace the session package with one that only exposes hyprland.desktop.
    # Selecting hyprland-uwsm.desktop causes a kernel DRM master deadlock:
    # Weston holds DRM master while uwsm's async systemd startup races to
    # acquire it, freezing the system with no TTY escape possible.
    programs.hyprland.withUWSM = false;

    # With home-manager.useUserPackages the user profile is built from these
    # paths only; OMANIX_PATH resolves through it.
    environment.pathsToLink = [ "/share/omanix" ];

    services.displayManager.sessionPackages = lib.mkForce [
      (pkgs.runCommand "hyprland-sessions" {
        passthru.providedSessions = [ "hyprland" ];
      } ''
        mkdir -p $out/share/wayland-sessions
        cp ${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop \
           $out/share/wayland-sessions/
      '')
    ];
  };
}
