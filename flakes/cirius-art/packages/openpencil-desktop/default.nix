{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "openpencil-desktop";
  version = "0.16.0";

  # Releases are versioned and immutable, so a rebuild keeps producing the
  # version this file claims.
  #
  # To bump: pick a tag from
  #   https://github.com/open-pencil/open-pencil/releases
  # set `version`, then refresh the hash with
  #   nix store prefetch-file --json <the url below>
  src = fetchurl {
    url =
      "https://github.com/open-pencil/open-pencil/releases/download/"
      + "v${version}/OpenPencil_${version}_amd64.AppImage";
    hash = "sha256-p9iTrDU2fI6gALAIkBNs5YYaE78ldLRHYPd4Sc/fd6I=";
  };

  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/usr/share/applications/OpenPencil.desktop \
      $out/share/applications/openpencil-desktop.desktop
    install -Dm444 ${contents}/usr/share/icons/hicolor/32x32/apps/OpenPencil.png \
      $out/share/icons/hicolor/32x32/apps/openpencil-desktop.png
    install -Dm444 ${contents}/usr/share/icons/hicolor/128x128/apps/OpenPencil.png \
      $out/share/icons/hicolor/128x128/apps/openpencil-desktop.png
    install -Dm444 ${contents}/usr/share/icons/hicolor/256x256@2/apps/OpenPencil.png \
      $out/share/icons/hicolor/512x512/apps/openpencil-desktop.png

    substituteInPlace $out/share/applications/openpencil-desktop.desktop \
      --replace-fail 'Exec=OpenPencil' 'Exec=openpencil-desktop' \
      --replace-fail 'Icon=OpenPencil' 'Icon=openpencil-desktop'
  '';

  meta = {
    description = "Open-source Figma-compatible design editor";
    homepage = "https://openpencil.dev";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "openpencil-desktop";
  };
}
