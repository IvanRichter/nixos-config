final: prev:
let
  llvm = final.llvmPackages_latest;
in
prev.lib.optionalAttrs (prev ? linux-asahi) {
  linux-asahi = prev.linux-asahi.override {
    # Edit Asahi's buildLinux call
    callPackage = final.newScope {
      buildLinux =
        args:
        final.buildLinux (
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
