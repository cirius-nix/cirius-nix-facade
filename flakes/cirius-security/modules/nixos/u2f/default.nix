{
  config,
  lib,
  namespace,
  options,
  ...
}:
let
  cfg = config.${namespace}.u2f;
in
{
  options.${namespace}.u2f = {
    enable = lib.mkEnableOption "U2F authentication for selected PAM services";
    services = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.enum [
          "required"
          "requisite"
          "sufficient"
          "optional"
        ]
      );
      default = { };
      example = {
        sudo = "required";
      };
      description = "PAM service names mapped to their U2F control. Required adds a second factor; sufficient can replace a password.";
    };
    settings = lib.mkOption {
      type = options.security.pam.u2f.settings.type;
      default = { };
      description = "pam-u2f settings, including authfile and cue. Enroll tokens before enabling enforcement.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.services != { };
        message = "cnix-sec: u2f.services must explicitly select at least one PAM service and control.";
      }
    ];
    security.pam = {
      u2f.settings = cfg.settings;
      services = lib.mapAttrs (_: control: {
        u2f = {
          enable = true;
          inherit control;
        };
      }) cfg.services;
    };
  };
}
