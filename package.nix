{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  cups,
  dbus,
  cairo,
  gtk3,
  pango,
  xorg,
  nss,
  nspr,
  libdrm,
  mesa,
  alsa-lib,
  libxkbcommon,
  libglvnd,
  udev,
  libsecret,
  copyDesktopItems,
  commandLineArgs ? "",
}:
stdenv.mkDerivation rec {
  pname = "xmcl";
  version = "0.52.4";
  src = fetchurl {
    url = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${version}/xmcl-${version}-x64.tar.xz";
    sha256 = "sha256:ed74065f087f3a1bf75884b1a0d4256cc044385ad3077c32b9735d7eb261aa1b";
  };
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];
  buildInputs = [
    cups
    dbus
    cairo
    gtk3
    pango
    nss
    nspr
    libdrm
    mesa
    alsa-lib
    libxkbcommon
    xorg.libXdamage
    xorg.libXext
    xorg.libX11
    xorg.libXcomposite
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb

    udev
    libglvnd
    libsecret
  ];
  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = "${pname} %U";
      desktopName = "X Minecraft Launcher";
      terminal = false;
      icon = pname;
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/opt/xmcl $out/share/icons/hicolor
    cp -r ./* $out/opt/xmcl/

    cp -r ${./assets}/icons/ $out/share/

    makeWrapper $out/opt/xmcl/${pname} $out/bin/${pname} \
      --add-flags ${lib.escapeShellArg commandLineArgs} \
      --prefix LD_LIBRARY_PATH : "$out/opt/xmcl:${lib.makeLibraryPath buildInputs}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
    runHook postInstall
  '';
  autoPatchelf = true;

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
