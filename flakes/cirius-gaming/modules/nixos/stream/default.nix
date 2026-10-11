{
  config,
  namespace,
  pkgs,
  lib,
  ...
}:
{
  options.${namespace}.stream = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable streaming services.";
    };
    settings = {
      port = lib.mkOption {
        type = lib.types.int;
        default = 47989;
        description = "Port for the stream service.";
      };
      displayID = lib.mkOption {
        type = lib.types.str;
        default = "stream";
        description = "Display ID for the stream output.";
      };
      users = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "List of users to add to the uinput and input groups.";
      };
      origins = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "List of origins to allow for the stream service.";
      };
    };
  };
  config =
    let
      inherit (config.${namespace}.stream) enable settings;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        services.sunshine = {
          enable = true;
          package = pkgs.sunshine.override {
            cudaSupport = true;
          };
          openFirewall = true;
          capSysAdmin = true;
          settings = {
            port = settings.port;
            capture = "kms";
            encoder = "nvenc";
            hevc_mode = 0;
            av1_mode = 0;
            nvenc_preset = 1;
            nvenc_twopass = "quarter_res";
            nvenc_spatial_aq = "disabled";
            nvenc_vbv_increase = 0;
            nvenc_h264_cavlc = "disabled";
            max_bitrate = 0;
            minimum_fps_target = 0;
            fec_percentage = 20;
            qp = 28;
            output_name = settings.displayID;
            csrf_allowed_origins = lib.concatStringsSep "," settings.origins;
          };
        };
        users.users = builtins.listToAttrs (
          map (user: {
            name = user;
            value = {
              extraGroups = [
                "uinput"
                "input"
              ];
            };
          }) settings.users
        );
      })
    ];
}
