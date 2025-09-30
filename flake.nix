{
  description = "X Minecraft Launcher (XMCL) - A modern Minecraft launcher";

  inputs = {
    systems.url = "github:nix-systems/default";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      xmclVersion = "0.52.4";
      sha256 = "sha256:ed74065f087f3a1bf75884b1a0d4256cc044385ad3077c32b9735d7eb261aa1b";
      runtimeDeps =
        with pkgs;
        [
          stdenv.cc.cc.lib
          alsa-lib
          atk
          cairo
          cups
          dbus
          expat
          fontconfig
          freetype
          gdk-pixbuf
          glib
          gobject-introspection
          gtk3
          libsecret
          hicolor-icon-theme
          libdrm
          libGL
          libglvnd
          mesa
          nspr
          nss
          pango
          udev
          vulkan-loader
        ]
        ++ (with pkgs.xorg; [
          libX11
          libXcomposite
          libXcursor
          libXdamage
          libXext
          libXfixes
          libXi
          libXrandr
          libXrender
          libXScrnSaver
          libxshmfence
          libXtst
          libxcb
          libXxf86vm
        ]);
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
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

      makeXmclPackage =
        {
          commandLineArgs ? "",
          jres ? [ ],
        }:
        pkgs.stdenv.mkDerivation {
          pname = "xmcl";
          version = xmclVersion;

          src = pkgs.fetchurl {
            url = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${xmclVersion}/xmcl-${xmclVersion}-x64.tar.xz";
            sha256 = sha256;
          };
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            makeWrapper
          ];
          buildInputs = runtimeDeps;
          dontConfigure = true;
          dontBuild = true;
          installPhase =
            let
              name = "xmcl";
              desktopEntry = pkgs.makeDesktopItem {
                name = name;
                desktopName = "X Minecraft Launcher";
                exec = "xmcl";
                terminal = false;
                icon = "xmcl";
              };
              javaJson = createJavaJson jres;
            in
            ''
              runHook preInstall

              mkdir -p $out/bin $out/opt/xmcl $out/share/applications $out/share/config $out/share/icons/hicolor
              cp -r ./* $out/opt/xmcl/

              cp ${javaJson} $out/share/config/java.json

              cp -r ${./assets}/icons/ $out/share/

              makeWrapper $out/opt/xmcl/${name} $out/bin/${name} \
              --add-flags "${commandLineArgs}" \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeDeps}" \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.xdg-utils ]}
              cp ${desktopEntry}/share/applications/${name}.desktop $out/share/applications/${name}.desktop

              runHook postInstall
            '';
          autoPatchelf = true;

          meta = with pkgs.lib; {
            description = "X Minecraft Launcher (XMCL)";
            homepage = "https://github.com/Voxelum/x-minecraft-launcher";
            license = licenses.mit;
            platforms = [ "x86_64-linux" ];
            maintainers = with maintainers; [
              "x45iq"
            ];
          };
        };
    in
    {
      packages.x86_64-linux.default = makeXmclPackage { };
      formatter = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          config = self.checks.${system}.pre-commit-check.config;
          inherit (config) package configFile;
          script = ''
            ${package}/bin/pre-commit run --all-files --config ${configFile}
          '';
        in
        pkgs.writeShellScriptBin "pre-commit-run" script
      );

      checks = forEachSystem (system: {
        pre-commit-check = inputs.git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
          };
        };
      });
      homeModules.xmcl =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        with lib;
        let
          cfg = config.programs.xmcl;
          xmclPackage = makeXmclPackage {
            commandLineArgs = lib.concatStringsSep " " cfg.commandLineArgs;
            jres = cfg.jres;
          };
        in
        {
          options.programs.xmcl = {
            enable = mkEnableOption "X Minecraft Launcher";
            commandLineArgs = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [
                "--enable-features=UseOzonePlatform"
                "--ozone-platform=wayland"
              ];
              description = "Additional command line arguments to pass to XMCL";
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

          config = mkIf cfg.enable {
            home.packages = [
              xmclPackage
            ];
            home.file.".config/xmcl/java.json".source =
              if cfg.jres != [ ] then
                "${xmclPackage}/share/config/java.json"
              else
                pkgs.writeText "java.json" (builtins.toJSON { all = [ ]; });
          };
        };
    };
}
