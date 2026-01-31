{
  lib,
  addDriverRunpath,
  stdenv,
  fetchurl,
  makeWrapper,
  makeDesktopItem,
  electron,
  glfw3-minecraft,
  openal,
  alsa-lib,
  libjack2,
  libpulseaudio,
  pipewire,
  libGL,
  libX11,
  libXcursor,
  libXext,
  libXrandr,
  libXxf86vm,
  udev,
  vulkan-loader,
  copyDesktopItems,
  commandLineArgs ? "",
}: let
  version = "0.54.3";
  sources = let
    base = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${version}";
  in {
    x86_64-linux = {
      url = "${base}/app-${version}-linux.asar";
      sha256 = "sha256:a53a4acd492d1351680801b1224a280785ac417e14f3c8d5221488ddcf5f6b53";
    };
    aarch64-linux = {
      url = "${base}/app-${version}-linux-arm64.asar";
      sha256 = "sha256:0afb7dc82b1d1e8e3db0b710576a3d85170f8d3ba56192aa8e33d7d58b700586";
    };
  };
  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  runtimeLibs = [
    (lib.getLib stdenv.cc.cc)
    glfw3-minecraft
    openal

    ## openal
    alsa-lib
    libjack2
    libpulseaudio
    pipewire

    ## glfw
    libGL
    libX11
    libXcursor
    libXext
    libXrandr
    libXxf86vm

    udev # oshi

    vulkan-loader # VulkanMod's lwjgl
  ];
in
  stdenv.mkDerivation rec {
    pname = "xmcl";
    inherit version;
    src = fetchurl {
      url = source.url;
      sha256 = source.sha256;
    };
    nativeBuildInputs = [
      makeWrapper
      copyDesktopItems
    ];
    buildInputs = electron.buildInputs;

    desktopItems = [
      (makeDesktopItem {
        name = pname;
        exec = "${pname} %U";
        desktopName = "X Minecraft Launcher";
        terminal = false;
        icon = pname;
      })
    ];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/${pname} $out/share/icons/hicolor
      cp $src $out/share/${pname}/app.asar

      cp -r ${./assets}/icons/ $out/share/

      makeWrapper ${lib.getExe electron} $out/bin/${pname} \
        --add-flags $out/share/${pname}/app.asar \
        --add-flags ${lib.escapeShellArg commandLineArgs} \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        --set LD_LIBRARY_PATH ${addDriverRunpath.driverLink}/lib:${lib.makeLibraryPath runtimeLibs}
      runHook postInstall
    '';

    meta = {
      description = "X Minecraft Launcher (XMCL)";
      homepage = "https://github.com/Voxelum/x-minecraft-launcher";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux" "aarch64-linux"];
      maintainers = with lib.maintainers; [
        x45iq
      ];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      desktopFileName = "${pname}.desktop";
    };
  }
