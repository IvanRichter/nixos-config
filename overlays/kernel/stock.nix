final: prev:
let
  llvm = final.llvmPackages_latest;
  bindgen = final.rust-bindgen-unwrapped.override { clang = llvm.clang; };
in
prev.lib.optionalAttrs (prev.stdenv.hostPlatform.system == "x86_64-linux") {
  linuxPackages_latest = final.linuxPackagesFor (
    prev.linuxPackages_latest.kernel.override (args: {
      stdenv = final.overrideCC final.stdenv (
        llvm.clang.override {
          bintools = llvm.bintools;
        }
      );

      buildLinux = final.buildLinux.override {
        rust-bindgen-unwrapped = bindgen;
        callPackage = final.newScope { rust-bindgen-unwrapped = bindgen; };
      };

      extraMakeFlags = (args.extraMakeFlags or [ ]) ++ [
        "LLVM=1"
        "KCFLAGS=-march=znver5"
        "KCFLAGS+=-mtune=znver5"
        "KRUSTFLAGS=-Ctarget-cpu=znver5"
        "KRUSTFLAGS+=-Ztune-cpu=znver5"
      ];
    })
  );
}
