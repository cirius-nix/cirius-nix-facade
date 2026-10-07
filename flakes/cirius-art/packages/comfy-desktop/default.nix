{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  fetchzip,
  fetchPnpmDeps,
  cacert,
  pnpmConfigHook,
  nodejs_22,
  pnpm_10,
  node-gyp,
  python3,
  pkg-config,
  autoPatchelfHook,
  makeWrapper,
  runCommand,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  zlib,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  libXrender,
  libxcb,
}:
let
  electronVersion = "40.4.1";
  pnpm = pnpm_10;
  electronDist = fetchzip {
    url = "https://github.com/electron/electron/releases/download/v${electronVersion}/electron-v${electronVersion}-linux-x64.zip";
    hash = "sha256-pXGmVhBvcKI4sYGdu3uoZGrCPs26F5tDuBddLzd8df8=";
    stripRoot = false;
  };
  electronHeaders = runCommand "electron-${electronVersion}-headers" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://electronjs.org/headers/v${electronVersion}/node-v${electronVersion}-headers.tar.gz";
        hash = "sha256-N792Z0c/Biq+c0AoPVzhW7DtZFzUZcsEBooJr+EObUw=";
      }
    } -C $out --strip-components=1
  '';
  bootstrapPython = fetchurl {
    url = "https://github.com/Comfy-Org/Comfy-Desktop/releases/download/bootstrap-v3/bootstrap-python-linux-x64.tar.gz";
    hash = "sha256-0aLhjlwhuAllop8BpZ9LxeUcnpWJONzcYwBByIv7LwQ=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "comfy-desktop";
  version = "1.1.6";

  src = fetchFromGitHub {
    owner = "Comfy-Org";
    repo = "Comfy-Desktop";
    rev = "v${finalAttrs.version}";
    hash = "sha256-OUAkclXDfjXvL2aqpM8NHLQya3yqNiItQ7LzCjBnO48=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      pnpmInstallFlags
      prePnpmInstall
      ;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-51DMS9uFV9jeUDSJGSANspuFwOvrbeuhSZXrjYgZoGk=";
  };
  pnpmInstallFlags = [ "--ignore-scripts" ];
  prePnpmInstall = "pnpm config set node-linker hoisted";

  dontAutoPatchelf = true;

  nativeBuildInputs = [
    nodejs_22
    pnpm
    pnpmConfigHook
    node-gyp
    python3
    pkg-config
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libxkbcommon
    mesa
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    zlib
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libxcb
  ];

  buildPhase = ''
    runHook preBuild
    mkdir -p bootstrap-python
    tar -xzf ${bootstrapPython} -C bootstrap-python
    node-gyp rebuild --directory=node_modules/node-pty --nodedir=${electronHeaders}
    pnpm run build
    pnpm exec electron-builder --linux --dir --config.electronDist=${electronDist} --config.npmRebuild=false --config.executableName=comfy-desktop
    pnpm install --offline --prod --frozen-lockfile --ignore-scripts
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/comfy-desktop $out/bin $out/share/applications
    cp -a dist/linux-unpacked/. $out/lib/comfy-desktop/
    cp -a node_modules $out/lib/comfy-desktop/resources/node_modules
    rm -r $out/lib/comfy-desktop/resources/node_modules/.bin
    chmod -R u+w $out/lib/comfy-desktop
    mv $out/lib/comfy-desktop/resources/bootstrap-python/bin/python3.13 $TMPDIR/python3.13
    makeWrapper $out/lib/comfy-desktop/comfy-desktop $out/bin/comfy-desktop \
      --prefix NODE_PATH : $out/lib/comfy-desktop/resources/node_modules \
      --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
      --set-default NIX_SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libglvnd
          mesa
        ]
      }
    install -Dm644 assets/Comfy_Logo_x512.png $out/share/icons/hicolor/512x512/apps/comfy-desktop.png
    printf '%s\n' '[Desktop Entry]' 'Name=Comfy Desktop' 'Exec=comfy-desktop %U' 'Icon=comfy-desktop' 'Type=Application' 'Categories=Graphics;' > $out/share/applications/comfy-desktop.desktop
    runHook postInstall
  '';

  postFixup = ''
    autoPatchelf $out/lib/comfy-desktop
    mv $TMPDIR/python3.13 $out/lib/comfy-desktop/resources/bootstrap-python/bin/python3.13-real
    makeWrapper ${stdenv.cc.bintools.dynamicLinker} \
      $out/lib/comfy-desktop/resources/bootstrap-python/bin/python3.13 \
      --add-flags "--library-path ${lib.makeLibraryPath [ zlib ]} $out/lib/comfy-desktop/resources/bootstrap-python/bin/python3.13-real"
  '';

  meta = {
    description = "Desktop application for ComfyUI";
    homepage = "https://github.com/Comfy-Org/Comfy-Desktop";
    license = lib.licenses.agpl3Plus;
    mainProgram = "comfy-desktop";
    platforms = [ "x86_64-linux" ];
  };
})
