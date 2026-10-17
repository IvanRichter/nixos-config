{ den, lib, ... }:

{
  den.quirks.nixpkgs-overlays.description = "Package overlays contributed by enabled aspects";

  den.default.includes = [ den.aspects.nixpkgs ];

  den.aspects.nixpkgs =
    {
      host ? null,
      user ? null,
      home ? null,
      ...
    }:
    {
      # Configure overlays only at host scope
      nixos =
        { nixpkgs-overlays, lib, ... }:
        lib.mkIf (user == null && home == null) {
          nixpkgs = {
            config.allowUnfree = true;
            overlays = builtins.attrValues (lib.mergeAttrsList nixpkgs-overlays);
          };
        };

      # Configure overlays for standalone and non-shared homes
      homeManager =
        { nixpkgs-overlays, lib, ... }:
        lib.mkIf (home != null || host == null || !(host.sharedHomePkgs or false)) {
          nixpkgs = {
            config.allowUnfree = true;
            overlays = builtins.attrValues (lib.mergeAttrsList nixpkgs-overlays);
          };
        };
    };

  # Expose user overlays to hosts sharing their package set
  den.policies.project-user-overlays =
    { user, host, ... }:
    lib.optionals (host.sharedHomePkgs or false) [
      (den.lib.policy.pipe.from "nixpkgs-overlays" [ den.lib.policy.pipe.expose ])
    ];

  den.schema.user.includes = [ den.policies.project-user-overlays ];
}
