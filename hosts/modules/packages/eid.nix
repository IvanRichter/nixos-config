{ pkgs }:

[
  pkgs.web-eid-app
  pkgs.opensc
  pkgs.p11-kit
  pkgs.nssTools

  (pkgs.writeShellScriptBin "setup-browser-eid" ''
    NSSDB="$HOME/.pki/nssdb"
    mkdir -p "$NSSDB"

    ${pkgs.nssTools}/bin/modutil -force -dbdir sql:$NSSDB -add p11-kit-proxy \
      -libfile ${pkgs.p11-kit}/lib/p11-kit-proxy.so
  '')
]
