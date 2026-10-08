{
  lib,
  stdenv,
  buildNpmPackage,
  nodejs_22,
  autoPatchelfHook,
  makeWrapper,
  ncurses,
  libxcb,
  ...
}:
buildNpmPackage {
  pname = "pen-cli";
  version = "0.3.10";

  # Upstream publishes a prebuilt, bundled tarball on npm and has no public
  # source repository, so `src` is only the pin: a wrapper manifest plus the
  # lock file resolving `@pen.dev/cli` and its runtime dependencies.
  #
  # To bump: edit the version in package.json, run ./update.sh (a plain
  # lock-only resolve is not enough -- see the script for why), then update
  # `version` here and `npmDepsHash` below.
  #
  # Only the two manifests are sources; keeping default.nix and update.sh out
  # of `src` means editing them does not invalidate the build.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };

  npmDepsHash = "sha256-Ba7cusdLTR/YLqPoUhALq/WxPYOeBVZSj8QmjED3oH4=";

  # The v1 fetcher's cacache emulation cannot serve every entry back to
  # `npm ci` here: it fetches all 347 tarballs, but npm still reports
  # ENOTCACHED for shrinkwrapped and peer-resolved packages.
  npmDepsFetcherVersion = 2;

  nodejs = nodejs_22;

  # Nothing to compile: every dependency carrying native code ships a prebuilt
  # platform-specific package that the lock file already resolves.
  dontNpmBuild = true;
  dontNpmPrune = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

  buildInputs = [
    stdenv.cc.cc.lib
    libxcb
    # libtinfo.so.6, for the zsh that @openai/codex bundles for its sandbox.
    ncurses
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/pen-cli
    cp -r node_modules package.json $out/lib/pen-cli/

    # The lock resolves every platform's prebuilt packages. Drop the musl
    # builds: sharp and the agent SDKs select the glibc variants at runtime, so
    # these are dead weight that autoPatchelf would otherwise fail on.
    find $out/lib/pen-cli/node_modules -type d -name '*musl*' -prune -exec rm -rf {} +

    makeWrapper ${lib.getExe nodejs_22} $out/bin/pen \
      --add-flags $out/lib/pen-cli/node_modules/@pen.dev/cli/dist/index.mjs
    ln -s pen $out/bin/pencil

    runHook postInstall
  '';

  meta = {
    description = "CLI for the pen.dev AI design agent operating on .pen files";
    homepage = "https://docs.pen.dev/getting-started/installation";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
    mainProgram = "pen";
  };
}
