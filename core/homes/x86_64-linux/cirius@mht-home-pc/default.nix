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
}
