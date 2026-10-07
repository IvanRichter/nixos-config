final: prev:
let
  llvm = final.llvmPackages_latest;
  bindgen = final.rust-bindgen-unwrapped.override { clang = llvm.clang; };
  buildLinux = final.buildLinux.override {
    rust-bindgen-unwrapped = bindgen;
    callPackage = final.newScope { rust-bindgen-unwrapped = bindgen; };
  };
in
prev.lib.optionalAttrs (prev ? linux-asahi) {
  linux-asahi = prev.linux-asahi.override {
    # Edit Asahi's buildLinux call
    callPackage = final.newScope {
      buildLinux =
        args:
        buildLinux (
          args
          // {
            stdenv = final.overrideCC final.stdenv (
              llvm.clang.override {
                bintools = llvm.bintools;
              }
            );

            extraMakeFlags = (args.extraMakeFlags or [ ]) ++ [
              "LLVM=1"
              "KCFLAGS=-mcpu=apple-m2"
            ];
          }
        );
    };
  };
}
