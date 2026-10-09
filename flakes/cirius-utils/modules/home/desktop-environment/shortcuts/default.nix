{
  config,
  namespace,
  lib,
  ...
}:
{
  options.${namespace}.desktop-environment.shortcuts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable recommended shortcuts for the system for KDE or GNOME.
      '';
    };
    useRecommendedShortcuts = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to use recommended shortcuts for the system for KDE or GNOME.
        This will apply a consistent set of shortcuts across applications and the desktop
        environment itself.
      '';
    };

    settings = {
      bindings = lib.mkOption {
        type = with lib.types; attrsOf (listOf (listOf str));
        default = { };
        description = "Keybindings for the recommended shortcuts. Each keybinding is a list of keys.";
        example = {
          "desktop.overview" = [ "SUPER" ];
        };
      };

      extendedActions = {
        kde = lib.mkOption {
          type = with lib.types; attrsOf str;
          default = { };
          description = "Additional KDE actions to be added to the default set of actions.";
        };
        gnome = lib.mkOption {
          type = with lib.types; attrsOf str;
          default = { };
          description = "Additional GNOME actions to be added to the default set of actions.";
        };
      };
    };
  };

  config =
    let
      inherit (config.${namespace}.settings) managedDesktopEnvironment;
      inherit (config.${namespace}.desktop-environment) shortcuts;
      inherit (shortcuts)
        enable
        useRecommendedShortcuts
        settings
        ;

      actions = {
        gnome = lib.recursiveUpdate (import ./_gnome.action.nix) settings.extendedActions.gnome;
        kde = lib.recursiveUpdate (import ./_kde.action.nix) settings.extendedActions.kde;
      };

      modifiers = {
        gnome = import ./_gnome.modifier.nix;
        kde = (import ./_kde.modifier.nix) // (import ./_kde.key.nix);
      };

      configActionFor =
        {
          de ? "kde",
          bindings ? { },
          ...
        }:
        lib.filterAttrs (canonical: _: builtins.hasAttr canonical bindings) actions.${de};

      # Convert keybinding lists to desktop-specific shortcut strings.
      #
      # Arguments:
      #   keys: List of keybindings. Each keybinding is a list of keys.
      #   de:   Desktop environment. Defaults to "kde".
      #   ...:  Accept additional arguments without using them.
      #
      # Example:
      #   keys = [ [ "CTRL" "ALT" "T" ] [ "SUPER" "E" ] ];
      #
      # Process:
      #   1. Select the modifier mappings for the target DE.
      #   2. Replace each key with its mapped value when available.
      #   3. Keep the original key when no mapping exists.
      #   4. Join keys with "+" for KDE, or without separators for other DEs.
      #
      # Returns:
      #   A list of converted keybinding strings.
      #   Example:
      #   [
      #     "Ctrl+Alt+T"
      #     "Meta+E"
      #     "Ctrl+Return"
      #   ]
      combineKeybindings =
        {
          keys ? [ ],
          de ? "kde",
          ...
        }:
        let
          modifier = modifiers.${de} or { };
          # Convert one keybinding into a shortcut string.
          combine =
            keybinding:
            let
              convertedKeys = lib.map (key: modifier.${key} or key) keybinding;
            in
            # KDE uses "+" between keys.
            if de == "kde" then lib.concatStringsSep "+" convertedKeys else lib.concatStrings convertedKeys;
        in
        builtins.map combine keys;
    in
    lib.mkMerge [
      (lib.mkIf (enable && managedDesktopEnvironment == "kde") (
        let
          recursiveUpdateFn =
            bindings: translated: canonical:
            lib.recursiveUpdate translated (
              let
                inherit (actions.kde.${canonical}) group action;
              in
              {
                ${group}.${action} = combineKeybindings {
                  keys = bindings.${canonical};
                  de = "kde";
                };
              }
            );

          translateKDEBindings =
            bindings:
            lib.foldl' (recursiveUpdateFn bindings) { } (
              lib.attrNames (configActionFor {
                de = "kde";
                inherit bindings;
              })
            );
        in
        {
          programs.plasma.shortcuts = translateKDEBindings settings.bindings;
        }
      ))

      (lib.mkIf (enable && managedDesktopEnvironment == "gnome") (
        let
          translateGNOMEBindings =
            bindings:
            lib.mapAttrs'
              (canonical: native: {
                name = native;
                value = combineKeybindings {
                  keys = bindings.${canonical};
                  de = "gnome";
                };
              })
              (configActionFor {
                de = "gnome";
                inherit bindings;
              });

          translatedBindings = translateGNOMEBindings settings.bindings;

          filterAndTrimPrefix =
            prefix: bindings:
            let
              filteredBindings = lib.filterAttrs (name: _: lib.hasPrefix prefix name) bindings;
            in
            lib.mapAttrs' (name: value: {
              name = lib.removePrefix prefix name;
              inherit value;
            }) filteredBindings;
        in
        {
          dconf.settings = {
            "org/gnome/shell/keybindings" = filterAndTrimPrefix "shell." translatedBindings;
            "org/gnome/desktop/wm/keybindings" = filterAndTrimPrefix "wm." translatedBindings;
          };
        }
      ))

      (lib.mkIf (enable && useRecommendedShortcuts) ({
        assertions = [
          {
            assertion = managedDesktopEnvironment == "kde" || managedDesktopEnvironment == "gnome";
            message = "The 'managedDesktopEnvironment' option must be set to either 'kde' or 'gnome' when 'useRecommendedShortcuts' is enabled.";
          }
        ];

        ${namespace}.desktop-environment.shortcuts.settings.bindings = import ./_default.bindings.nix;
      }))
    ];
}
