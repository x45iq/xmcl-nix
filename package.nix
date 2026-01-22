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
  version = "0.54.0";
  sources = let
    base = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${version}";
  in {
    x86_64-linux = {
      url = "${base}/app-${version}-linux.asar";
      sha256 = "sha256:94a2578000d218824db8547293ceaa5e72fc2aa28d66e770417c32ea31633be3";
    };
    aarch64-linux = {
      url = "${base}/app-${version}-linux-arm64.asar";
      sha256 = "sha256:94a2578000d218824db8547293ceaa5e72fc2aa28d66e770417c32ea31633be3";
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
