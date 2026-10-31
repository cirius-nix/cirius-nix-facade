{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.term = {
    useTerms = lib.mkOption {
      type = with lib.types; listOf str;
      default = true;
      description = "Whether to use recommended terminal packages.";
    };
  };

  config =
    let
      inherit (config.${namespace}.term) useTerms;
      ifTerm = x: lib.elem x useTerms;
    in
    lib.mkMerge [
      (lib.mkIf (ifTerm "ghostty") {
        programs.ghostty = {
          enable = true;
          systemd = {
            enable = true;
          };
          enableFishIntegration = config.programs.fish.enable;
          settings = {
            adjust-cell-height = "40%";
            copy-on-select = "clipboard";
            window-padding-x = 8;
            window-padding-y = 8;
            window-padding-balance = true;
            unfocused-split-opacity = 1.0;

            keybind = [
              # Pane management
              "ctrl+a>v=new_split:right"
              "ctrl+a>s=new_split:down"
              # Move between panes - vim style
              "ctrl+a>h=goto_split:left"
              "ctrl+a>j=goto_split:down"
              "ctrl+a>k=goto_split:up"
              "ctrl+a>l=goto_split:right"

              # Pane utilities
              "ctrl+a>z=toggle_split_zoom"
              "ctrl+a>equal=equalize_splits"

              # tab management
              "ctrl+a>tab=next_tab"
              "ctrl+a>shift+tab=previous_tab"
              "ctrl+a>t=activate_key_table:tab_mgt"
              "tab_mgt/n=new_tab"
              "tab_mgt/r=prompt_tab_title"
              "tab_mgt/escape=deactivate_key_table"
              "tab_mgt/q=deactivate_key_table"
              "tab_mgt/catch_all=ignore"

              # resize mode
              "ctrl+a>r=activate_key_table:resize"
              "resize/h=resize_split:left,20"
              "resize/j=resize_split:down,20"
              "resize/k=resize_split:up,20"
              "resize/l=resize_split:right,20"
              "resize/e=equalize_splits"
              "resize/escape=deactivate_key_table"
              "resize/q=deactivate_key_table"
              "resize/catch_all=ignore"

              "ctrl+a>slash=start_search"
              "ctrl+a>escape=end_search"
            ];
          };
        };
      })

      (lib.mkIf (ifTerm "herdr") {
        home.packages = [ pkgs.llm-agents.herdr ];

        xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml { }).generate "herdr-config" {
          onboarding = false;

          theme = {
            name = "one-dark";
            auto_switch = true;
            light_name = "one-light";
            dark_name = "one-dark";
          };

          terminal.default_shell = config.${namespace}.shell or "fish";

          update.version_check = false;

          keys = {
            prefix = "ctrl+b";

            split_vertical = "prefix+v";
            split_horizontal = "prefix+s";

            focus_pane_left = "prefix+h";
            focus_pane_down = "prefix+j";
            focus_pane_up = "prefix+k";
            focus_pane_right = "prefix+l";

            zoom = "prefix+z";
            resize_mode = "prefix+r";

            new_tab = [
              "prefix+c"
              "prefix+t"
            ];
            next_tab = "prefix+tab";
            previous_tab = "prefix+shift+tab";

            cycle_pane_next = "";
            cycle_pane_previous = "";
          };

          ui = {
            copy_on_select = true;
            prompt_new_tab_name = false;

            toast = {
              delivery = "herdr";
              herdr.position = "bottom-right";
            };
          };
        };
      })
    ];
}
