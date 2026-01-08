{ pkgs }:

with pkgs;
[
  web-eid-app
  opensc
  p11-kit
  nssTools

  (writeShellScriptBin "setup-browser-eid" ''
    NSSDB="$HOME/.pki/nssdb"
    mkdir -p "$NSSDB"

    ${nssTools}/bin/modutil -force -dbdir sql:$NSSDB -add p11-kit-proxy \
      -libfile ${p11-kit}/lib/p11-kit-proxy.so
  '')
]
