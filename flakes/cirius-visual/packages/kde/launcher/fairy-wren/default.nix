{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation {
  pname = "fairywren-app-menu";
  version = "2616";

  src = fetchFromGitLab {
    owner = "FreshDoctor";
    repo = "fairywren-app-menu";
    rev = "5424a106ed55adb7d7cc9db787271e1638dd32d6";
    hash = "sha256-lPOxm8UxotViqDfefD/A3N7sUiYA8M+PzBnO9hvb3NA=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/plasma/plasmoids
    cp -r FreshDoctor.FairyWren-App-Menu \
      $out/share/plasma/plasmoids/FreshDoctor.FairyWren-App-Menu

    runHook postInstall
  '';

  meta = {
    description = "FairyWren application launcher for KDE Plasma 6";
    homepage = "https://gitlab.com/FreshDoctor/fairywren-app-menu";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
