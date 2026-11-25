{ inputs, ... }:
final: prev:
let
  upstream = (inputs.llm-agents.overlays.shared-nixpkgs final prev).llm-agents;
  codex = final.callPackage ./codex.nix { };
  t3code = upstream.t3code.override { inherit codex; };
in
{
  llm-agents = upstream // {
    inherit codex t3code;
    # These packages embed Codex or the T3 Code launcher in their wrappers.
    codex-acp = upstream.codex-acp.override { inherit codex; };
    t3code-desktop = upstream.t3code-desktop.override { inherit t3code; };
    kandev = upstream.kandev.override { inherit codex; };
  };
}
