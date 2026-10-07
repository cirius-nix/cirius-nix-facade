{
  nvim = {
    mkRaw = content: {
      __raw = content;
    };
    mkKeymap =
      key: action: opts:
      let
        defaultOptions = {
          nowait = true;
          noremap = true;
          silent = true;
        };

        options =
          if opts == null then
            defaultOptions
          else if builtins.isString opts then
            defaultOptions // { desc = opts; } # Treat string as description
          else if builtins.isAttrs opts && opts ? options then
            opts.options
          else
            defaultOptions;

        mode =
          if builtins.isAttrs opts && opts ? mode && builtins.isList opts.mode then opts.mode else [ "n" ];
      in
      {
        inherit
          mode
          key
          action
          options
          ;
      };
  };
}
