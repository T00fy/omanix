{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.jetbrains;
in
{
  options.omanix.apps.jetbrains = {
    intellij = {
      enable = lib.mkEnableOption "IntelliJ IDEA";
    };
    rustrover = {
      enable = lib.mkEnableOption "JetBrains RustRover";
    };
  };
  config = lib.mkIf (cfg.intellij.enable || cfg.rustrover.enable) {
    home.packages = lib.flatten [
      (lib.optional cfg.intellij.enable pkgs.jetbrains.idea)
      (lib.optional cfg.rustrover.enable pkgs.jetbrains.rust-rover)
    ];
  };
}
