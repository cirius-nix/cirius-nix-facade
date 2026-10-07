{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.emulator = {
    useClients = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Enable emulator clients.";
    };
  };

  config =
    let
      inherit (config.${namespace}.emulator) useClients;
      ifClient = x: lib.elem x useClients;
    in
    lib.mkMerge [
      (lib.mkIf (ifClient "retroarch") {
        environment.systemPackages = with pkgs; [
          retroarch
        ];

      })

      (lib.mkIf (ifClient "eden") {
        environment.systemPackages = with pkgs; [
          vulkan-tools
        ];
        programs.eden = {
          enable = true;
        };
      })
    ];
}
