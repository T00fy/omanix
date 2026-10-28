{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omanix;

  toggleScript = pkgs.writeShellApplication {
    name = "omanix-toggle-sunshine";
    runtimeInputs = with pkgs; [
      systemd
      libnotify
    ];
    text = builtins.readFile ./omanix-toggle-sunshine.sh;
  };

  toggleDesktopItem = pkgs.makeDesktopItem {
    name = "omanix-toggle-sunshine";
    desktopName = "Sunshine";
    comment = "Start/stop the Sunshine game stream host for Moonlight";
    exec = "${toggleScript}/bin/omanix-toggle-sunshine";
    icon = "dev.lizardbyte.app.Sunshine";
    categories = [
      "Network"
      "RemoteAccess"
    ];
  };

  # Upstream ships its own "Sunshine" launcher entry whose Exec runs the bare
  # binary with no config file, bypassing sunshine.service entirely (and thus
  # the declarative `file_apps` below) and falling back to the web-UI
  # apps.json. Strip it so the app launcher only ever surfaces the toggle
  # script above, which starts sunshine.service correctly. overrideAttrs (not
  # symlinkJoin) so pname/mainProgram are preserved for getExe/security wrappers.
  sunshinePackage = pkgs.sunshine.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      rm -f $out/share/applications/dev.lizardbyte.app.Sunshine.desktop
      rm -f $out/share/applications/dev.lizardbyte.app.Sunshine.terminal.desktop
    '';
  });

  tcpPorts = [
    47984
    47989
    47990
    48010
  ];
  udpPorts = [
    47998
    47999
    48000
    48002
    48010
  ];

  firewallRules = lib.concatMapStringsSep "\n" (
    ip:
    let
      tcpRules = lib.concatMapStringsSep "\n" (
        port: "iptables -A nixos-fw -p tcp --dport ${toString port} -s ${ip} -j nixos-fw-accept"
      ) tcpPorts;
      udpRules = lib.concatMapStringsSep "\n" (
        port: "iptables -A nixos-fw -p udp --dport ${toString port} -s ${ip} -j nixos-fw-accept"
      ) udpPorts;
    in
    "${tcpRules}\n${udpRules}"
  ) cfg.sunshine.allowedIps;

  firewallStopRules = lib.concatMapStringsSep "\n" (
    ip:
    let
      tcpRules = lib.concatMapStringsSep "\n" (
        port: "iptables -D nixos-fw -p tcp --dport ${toString port} -s ${ip} -j nixos-fw-accept || true"
      ) tcpPorts;
      udpRules = lib.concatMapStringsSep "\n" (
        port: "iptables -D nixos-fw -p udp --dport ${toString port} -s ${ip} -j nixos-fw-accept || true"
      ) udpPorts;
    in
    "${tcpRules}\n${udpRules}"
  ) cfg.sunshine.allowedIps;

  scaledCfg = cfg.sunshine.scaledDesktop;

  # omanix-scale (pkgs/omanix-scripts/src/omanix-scale.sh) owns the
  # compositor-scale toggle — see the script's own comments for why hyprctl
  # eval hl.monitor{...}/hl.config{...} (not `hyprctl keyword`) is required
  # with this Lua config parser.
  #
  # `pkgs.omanix-scripts` (the bare overlay package) has no scaledDesktop
  # values baked in — those are only injected by the home-manager module
  # (modules/home-manager/scripts/default.nix, via osConfig) for the
  # omanix-menu-triggered instance. Build our own override here from the same
  # NixOS-level cfg so the Sunshine-triggered instance matches it exactly,
  # without reaching into home-manager's config from a NixOS module.
  # `monitor`/`mode` have no defaults, so they're guarded by `enable`.
  omanixScaleScripts = pkgs.omanix-scripts.override {
    scaledDesktopMonitor = if scaledCfg.enable then scaledCfg.monitor else "";
    scaledDesktopMode = if scaledCfg.enable then scaledCfg.mode else "";
    scaledDesktopPosition = if scaledCfg.enable then scaledCfg.position else "";
    scaledDesktopScale = if scaledCfg.enable then scaledCfg.scale else "";
    scaledDesktopRevertScale = if scaledCfg.enable then scaledCfg.revertScale else "";
    scaledDesktopSensitivity = if scaledCfg.enable then scaledCfg.sensitivity else "";
    scaledDesktopRevertSensitivity = if scaledCfg.enable then scaledCfg.revertSensitivity else "";
    scaledDesktopCursorSize = if scaledCfg.enable then toString scaledCfg.cursorSize else "";
    scaledDesktopRevertCursorSize = if scaledCfg.enable then toString scaledCfg.revertCursorSize else "";
  };
  # Absolute path: the Sunshine user service forces PATH=null, so prep-cmd
  # children can't resolve binaries from PATH.
  omanixScaleBin = "${omanixScaleScripts}/bin/omanix-scale";

  # Default names embed the scale and monitor so the two entries are
  # self-explanatory in the Moonlight client. Overridable via scaledName /
  # nativeName. Sunshine streams the primary output regardless of which entry
  # is picked, so the monitor name is documentation for the user, not a selector.
  scaledName =
    if scaledCfg.scaledName != null then
      scaledCfg.scaledName
    else
      "Desktop (Scaled ${scaledCfg.scale}x — ${scaledCfg.monitor})";
  nativeName =
    if scaledCfg.nativeName != null then
      scaledCfg.nativeName
    else
      "Desktop (Native — ${scaledCfg.monitor})";

  scaledDesktopApp = {
    name = scaledName;
    image-path = "desktop.png";
    prep-cmd = [
      {
        do = "${omanixScaleBin} --on";
        undo = "${omanixScaleBin} --off";
      }
    ];
  };

  # Companion "native" entry: same host session, no prep-cmd, so the monitor
  # scale is left untouched at its normal 1x. Pick this in Moonlight when the
  # client is driving an external display that doesn't want the UI enlarged.
  # No `output` key — in Sunshine's apps.json `output` is a log-file path, not
  # a monitor selector; monitor choice is global / done in prep-cmd. A bare
  # name-only entry is the canonical passthrough stream.
  nativeDesktopApp = {
    name = nativeName;
    image-path = "desktop.png";
  };

  sunshineApps =
    lib.optionals scaledCfg.enable [
      scaledDesktopApp
      nativeDesktopApp
    ]
    ++ cfg.sunshine.extraApps;
in
{
  config = lib.mkIf (cfg.enable && cfg.sunshine.enable) {
    environment.systemPackages = [
      toggleScript
      toggleDesktopItem
    ];

    services.sunshine = {
      enable = true;
      package = sunshinePackage;
      capSysAdmin = true;
      autoStart = false;
      # Declaring apps makes Sunshine ignore its web-UI apps.json in favour of
      # this generated, reproducible list. Only set it when we actually have
      # apps to declare, so an empty config still allows web-UI management.
      applications = lib.mkIf (sunshineApps != [ ]) {
        env.PATH = "$(PATH):$(HOME)/.local/bin";
        apps = sunshineApps;
      };
    };

    networking.firewall.extraCommands = lib.mkIf (cfg.sunshine.allowedIps != [ ]) firewallRules;
    networking.firewall.extraStopCommands = lib.mkIf (cfg.sunshine.allowedIps != [ ]) firewallStopRules;

    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        userServices = true;
      };
      # Don't advertise container bridge addresses
      denyInterfaces = [ "docker0" ];
    };

    # Avahi is the mDNS responder; resolved's built-in mDNS fights it over
    # port 5353 and causes "Host name conflict" renames (host-2.local, ...).
    services.resolved.settings.Resolve.MulticastDNS = lib.mkDefault false;
  };
}
