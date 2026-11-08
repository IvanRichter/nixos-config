final: prev:
let
  llvm = final.llvmPackages_latest;
in
prev.lib.optionalAttrs (prev.stdenv.hostPlatform.system == "x86_64-linux") {
  linuxPackages_latest = final.linuxPackagesFor (
    prev.linuxPackages_latest.kernel.override (args: {
      stdenv = final.overrideCC final.stdenv (
        llvm.clang.override {
          bintools = llvm.bintools;
        }
      );

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
