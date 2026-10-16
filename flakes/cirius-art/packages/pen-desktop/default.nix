{
  lib,
  stdenv,
  appimageTools,
  autoPatchelfHook,
  fetchurl,
}:
let
  pname = "pen-desktop";
  version = "1.2.18";

  # www.pen.dev/download only serves a rolling "latest" behind a short-lived
  # signed redirect. electron-builder's app-update.yml names the real release
  # repo, whose assets are versioned and immutable -- use those, so a rebuild
  # keeps producing the version this file claims.
  #
  # To bump: pick a tag from
  #   https://github.com/highagency/pen-desktop-releases/releases
  # set `version`, then refresh the hash with
  #   nix store prefetch-file --json <the url below>
  src = fetchurl {
    url =
      "https://github.com/highagency/pen-desktop-releases/releases/download/"
      + "v${version}/Pen-${version}-linux-x86_64.AppImage";
    hash = "sha256-sm+TRIodw6dPcFauZQ6VoEps5wtDAz3tNjzsPeiNrJM=";
  };

  contents = appimageTools.extract { inherit pname version src; };

  # The AppImage also carries the stdio MCP server that agents use to drive the
  # desktop app. It is a generic-linux Go binary (interpreter /lib64/ld-linux,
  # libc.so.6 its only NEEDED), so it cannot run straight out of the extracted
  # tree the way it can on an FHS distro -- patch it and give it a real name on
  # PATH, rather than having callers point at an unpacked asar path.
  mcp-server = stdenv.mkDerivation {
    pname = "pen-mcp-server";
    inherit version;

    dontUnpack = true;

    nativeBuildInputs = [ autoPatchelfHook ];

    installPhase = ''
      runHook preInstall

      install -Dm555 \
        ${contents}/resources/app.asar.unpacked/out/mcp-server-linux-x64 \
        $out/bin/pen-mcp-server

      runHook postInstall
    '';

    meta = {
      description = "MCP server bundled with the pen.dev desktop application";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "pen-mcp-server";
    };
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/pen.desktop $out/share/applications/pen-desktop.desktop
    install -Dm444 ${contents}/pen.png $out/share/icons/hicolor/512x512/apps/pen-desktop.png

    ln -s ${lib.getExe mcp-server} $out/bin/pen-mcp-server

    # Upstream ships --no-sandbox because a bare AppImage cannot use the
    # setuid helper. Wrapped here the namespace sandbox works, so keep it on.
    substituteInPlace $out/share/applications/pen-desktop.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=pen-desktop' \
      --replace-fail 'Icon=pen' 'Icon=pen-desktop'
  '';

  passthru = {
    inherit mcp-server;
  };

  meta = {
    description = "pen.dev desktop application for creating designs with code";
    homepage = "https://docs.pen.dev/getting-started/installation";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pen-desktop";
  };
}
