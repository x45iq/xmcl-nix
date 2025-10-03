{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkMerge
    ;
  cfg = config.programs.xmcl;
  getJavaVersion =
    jre:
    pkgs.runCommand "get-java-version"
      {
        nativeBuildInputs = [ jre ];
      }
      ''
        java_version=$(${jre}/bin/java -version 2>&1 | head -n1 | cut -d'"' -f2)
        major_version=$(echo $java_version | cut -d'.' -f1)
        if [ "$major_version" = "1" ]; then
          major_version=$(echo $java_version | cut -d'.' -f2)
        fi
        mkdir -p $out/
        echo -n "$java_version" > $out/version
        echo -n "$major_version" > $out/major
      '';

  createJavaJson =
    jres:
    if jres == [ ] then
      pkgs.writeText "java.json" (builtins.toJSON { all = [ ]; })
    else
      pkgs.writeText "java.json" (
        builtins.toJSON {
          all = builtins.map (
            jre:
            let
              versionInfo = getJavaVersion jre;
              version = builtins.readFile "${versionInfo}/version";
              majorVersion = builtins.fromJSON (builtins.readFile "${versionInfo}/major");
            in
            {
              path = "${jre}/bin/java";
              version = version;
              majorVersion = majorVersion;
              valid = true;
            }
          ) jres;
        }
      );
in
{
  options.programs.xmcl = {
    enable = mkEnableOption "X Minecraft Launcher";

    package = mkOption {
      type = types.package;
      default = pkgs.xmcl;
      defaultText = "pkgs.xmcl";
      description = "XMCL package to use.";
    };

    commandLineArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--password-store=\"gnome-libsecret\"" ];
      description = "Additional command line arguments to pass to XMCL.";
    };
    jres = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = [
        pkgs.jre8
        pkgs.temurin-jre-bin-17
      ];
      description = "JREs";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      nixpkgs.overlays = [
        (final: prev: {
          xmcl = prev.callPackage ./package.nix {
            commandLineArgs = lib.concatStringsSep " " cfg.commandLineArgs;
          };
        })
      ];
    }

    (mkIf (cfg.jres != [ ]) {
      xdg.configFile."xmcl/java.json".source = createJavaJson cfg.jres;
    })
  ]);
}
