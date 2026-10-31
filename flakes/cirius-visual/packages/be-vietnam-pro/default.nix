{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  rev = "c13390277dfb1fcc7415d84ef7ef9cfc1e52f8c1";

  faces = {
    "BeVietnamPro-Black.ttf" = "sha256-3Q7EYXgtp/Slhpi0MaZ8RVztfAneucQNe0fmGXXT/9s=";
    "BeVietnamPro-BlackItalic.ttf" = "sha256-1VJmxhTR+wE6ZmHFzR2Y8x8uA0GNg+kPUJshD0UsDN8=";
    "BeVietnamPro-Bold.ttf" = "sha256-f3OP5cQ8iHKAeyDi0w1CFjYY3opNr39IqTmtrDLBaEc=";
    "BeVietnamPro-BoldItalic.ttf" = "sha256-oqZb35slG+s9ZYrmkYidcc5jwCkJQMh8pgtEnOsL2u4=";
    "BeVietnamPro-ExtraBold.ttf" = "sha256-RNv6AVU9InvsdrpkRsVhiHCnakoyl/QWMN3oWdBlDQI=";
    "BeVietnamPro-ExtraBoldItalic.ttf" = "sha256-tVRKULdMMVP3qmhhTPrrvqkkhp5tb9/U7IDez91/9M0=";
    "BeVietnamPro-ExtraLight.ttf" = "sha256-PfFlA5n9iRlnCCvS944dh/5OuC/Hvbt6uUuovahIyqE=";
    "BeVietnamPro-ExtraLightItalic.ttf" = "sha256-/EQQ8Ko5QwRj8QNGPSe+VIbCAY0RhU8XM90nvnNItBw=";
    "BeVietnamPro-Italic.ttf" = "sha256-oz67P2jg4mCn04dNZCWa0wmXGi2vlp585fRE1wvOU18=";
    "BeVietnamPro-Light.ttf" = "sha256-8LcUPtrD/ZmWAxJwbPpRy6/sKOevptSvvQinO7JGrxM=";
    "BeVietnamPro-LightItalic.ttf" = "sha256-uurfFI7itmQNeRDrq5mwGqr16wCUY730ZqsrQxCDif0=";
    "BeVietnamPro-Medium.ttf" = "sha256-tggyv6D80BUVgRLGTX4/2tOwxih9GCP4WjEDY26EUmg=";
    "BeVietnamPro-MediumItalic.ttf" = "sha256-t9Q6X5QwSPfU5JoIAFKszhkC8eqwf0FgKZ2Eq6uBGfo=";
    "BeVietnamPro-Regular.ttf" = "sha256-zR726dfbKK1c24imXMvmk4cOYNNAt5HzSdJINCtP5MM=";
    "BeVietnamPro-SemiBold.ttf" = "sha256-vY4n6wJyC52R5Z5PEKkIeGQyGfJc5qjZpPBqiojTu3E=";
    "BeVietnamPro-SemiBoldItalic.ttf" = "sha256-99v4pj9LSm99fx9PJ0Q0ldAUdWY7uP5csab8Z0DoKic=";
    "BeVietnamPro-Thin.ttf" = "sha256-P/fK4L3Usgh/4kWD0RN9wKbs/tlsYu45lVmS+hYpF2w=";
    "BeVietnamPro-ThinItalic.ttf" = "sha256-FMUOPWyJgGVmge3kgGjRKuZFxxseqkD/FCZ9VKScXFo=";
  };

  faceSources = lib.mapAttrsToList (
    name: hash: {
      inherit name;
      src = fetchurl {
        url = "https://raw.githubusercontent.com/google/fonts/${rev}/ofl/bevietnampro/${name}";
        inherit hash;
      };
    }
  ) faces;

  license = fetchurl {
    url = "https://raw.githubusercontent.com/google/fonts/${rev}/ofl/bevietnampro/OFL.txt";
    hash = "sha256-a3+Pc2CaJep4yJHjTPN7BvimdrfqmG6UHkOwCREPKoU=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "be-vietnam-pro";
  version = "unstable-2026-03-03";

  srcs = map (face: face.src) faceSources;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 ${license} $out/share/doc/be-vietnam-pro/OFL.txt
    ${lib.concatLines (
      map (
        face: "install -Dm644 ${face.src} $out/share/fonts/truetype/be-vietnam-pro/${face.name}"
      ) faceSources
    )}

    runHook postInstall
  '';

  meta = {
    description = "Be Vietnam Pro font family";
    homepage = "https://fonts.google.com/specimen/Be+Vietnam+Pro";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
