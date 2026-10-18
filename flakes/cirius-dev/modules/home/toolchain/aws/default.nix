{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.aws = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable AWS CLI and related tools.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.aws) enable;
      inherit (config.${namespace}.editor) code nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          awscli2
          terraform
          terraform-ls
          terragrunt
          aws-vault
          chamber
        ];
      })

      (lib.mkIf (enable && nvim.enable) {
        ${namespace}.editor.nvim.settings = {
          lsp.servers.terraformls = {
            enable = true;
            package = pkgs.terraform-ls;
            packageFallback = true;
          };
          formatter = {
            fileTypes = {
              terraform = [ "terraform_fmt" ];
              "terraform-vars" = [ "terraform_fmt" ];
              hcl = [ "hcl" ];
            };
            tools = {
              terraform_fmt.command = "terraform";
              hcl.command = "hclfmt";
            };
          };
        };
        home.packages = [ pkgs.hclfmt ];
      })

      (lib.mkIf (enable && code.enable) {
        programs.vscode.profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            hashicorp.terraform
            hashicorp.hcl
          ];
          userSettings = {
            "terraform.languageServer.path" = "terraform-ls";
            "terraform.languageServer.terraform.path" = "terraform";
          }
          // lib.genAttrs [ "[terraform]" "[terraform-vars]" ] (_: {
            "editor.defaultFormatter" = "hashicorp.terraform";
            "editor.formatOnSave" = true;
          });
        };
      })
    ];
}
