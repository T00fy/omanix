#!/usr/bin/env python3
import sys
import os
import random
import gi
import signal
import shutil
import argparse

# -----------------------------------------------------------------------------
# Dependency Checks
# -----------------------------------------------------------------------------
try:
    gi.require_version('Gtk', '4.0')
    gi.require_version('Gtk4LayerShell', '1.0')
    gi.require_version('Vte', '3.91')
        
    from gi.repository import Gtk, Gdk, GLib, Gtk4LayerShell, Vte, Gio
except ValueError as e:
    print(f"Error: Missing GTK4/LayerShell/Vte-GTK4 libraries.\n{e}")
    sys.exit(1)

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
APP_ID = "org.omanix.screensaver"
EFFECTS = [
    "beams", "binarypath", "blackhole", "bouncyballs", "bubbles", "burn", 
    "colorshift", "crumble", "decrypt", "errorcorrect", "expand", "fireworks", 
    "highlight", "laseretch", "matrix", "middleout", "orbittingvolley", 
    "overflow", "pour", "print", "rain", "randomsequence", "rings", 
    "scattered", "slice", "slide", "spotlights", "spray", "swarm", 
    "sweep", "synthgrid", "unstable", "vhstape", "waves", "wipe"
]

# -----------------------------------------------------------------------------
# The Application
# -----------------------------------------------------------------------------
class ScreensaverWindow(Gtk.ApplicationWindow):
    def __init__(self, app, monitor, logo_path):
        super().__init__(application=app)
        self.monitor = monitor
        self.logo_path = logo_path

        Gtk4LayerShell.init_for_window(self)
        Gtk4LayerShell.set_monitor(self, monitor)
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_namespace(self, "omanix-screensaver")
        
        # EXCLUSIVE mode + CAPTURE phase is the combo needed for locking
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.EXCLUSIVE)
        
        for edge in [Gtk4LayerShell.Edge.TOP, Gtk4LayerShell.Edge.BOTTOM, 
                     Gtk4LayerShell.Edge.LEFT, Gtk4LayerShell.Edge.RIGHT]:
            Gtk4LayerShell.set_anchor(self, edge, True)
        
        Gtk4LayerShell.set_exclusive_zone(self, -1)

        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(b"""
            window { background-color: black; } 
            vte-terminal { background-color: black; }
        """)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.terminal = Vte.Terminal()
        self.terminal.set_cursor_blink_mode(Vte.CursorBlinkMode.OFF)
        self.terminal.set_mouse_autohide(True)
        self.terminal.set_input_enabled(False)
        
        box = Gtk.Box()
        box.append(self.terminal)
        self.terminal.set_hexpand(True)
        self.terminal.set_vexpand(True)
        self.set_child(box)

        self.terminal.connect("child-exited", self.on_effect_finished)
        self.setup_input()
        self.spawn_effect()

    def setup_input(self):
        # Key Press - Use CAPTURE to intercept before the terminal sees it
        key_controller = Gtk.EventControllerKey()
        key_controller.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        key_controller.connect("key-pressed", self.quit_all)
        self.add_controller(key_controller)

        # Mouse Click
        click_controller = Gtk.GestureClick()
        click_controller.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        click_controller.connect("pressed", self.quit_all)
        self.add_controller(click_controller)

        # Mouse Motion
        motion_controller = Gtk.EventControllerMotion()
        motion_controller.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        motion_controller.connect("motion", self.quit_all)
        self.add_controller(motion_controller)

    def quit_all(self, *args):
        self.get_application().quit()

    def spawn_effect(self):
        effect = random.choice(EFFECTS)
        tte_bin = shutil.which("tte")
        
        if not tte_bin:
            # Silently fail or just quit if TTE isn't there
            self.get_application().quit()
            return

        argv = [
            tte_bin, 
            "--canvas-width", "0", 
            "--canvas-height", "0", 
            "--anchor-canvas", "c", 
            "--anchor-text", "c", 
            effect
        ]
        
        if self.logo_path and os.path.exists(self.logo_path):
             argv.insert(1, "--input-file")
             argv.insert(2, self.logo_path)

        try:
            self.terminal.spawn_async(
                Vte.PtyFlags.DEFAULT,
                None, argv, [], GLib.SpawnFlags.DEFAULT,
                None, None, -1, None, None
            )
        except Exception:
            self.get_application().quit()

    def on_effect_finished(self, terminal, status):
        GLib.timeout_add(1000, self.delayed_spawn)

    def delayed_spawn(self):
        self.spawn_effect()
        return False

class ScreensaverApp(Gtk.Application):
    def __init__(self, logo_path):
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.logo_path = logo_path

    def do_activate(self):
        display = Gdk.Display.get_default()
        monitors = display.get_monitors()
        for i in range(monitors.get_n_items()):
            monitor = monitors.get_item(i)
            win = ScreensaverWindow(self, monitor, self.logo_path)
            win.present()

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--logo", help="Path to logo file", default=None)
    args = parser.parse_args()

    app = ScreensaverApp(args.logo)
    app.run(None)
