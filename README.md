# xmcl-nix
**X Minecraft Launcher (XMCL)** - A modern Minecraft launcher packaged for Nix and Home Manager.
This flake allows you to install and run [XMCL](https://github.com/Voxelum/x-minecraft-launcher) on NixOS and other systems with Nix.

## ✨ Features
- `xmcl` package with necessary runtime dependencies
- Support for additional command line arguments
- Automatic detection of specified JREs in XMCL
- Generation of `java.json` configuration for available Java versions
- Wayland and Ozone Platform support
- Home Manager module for convenient integration

## 🚀 Installation
### Via `nix run`
```bash
nix run github:x45iq/xmcl-nix
```

### Adding to `flake.nix`
```nix
{
  inputs = {
    xmcl.url = "github:x45iq/xmcl-nix";
  };
  outputs = { self, xmcl, ... }: {
    packages.x86_64-linux.my-xmcl = xmcl.packages.x86_64-linux.default;
  };
}
```

### Home Manager Module
```nix
{
  inputs = {
    xmcl.url = "github:x45iq/xmcl-nix";
  };
  outputs = { self, nixpkgs, xmcl, ... }: {
    homeConfigurations.my-user = nixpkgs.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      modules = [
        xmcl.homeModules.xmcl
        {
          programs.xmcl = {
            enable = true;
            commandLineArgs = [
              "--password-store=\"gnome-libsecret\""
            ];
            jres = [
              pkgs.jre8
              pkgs.temurin-jre-bin-17
            ];
          };
        }
      ];
    };
  };
}
```

## ⚙️ Home Manager Module Options
| Option                          | Type              | Default     | Description                              |
| ------------------------------- | ----------------- | ----------- | ---------------------------------------- |
| `programs.xmcl.enable`          | `bool`            | `false`     | Enables XMCL installation                |
| `programs.xmcl.package`         | `package`         | `pkgs.xmcl` | XMCL package to use                      |
| `programs.xmcl.commandLineArgs` | `list of string`  | `[]`        | Additional command line arguments        |
| `programs.xmcl.jres`            | `list of package` | `[]`        | List of JREs available to XMCL           |

## 🔧 Implementation Details
- Automatic generation of `java.json` with information about available Java versions
- Support for automatic detection of major and full Java versions
- Wayland integration via Ozone Platform
- Automatic binary patching
- Desktop file support for integration with desktop environments
