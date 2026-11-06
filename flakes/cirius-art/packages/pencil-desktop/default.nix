{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  wrapGAppsHook3,
  makeWrapper,
  makeDesktopItem,
  asar,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libgbm,
  libglvnd,
  libxkbcommon,
  nspr,
  nss,
  pango,
  systemdLibs,
  vulkan-loader,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libXtst,
  libxcb,
}:
let
  version = "1.2.22";
  sources = {
    x86_64-linux = {
      arch = "x64";
      hash = "sha256-Htq8mR71E8w4TUFaJZGx9VEq6km5c/eu5seEQe8sCBI=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-o+onc2CyS4dIbjpgtWXiRVToca5cDA58iahbL6nxTto=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
  desktopItem = makeDesktopItem {
    name = "pencil-desktop";
    desktopName = "Pencil (pen.dev)";
    comment = "Design with the pen.dev desktop application";
    exec = "pencil-desktop %U";
    icon = "pencil-desktop";
    categories = [
      "Graphics"
      "VectorGraphics"
    ];
  };
in
stdenv.mkDerivation {
  pname = "pencil-desktop";
  inherit version;

  # The download page redirects to a rolling object with a short-lived signed
  # URL. app-update.yml identifies this official repo; use its versioned assets.
  src =
    (fetchurl {
      url = "https://github.com/highagency/pen-desktop-releases/releases/download/v${version}/Pen-${version}-linux-${source.arch}.tar.gz";
      inherit (source) hash;
      meta.license = lib.licenses.unfree;
    }).overrideAttrs
      (_: {
        allowSubstitutes = false;
      });

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
    makeWrapper
    asar
  ];
  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgbm
    libxkbcommon
    nspr
    nss
    pango
    systemdLibs
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXtst
    libxcb
    stdenv.cc.cc.lib
  ];
  runtimeDependencies = [
    libglvnd
    vulkan-loader
  ];

  dontBuild = true;
  dontStrip = true;
  dontWrapGApps = true;
  dontAutoPatchelf = true;
  preferLocalBuild = true;
  allowSubstitutes = false;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/pencil-desktop" "$out/bin"
    cp -a ./. "$out/lib/pencil-desktop/"

    asar extract-file resources/app.asar out/assets/512x512.png
    install -Dm444 512x512.png "$out/share/icons/hicolor/512x512/apps/pencil-desktop.png"
    install -Dm444 ${desktopItem}/share/applications/pencil-desktop.desktop \
      "$out/share/applications/pencil-desktop.desktop"

    ln -s "$out/lib/pencil-desktop/resources/app.asar.unpacked/out/mcp-server-linux-${source.arch}" \
      "$out/bin/pencil-mcp-server"
    runHook postInstall
  '';

  postFixup = ''
    # Agent voice libraries ship their own GLib. Do not let those nested copies
    # win over Nix's GTK dependencies when patching the Electron executable.
    autoPatchelf --no-recurse "$out/lib/pencil-desktop"
    autoPatchelf "$out/lib/pencil-desktop/resources"
    makeWrapper "$out/lib/pencil-desktop/pen" "$out/bin/pencil-desktop" \
      "''${gappsWrapperArgs[@]}"
  '';

  meta = {
    description = "Pencil (pen.dev) desktop design application from the official Linux tarball";
    homepage = "https://www.pen.dev/";
    changelog = "https://github.com/highagency/pen-desktop-releases/releases/tag/v${version}";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames sources;
    mainProgram = "pencil-desktop";
  };
}
