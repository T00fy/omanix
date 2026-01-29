{ config, pkgs, lib, inputs, ... }:

let
  elephantPkg = inputs.elephant.packages.${pkgs.system}.default;
in
{
  # REMOVED: home.packages = [ elephantPkg ]; 
  # We let the upstream module handling install the binary to avoid conflicts.
  # If the binary is missing after this, we will use a package override instead.

  xdg.configFile = {
    # ... keep config files ...
    "elephant/desktopapplications.toml".text = ''
      show_actions = false
      only_search_title = true
      history = false
    '';

    "elephant/calc.toml".text = ''
      async = false
    '';
  };

  # ... keep service definition ...
  systemd.user.services.elephant = lib.mkForce {
    Unit = {
      Description = "Elephant Data Provider for Walker";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      # We still reference the exact binary path here for the service execution
      ExecStart = "${elephantPkg}/bin/elephant service run";
      Restart = "always";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
