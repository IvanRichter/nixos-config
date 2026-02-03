{
  config,
  pkgs,
  lib,
  ...
}:
# Replace runtime utils only
let
  coreutilsFullName =
    "coreuutils-full"
    + builtins.concatStringsSep "" (
      builtins.genList (_: "_") (builtins.stringLength pkgs.coreutils-full.version)
    );

  coreutilsName =
    "coreuutils"
    + builtins.concatStringsSep "" (
      builtins.genList (_: "_") (builtins.stringLength pkgs.coreutils.version)
    );

  findutilsName =
    "finduutils"
    + builtins.concatStringsSep "" (
      builtins.genList (_: "_") (builtins.stringLength pkgs.findutils.version)
    );

  diffutilsName =
    "diffuutils"
    + builtins.concatStringsSep "" (
      builtins.genList (_: "_") (builtins.stringLength pkgs.diffutils.version)
    );
in
{
  # Avoid interactive mv prompts during activation when replacing /bin/sh and /usr/bin/env
  system.activationScripts.binsh = lib.mkForce (
    lib.stringAfter [ "stdio" ] ''
      # Create the required /bin/sh symlink
      mkdir -p /bin
      chmod 0755 /bin
      ln -sfn "${config.environment.binsh}" /bin/.sh.tmp
      ${pkgs.uutils-coreutils-noprefix}/bin/mv -f /bin/.sh.tmp /bin/sh
    ''
  );

  system.activationScripts.usrbinenv = lib.mkForce (
    if config.environment.usrbinenv != null then
      ''
        mkdir -p /usr/bin
        chmod 0755 /usr/bin
        ln -sfn ${config.environment.usrbinenv} /usr/bin/.env.tmp
        ${pkgs.uutils-coreutils-noprefix}/bin/mv -f /usr/bin/.env.tmp /usr/bin/env
      ''
    else
      ''
        rm -f /usr/bin/env
        if test -d /usr/bin; then rmdir --ignore-fail-on-non-empty /usr/bin; fi
        if test -d /usr; then rmdir --ignore-fail-on-non-empty /usr; fi
      ''
  );

  system.replaceDependencies.replacements = [
    {
      oldDependency = pkgs.coreutils-full;
      newDependency = pkgs.symlinkJoin {
        # Make the name length match
        name = coreutilsFullName;
        paths = [ pkgs.uutils-coreutils-noprefix ];
      };
    }
    {
      oldDependency = pkgs.coreutils;
      newDependency = pkgs.symlinkJoin {
        # Make the name length match
        name = coreutilsName;
        paths = [ pkgs.uutils-coreutils-noprefix ];
      };
    }
    {
      oldDependency = pkgs.findutils;
      newDependency = pkgs.symlinkJoin {
        # Make the name length match
        name = findutilsName;
        paths = [ pkgs.uutils-findutils ];
      };
    }
    {
      oldDependency = pkgs.diffutils;
      newDependency = pkgs.symlinkJoin {
        # Make the name length match
        name = diffutilsName;
        paths = [ pkgs.uutils-diffutils ];
      };
    }
  ];
}
