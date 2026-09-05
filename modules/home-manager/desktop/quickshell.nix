{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omanix.quickshell;

  # Declarative base merged over the user's shell.json on every activation
  # (declared keys win). Kept minimal here: only the required version marker
  # and the disabled first-party plugins. Bar layout and the idle block become
  # option-driven in later work and join this base then.
  declaredBase = pkgs.writeText "omanix-shell.json" (builtins.toJSON {
    version = 1;
    disabledPlugins = cfg.disabledPlugins;
  });
in
{
  options.omanix.quickshell = {
    enable = lib.mkEnableOption "the Omanix Quickshell desktop shell";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.omanix-shell;
      defaultText = lib.literalExpression "pkgs.omanix-shell";
      description = "The Quickshell shell code package. OMANIX_PATH resolves to its share/omanix directory.";
    };

    disabledPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "omanix.dropbox"
        "omanix.nightlight"
        "omanix.disk-speedtest"
      ];
      description = ''
        First-party shell plugin ids seeded into shell.json's disabledPlugins,
        so the shell never invokes a command with no omanix implementer. This
        list is reconciled onto the user's config on every rebuild (declared
        config wins).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.quickshell
      pkgs.jq
    ];

    # Reconcile the declared base onto the user-writable shell.json. The shell
    # treats a valid user file as canonical (no in-shell merge), so this merge
    # is what re-applies declared keys each rebuild. Never a store symlink (R3)
    # — the file stays writable and is IPC-mutated at runtime.
    home.activation.omanixShellConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.config/omanix"
      _omanix_cfg="$HOME/.config/omanix/shell.json"
      if [ -f "$_omanix_cfg" ] && ${pkgs.jq}/bin/jq -e . "$_omanix_cfg" >/dev/null 2>&1; then
        run ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$_omanix_cfg" "${declaredBase}" > "$_omanix_cfg.tmp"
      else
        run cp "${declaredBase}" "$_omanix_cfg.tmp"
      fi
      run mv "$_omanix_cfg.tmp" "$_omanix_cfg"
      run chmod u+w "$_omanix_cfg"
      # Best-effort reload; a guarded no-op until the IPC CLI lands. Must never
      # fail activation whether or not the shell is running.
      run sh -c 'command -v omanix-refresh-shell >/dev/null 2>&1 && omanix-refresh-shell || true'
    '';
  };
}
