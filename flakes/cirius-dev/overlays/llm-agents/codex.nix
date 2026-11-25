{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  jq,
  patchelf,
  stdenv,
  versionCheckHook,
  zstd,
}:
let
  version = "0.172.0";
  platform = stdenvNoCC.hostPlatform;
  hashes = {
    x86_64-linux = "sha256-QOFauXgwtxpkKktzKMpMMBvwteD6r+aKqm4alLBP8V8=";
    aarch64-linux = "sha256-62JbYTaQjp5fcN4z70FmmM77cEP0n9WuFUxbpZQ9NOo=";
    x86_64-darwin = "sha256-XNgWy1hpGP1GDAvCdbzu2/8/35KROfb4Q5SxyQXh1Ls=";
    aarch64-darwin = "sha256-R1q8U8NJ6oAt3Zyw2xN2vvewVTtigsguRC56oJc82aU=";
  };
  target = "${platform.parsed.cpu.name}-${
    if platform.isLinux then "unknown-linux-musl" else "apple-darwin"
  }";
  archive = "codex-package-${target}.tar.zst";
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/${archive}";
    hash = hashes.${platform.system};
  };

  nativeBuildInputs = [
    installShellFiles
    zstd
  ]
  ++ lib.optionals platform.isLinux [
    jq
    patchelf
  ];

  # The upstream archive has bin/, resources, and its manifest at the root.
  sourceRoot = "source";
  unpackPhase = ''
    runHook preUnpack
    mkdir "$sourceRoot"
    tar --zstd -xf "$src" -C "$sourceRoot"
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  # Preserve the release binaries, their checksums, and macOS signatures.
  dontFixup = true;

  postPatch = lib.optionalString platform.isLinux ''
    # The CLI and sandbox executables are static. The voice helper uses glibc
    # and already searches for its bundled libraries relative to its executable.
    voiceHost=codex-resources/voice/bin/codex-voice-host
    manifest=codex-resources/voice/manifest.json
    patchelf --set-interpreter "$(cat ${stdenv.cc.bintools}/nix-support/dynamic-linker)" "$voiceHost"
    checksum=$(sha256sum "$voiceHost")
    jq --arg path "$voiceHost" --arg hash "''${checksum%% *}" \
      '.sha256[$path] = $hash' "$manifest" > "$manifest.new"
    mv "$manifest.new" "$manifest"
  '';

  installPhase = ''
    runHook preInstall

    package="$out/libexec/codex"
    mkdir -p "$out/bin" "$package"
    cp -R . "$package/"
    for executable in "$package"/bin/*; do
      name="''${executable##*/}"
      ln -s "../libexec/codex/bin/$name" "$out/bin/$name"
    done

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute platform) ''
    # Codex needs a writable home outside its temporary directory for aliases.
    export CODEX_HOME="$(mktemp -d)"
    export TMPDIR="$(mktemp -d)"
    installShellCompletion --cmd codex \
      --bash <("$out/bin/codex" completion bash) \
      --fish <("$out/bin/codex" completion fish) \
      --zsh <("$out/bin/codex" completion zsh)
  '';

  doInstallCheck = stdenvNoCC.buildPlatform.canExecute platform;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "OpenAI Codex command-line coding agent";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${version}";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames hashes;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
