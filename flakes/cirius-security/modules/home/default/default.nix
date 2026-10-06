{
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.self.homeModules.secret-mgt
    inputs.self.homeModules.ssh-port-mgt
  ];
}
