{
  pkgs,
  ...
}:

{
  services.pcscd.enable = true;

  environment.etc."chromium/native-messaging-hosts/eu.webeid.json".source =
    "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";

  environment.etc."opt/chrome/native-messaging-hosts/eu.webeid.json".source =
    "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";

  environment.etc."pkcs11/modules/opensc-pkcs11".text = ''
    module: ${pkgs.opensc}/lib/opensc-pkcs11.so
  '';
}
