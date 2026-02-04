{ config, lib, ... }:

let
  cfg = config.omanix.apps.whatsapp;
in
{
  options.omanix.apps.whatsapp = {
    enable = lib.mkEnableOption "WhatsApp";
  };

  config = lib.mkIf cfg.enable {
    xdg.desktopEntries.whatsapp = {
      name = "WhatsApp";
      genericName = "Chat";
      exec = "chromium --app=https://web.whatsapp.com";
      terminal = false;
      categories = [
        "Network"
        "Chat"
      ];
      icon = ../../../assets/icons/WhatsApp.png;
    };
  };
}
