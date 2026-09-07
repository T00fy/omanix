{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.omanix.audio;
in
{
  options.omanix.audio.speakerTuning.enable = lib.mkEnableOption ''
    per-laptop speaker EQ/limiter as a PipeWire filter-chain.

    Ships the tuning framework, an on-demand systemd user service hosting the
    filter-chain in its own PipeWire client, and the LV2 limiter (lsp-plugins).
    Nothing starts automatically: run `omanix-audio-tuning on` (or use the menu)
    to apply the tuning that matches this laptop, and `omanix-audio-tuning off`
    to remove it -- neither restarts the audio server. Only laptops with a
    shipped tuning are affected; on others it is a no-op'';

  config = lib.mkIf cfg.speakerTuning.enable {
    # The LV2 EQ/limiter the tuning graph instantiates. Pulled into the closure
    # only when the subsystem is enabled.
    home.packages = [ pkgs.lsp-plugins ];

    # The filter-chain runs as its own PipeWire client rather than inside the
    # session daemon, so the tuning can be switched on and off without an audio
    # restart. omanix-audio-tuning renders the runtime config this unit reads and
    # start/stops the unit; the unit itself is Nix-owned so `pipewire -c` and the
    # LV2 path are declarative. WantedBy is empty on purpose -- it is started on
    # demand, never at login.
    systemd.user.services.omanix-speaker-tuning = {
      Unit = {
        Description = "Omanix speaker tuning (PipeWire filter-chain)";
        After = [
          "pipewire.service"
          "wireplumber.service"
        ];
        Wants = [
          "pipewire.service"
          "wireplumber.service"
        ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.pipewire}/bin/pipewire -c omanix-speaker-tuning.conf";
        Environment = [ "LV2_PATH=${pkgs.lsp-plugins}/lib/lv2" ];
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ ];
      };
    };
  };
}
