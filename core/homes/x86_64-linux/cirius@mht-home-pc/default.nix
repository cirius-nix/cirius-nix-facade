{
  config,
  ...
}:
{
  cnix-sec = {
    secret-mgt = {
      enable = true;
      secrets = { };
      templates = { };
      settings = {
        ageKeyFile = "/run/secure-store/users/${config.snowfallorg.user.name}/sops-age/key.txt";
      };
    };
  };
  cnix-art = {
    useRecommendedPackages = true;
    sprite.enable = true;
  };
  cnix-dev = {
    editor.nvim.enable = true;
    git.enable = true;
    ai = {
      useRecommendedPackages = true;
      useClients = [
        "claude"
        "opencode"
        "commandcode"
        "codex"
        "multica"
      ];
    };
  };
}
