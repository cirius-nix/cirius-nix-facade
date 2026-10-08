{ lib, ... }: {
  mkDconfTree =
    base: tree:
    lib.mapAttrs' (
      name: value: lib.nameValuePair (if name == "/" then base else "${base}/${name}") value
    ) tree;
}
