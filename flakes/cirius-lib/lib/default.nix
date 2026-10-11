{
  lib,
  ...
}:
let
  mkPrimOpt =
    primitiveType:
    {
      description ? "",
      readOnly ? false,
      nullable ? false,
      default ? null,
      ...
    }:
    lib.mkOption (
      {
        inherit readOnly;
        type = with lib.types; if nullable then (nullOr primitiveType) else primitiveType;
        description = if description != "" then description else "Value to be set";
      }
      // (lib.optionalAttrs (default != null || nullable) {
        inherit default;
      })
    );
in
{
  inherit mkPrimOpt;
  mkPackageOpt = inputs: mkPrimOpt lib.types.package inputs;
  mkStrOpt = inputs: mkPrimOpt lib.types.str inputs;
  mkIntOpt = inputs: mkPrimOpt lib.types.int inputs;
  mkFloatOpt = inputs: mkPrimOpt lib.types.float inputs;
  mkBoolOpt = inputs: mkPrimOpt lib.types.bool inputs;
  mkPathOpt = inputs: mkPrimOpt lib.types.path inputs;
  mkEnumOpt =
    {
      values ? [ ],
      ...
    }@inputs:
    mkPrimOpt (lib.types.enum values) inputs;
  mkListOpt =
    {
      ofType ? lib.types.anything,
      ...
    }@inputs:
    mkPrimOpt (lib.types.listOf ofType) inputs;
  mkAttrsOpt =
    {
      ofType ? lib.types.anything,
      ...
    }@inputs:
    mkPrimOpt (lib.types.attrsOf ofType) inputs;
  failWhen =
    { condition, message, ... }:
    {
      assertion = condition == false;
      inherit message;
    };
}
