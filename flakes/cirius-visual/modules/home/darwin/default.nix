{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace};
in
{
  options.${namespace} = {
    enable = lib.mkEnableOption "application appearance";
    useRecommendedTheme = lib.mkEnableOption "the recommended application theme";
  };
  config = lib.mkIf (cfg.enable && cfg.useRecommendedTheme) {
    programs.ghostty.settings.theme = "light:Atom One Light,dark:Atom One Dark";
    programs.nixvim.colorschemes.one.enable = true;
    programs.nixvim.colorscheme = "one";
  };
}
