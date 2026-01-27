{ pkgs, ... }:
{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = [
      pkgs.fcitx5-gtk
      # Support for Qt5 apps
      pkgs.libsForQt5.fcitx5-qt
      # Support for Qt6 apps (Preferred in Unstable/24.11)
      pkgs.kdePackages.fcitx5-qt
      # The config tool has been moved to Qt6/kdePackages
      pkgs.kdePackages.fcitx5-configtool
    ];
  };

  # Environment variables to force apps to use Fcitx5
  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    # Tell Fcitx where to find our custom map
    XCOMPOSEFILE = "$HOME/.config/XCompose";
  };

  # Port the XCompose file from upstream
  xdg.configFile."XCompose".text = ''
    include "%L"

    # Emoji
    <Multi_key> <m> <s> : "😄" # smile
    <Multi_key> <m> <c> : "😂" # cry
    <Multi_key> <m> <l> : "😍" # love
    <Multi_key> <m> <v> : "✌️" # victory
    <Multi_key> <m> <h> : "❤️" # heart
    <Multi_key> <m> <y> : "👍" # yes
    <Multi_key> <m> <n> : "👎" # no
    <Multi_key> <m> <f> : "🖕" # fuck
    <Multi_key> <m> <w> : "🤞" # wish
    <Multi_key> <m> <r> : "🤘" # rock
    <Multi_key> <m> <k> : "😘" # kiss
    <Multi_key> <m> <e> : "🙄" # eyeroll
    <Multi_key> <m> <d> : "🤤" # droll
    <Multi_key> <m> <m> : "💰" # money
    <Multi_key> <m> <x> : "🎉" # xellebrate
    <Multi_key> <m> <1> : "💯" # 100%
    <Multi_key> <m> <t> : "🥂" # toast
    <Multi_key> <m> <p> : "🙏" # pray
    <Multi_key> <m> <i> : "😉" # wink
    <Multi_key> <m> <o> : "👌" # OK
    <Multi_key> <m> <g> : "👋" # greeting
    <Multi_key> <m> <a> : "💪" # arm
    <Multi_key> <m> <b> : "🤯" # blowing

    # Typography
    <Multi_key> <space> <space> : "—"
  '';
}
