{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  makeWrapper,
  gtk3,
  glib,
  glib-networking,
  gdk-pixbuf,
  cairo,
  dbus,
  wayland,
  libsoup_3,
  webkitgtk_4_1,
  xdg-utils,
  desktop-file-utils,
  writeShellScriptBin,
}:
let
  # Tauri registers current_exe, which is the unwrapped ELF on Nix. Select our
  # desktop entry instead so browser handoffs retain the GTK environment.
  xdgMime = writeShellScriptBin "xdg-mime" ''
    if [ "$#" -eq 3 ] && [ "$1" = default ] && [ "$3" = x-scheme-handler/doop ]; then
      # Keep an existing correct association, including a declarative one.
      if [ "$(${xdg-utils}/bin/xdg-mime query default "$3")" = doop.desktop ]; then
        exit 0
      fi
      exec ${xdg-utils}/bin/xdg-mime default doop.desktop "$3"
    fi
    exec ${xdg-utils}/bin/xdg-mime "$@"
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "doop";
  version = "0.12.0";

  # Desktop releases have their own version sequence, separate from the server.
  src = fetchurl {
    url = "https://github.com/kgoedecke/doop/releases/download/desktop-v${finalAttrs.version}/doop_${finalAttrs.version}_amd64.deb";
    hash = "sha256-tzmqA5p0ocAM3fB9bxnnW0DbarSJUg1MYzXvTrHSVp0=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
    makeWrapper
  ];
  buildInputs = [
    gtk3
    glib
    glib-networking
    gdk-pixbuf
    cairo
    dbus
    wayland
    libsoup_3
    webkitgtk_4_1
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/bin usr/share $out/
    substituteInPlace $out/share/applications/doop.desktop \
      --replace-fail 'Exec=doop-desktop' "Exec=$out/bin/doop-desktop %u" \
      --replace-fail 'MimeType=x-scheme-handler/doop' 'MimeType=x-scheme-handler/doop;'
    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --unset APPIMAGE
      --unset LD_LIBRARY_PATH
      # Avoid WebKitGTK's Wayland protocol error with NVIDIA explicit sync.
      --set-default __NV_DISABLE_EXPLICIT_SYNC 1
      --prefix PATH : ${
        lib.makeBinPath [
          xdgMime
          xdg-utils
          desktop-file-utils
        ]
      }
    )
  '';

  meta = {
    description = "Desktop client for the Doop collaborative design canvas";
    homepage = "https://github.com/kgoedecke/doop";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "doop-desktop";
  };
})
