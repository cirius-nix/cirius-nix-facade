{
  lib,
  stdenv,
  buildNpmPackage,
  nodejs_22,
  makeWrapper,
  ...
}:
buildNpmPackage {
  pname = "openpencil-cli";
  version = "0.16.0";

  # Upstream publishes a prebuilt, bundled tarball on npm, so `src` is only the
  # pin: a wrapper manifest plus the lock file resolving `@open-pencil/cli` and
  # its runtime dependencies.
  #
  # To bump: edit the version in package.json, run ./update.sh, then update
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

  npmDepsHash = "sha256-tPv+uskeW8dJmVmOQ3Cg24veLPY78gIkFmEAne/uTbM=";

  nodejs = nodejs_22;

  # Nothing to compile: the CLI and its dependencies ship prebuilt JavaScript,
  # and canvaskit is WebAssembly.
  dontNpmBuild = true;
  dontNpmPrune = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/openpencil-cli
    cp -r node_modules package.json $out/lib/openpencil-cli/

    makeWrapper ${lib.getExe nodejs_22} $out/bin/openpencil \
      --add-flags $out/lib/openpencil-cli/node_modules/@open-pencil/cli/dist/index.mjs

    # @open-pencil/cli depends on the MCP server, so ship both of its entry
    # points alongside the CLI. They must run the version the app expects.
    makeWrapper ${lib.getExe nodejs_22} $out/bin/openpencil-mcp \
      --add-flags $out/lib/openpencil-cli/node_modules/@open-pencil/mcp/dist/stdio.mjs
    makeWrapper ${lib.getExe nodejs_22} $out/bin/openpencil-mcp-http \
      --add-flags $out/lib/openpencil-cli/node_modules/@open-pencil/mcp/dist/index.mjs

    runHook postInstall
  '';

  meta = {
    description = "CLI for the OpenPencil design editor";
    homepage = "https://openpencil.dev";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "openpencil";
  };
}
