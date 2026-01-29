# Walker Configuration

Walker is the application launcher (Super+Space).

## Features

| Prefix | Function                        |
|--------|--------------------------------|
| (none) | Search installed applications  |
| `.`    | File search                    |
| `=`    | Calculator                     |
| `@`    | Web search                     |
| `$`    | Clipboard history              |
| `:`    | Symbols/Emoji                  |
| `>`    | Run command                    |

## Powered by Elephant

Walker uses Elephant as its data provider. Config files:

```
~/.config/elephant/elephant.toml      # Main config
~/.config/elephant/websearch.toml     # Search engines
~/.config/elephant/files.toml         # File search paths
```

## Overriding Web Search Engines

```nix
xdg.configFile."elephant/websearch.toml".text = lib.mkForce ''
  [[engines]]
  name = "DuckDuckGo"
  url = "https://duckduckgo.com/?q=%s"
  prefix = "d"
  
  [[engines]]
  name = "GitHub"
  url = "https://github.com/search?q=%s"
  prefix = "gh"
'';
```

## Restart Walker

If Walker misbehaves, run: `omarchy-restart-walker`

## Documentation

https://github.com/abenz1267/walker
