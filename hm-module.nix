{self}: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkMerge
    ;

  flakeXmcl = self.packages.${pkgs.stdenv.hostPlatform.system}.default;

  cfg = config.programs.xmcl;

  createJavaJson = jres:
    if jres == []
    then pkgs.writeText "java.json" (builtins.toJSON {all = [];})
    else
      pkgs.writeText "java.json" (
        builtins.toJSON {
          all =
            builtins.map (
              jre: let
                version = lib.getVersion jre;
                splitted = lib.splitString "." version;
                candidate =
                  if lib.elemAt splitted 0 == "1"
                  then lib.elemAt splitted 1
                  else lib.elemAt splitted 0;
                majorVersion =
                  if lib.match "([0-9]+)" candidate != null
                  then lib.toInt candidate
                  else if lib.match "8u.*" candidate != null
                  then 8
                  else throw "Invalid java version : ${candidate} of ${jre}";
              in {
                path = lib.makeSearchPath "bin/java" [jre];
                inherit version majorVersion;
                valid = true;
              }
            )
            jres;
        }
      );
in {
  options.programs.xmcl = {
    enable = mkEnableOption "X Minecraft Launcher";

    package = mkOption {
      type = types.package;
      default = flakeXmcl;
      defaultText = "self.packages.<system>.default";
      description = "XMCL package to use.";
    };

    commandLineArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["--password-store=\"gnome-libsecret\""];
      description = "Additional command line arguments to pass to XMCL.";
    };

    jres = mkOption {
      type = types.listOf types.package;
      default = [];
      example = [
        pkgs.jre8
        pkgs.temurin-jre-bin-17
      ];
      description = "JREs";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [
        (cfg.package.override {
          commandLineArgs = lib.concatStringsSep " " cfg.commandLineArgs;
        })
      ];
    }

    (mkIf (cfg.jres != []) {
      xdg.configFile."xmcl/java.json".source = createJavaJson cfg.jres;
    })
  ]);
}
