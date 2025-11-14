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
    version = "0.52.7";
    src = fetchurl {
      url = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${version}/app-${version}-linux.asar";
      sha256 = "sha256:8d09138a7925a90d4269cf1f233042e3c14bea4bbb53a89a590a5207e589fcfd";
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
      platforms = ["x86_64-linux"];
      maintainers = with lib.maintainers; [
        x45iq
      ];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      desktopFileName = "${pname}.desktop";
    };
  }
