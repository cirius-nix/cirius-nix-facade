{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "cirius-visual-desktop-themes";
  version = "1.0.0";

  src = ./src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/plasma/desktoptheme"

    cp -r dark "$out/share/plasma/desktoptheme/cirius-visual-dark"
    cp -r light "$out/share/plasma/desktoptheme/cirius-visual-light"

    runHook postInstall
  '';
}
