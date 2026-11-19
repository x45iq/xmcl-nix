# xmcl-nix

> ⚠️ **This project is deprecated and no longer maintained.**
>
> I'm no longer working on this project and won't be fixing bugs, reviewing pull requests, or updating the package for new XMCL releases. If you still want to use it, **please fork the repository** and maintain your own copy.

**X Minecraft Launcher (XMCL)** - A modern Minecraft launcher packaged for Nix and Home Manager.
This flake allows you to install and run [XMCL](https://github.com/Voxelum/x-minecraft-launcher) on NixOS and other systems with Nix.

## 🍴 Want to keep using it?

Since the project is no longer supported, the recommended path is:

1. Fork this repository to your own GitHub account.
2. Point your flake input at your fork instead of the original repository:

```nix
inputs = {
  xmcl = {
    url = "github:<your-username>/xmcl-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ...
}
```

3. Update the XMCL version and hashes yourself when you need a newer release.

The code is provided as is, without any guarantees that it will keep working with future versions of XMCL or nixpkgs.

## ✨ Features
- `xmcl` package with necessary runtime dependencies
- Support for additional command line arguments
- Automatic detection of specified JREs in XMCL
- Generation of `java.json` configuration for available Java versions
- Wayland and Ozone Platform support
- Home Manager module for convenient integration

## 🚀 Usage (for your fork)

Replace `x45iq` with your own GitHub username in the examples below.

### Via `nix run`
```bash
nix run github:<your-username>/xmcl-nix
```

### Home Manager Module
```nix
{
  # home.nix
  imports = [
    inputs.xmcl.homeModules.xmcl
  ];

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
```

### With environment.systemPackages or home.packages

To integrate `xmcl` to your NixOS/Home Manager configuration, add the
following to your `environment.systemPackages` or `home.packages`:

```nix
# options are: 'x86_64-linux', 'aarch64-linux'

inputs.xmcl.packages."${system}".default
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

## 📌 Status

**Deprecated / unmaintained.** No further updates are planned.
