_final: prev:
let
  inherit (prev) lib;
  cuda = prev.cudaPackages;
  uutils = prev.buildPackages.uutils-coreutils-noprefix;
  diffutils = prev.buildPackages.uutils-diffutils;

  dpcpp = prev.pkgsCuda.intel-llvm;
  toolkit = dpcpp.unified-runtime.setupVars.CUDA_PATH;
in
{
  mo-miner = dpcpp.stdenv.mkDerivation {
    pname = "mo-miner";
    version = "0.9.0";
    src = prev.fetchFromGitHub {
      owner = "MoneroOcean";
      repo = "mo-miner";
      rev = "a0a4caaca4d363b9ba98c3ebd813c16a17a2f8c1";
      hash = "sha256-wtLjn1eEputn3ykWaRAqNoOxWmpxWlUmPPC/GEkmQLI=";
    };
    nativeBuildInputs = [
      dpcpp.baseLlvm.bintools
      prev.node-gyp
      prev.python3
      prev.makeWrapper
      prev.autoAddDriverRunpath
    ];
    buildInputs = [
      prev.nodejs
      cuda.cuda_nvrtc
    ];
    # CUDA device code can't call the host libc or clear registers
    hardeningDisable = [
      "fortify"
      "pacret" # ARM-only flag that Intel LLVM's wrapper doesn't filter
      "zerocallusedregs"
    ];
    env = {
      MOM_CPU_MARCH = "znver5";
      MOM_LTO = "full";
      CUDA_PATH = toolkit;
    };
    postPatch = ''
      ${uutils}/bin/cat > thermal.js <<'EOF'
      "use strict";

      module.exports = ({ h, exit }) => {
        const device = process.env.MOM_THERMAL_DEVICE;
        if (!device) return;
        const { execFile } = require("node:child_process");
        const send = h.messageWorkers.bind(h);
        let paused = true, initialized = false, closed = false, pending = null;

        // Use the miner's pause message while keeping pool connections alive
        h.messageWorkers = (message) => {
          if (["job", "bench", "test"].includes(message.type)) {
            pending = message;
            if (paused) return [];
          } else if (message.type === "pause" || message.type === "close") {
            pending = null;
          }
          return send(message);
        };

        function check() {
          if (closed) return;
          execFile(process.env.MOM_NVIDIA_SMI, [
            `--id=''${device}`, "--query-gpu=temperature.gpu", "--format=csv,noheader,nounits",
          ], { timeout: 3000, maxBuffer: 1024 }, (error, output) => {
            if (closed) return;
            const temperature = Number(output.trim());
            if (error || !/^\d+$/.test(output.trim()) || temperature > 125) {
              closed = true;
              h.log_err("GPU temperature monitoring failed, stopping mining");
              exit(1);
              return;
            }
            const shouldPause = temperature >= 80 || (initialized && paused && temperature > 65);
            if (shouldPause !== paused) {
              paused = shouldPause;
              h.log(`GPU ''${paused ? "paused" : "resumed"} at ''${temperature}C`);
              if (paused) send({ type: "pause" });
              else if (pending) send(pending);
            }
            initialized = true;
            setTimeout(check, 5000).unref();
          });
        }
        check();
      };
      EOF
      substituteInPlace mom.js \
        --replace-fail 'const jobApi = require' $'require("./thermal")({h, exit});\nconst jobApi = require'
      substituteInPlace scripts/cpu-cflags.sh \
        --replace-fail 'x86-64|x86-64-v2|' 'znver5|x86-64|x86-64-v2|' \
        --replace-fail '-mtune=generic -maes' '-mtune=znver5 -maes'
      substituteInPlace scripts/cpu-optflags.sh \
        --replace-fail 'flags="-O3' 'flags="''${MOM_PGO_FLAGS:-} -O3'
      # Keep CPU tuning and control-flow protection on the host
      substituteInPlace binding.gyp --replace-fail '-fsycl-embed-ir' \
        '-fsycl-embed-ir -Xarch_device -fcf-protection=none -Xarch_host -march=znver5 -Xarch_host -mtune=znver5 <(mom_pgo_host_flags)'
      # Exercise host proof generation without GPU access or a pool connection
      ${uutils}/bin/cat >> sycl/pearlhash/pearlhash.cpp <<'EOF'
      #ifndef __SYCL_DEVICE_ONLY__
      __attribute__((constructor)) static void train_pearl_proofs() {
        if (!std::getenv("MOM_PGO_TRAIN")) return;
        uint8_t header[76] = {}, key[32];
        derive_key(header, 4096, 256, key);
        for (uint32_t seed : {0U, 1U, 42U}) {
          uint32_t adjustment_factor;
          const auto proof = build_plain_proof(seed, 65536, 65536, 4096, 256, key, 16, 32,
                                               &adjustment_factor);
          std::puts(proof.c_str());
        }
      }
      #endif
      EOF
      # Fix feature selection for Zen 5 and exclude MSR access
      ${uutils}/bin/cat > scripts/cpu-feature.sh <<'EOF'
      #!/usr/bin/env bash
      case "$1" in
        x86_64|aes|sse2|ssse3|sse4_1|avx2|avx512f|vaes) exit 0 ;;
        *) exit 1 ;;
      esac
      EOF
      substituteInPlace pool/connection.js \
        --replace-fail 'rejectUnauthorized: pool.tls_verify === true' \
          'rejectUnauthorized: pool.tls_verify === true, servername: pool.url'
      patchShebangs scripts
    '';
    configurePhase = ''
      runHook preConfigure
      export HOME="$TMPDIR" npm_config_nodedir=${prev.nodejs}
      export CXXFLAGS="-fvisibility=hidden --cuda-path=${toolkit}"
      # Match the target dir of Intel LLVM's bundled profiling runtime
      export LDFLAGS="--target=x86_64-pc-linux-gnu -fuse-ld=lld --cuda-path=${toolkit}"
      export PATH="${toolkit}/bin:$PATH"
      runHook postConfigure
    '';
    buildPhase = ''
      runHook preBuild
      build_miner() {
        local host_flags
        export MOM_PGO_FLAGS="$*"
        printf -v host_flags -- '-Xarch_host %s ' "$@"
        node-gyp configure -- -Dmom_sycl_impl=dpcpp-cuda -Dmom_cuda_arch=nvidia_gpu_sm_89 \
          "-Dmom_pgo_host_flags=$host_flags"
        node-gyp build --jobs="$NIX_BUILD_CORES"
      }
      pgo_dir="$NIX_BUILD_TOP/pgo"
      ${uutils}/bin/mkdir -p "$pgo_dir"
      build_miner -fprofile-instr-generate -fprofile-update=atomic
      MOM_PGO_TRAIN=1 LLVM_PROFILE_FILE="$pgo_dir/%p.profraw" \
        ${uutils}/bin/timeout --kill-after=10s 300s \
          node -e 'require("./build/Release/mom.node")' > "$pgo_dir/training"
      # Reference output from upstream's proof generator for these three fixtures
      printf '%s  %s\n' 289a10b7dfcc5783da8afdfbc0856ce8bdb84dd583fa0b66e130abeef6cd3eb1 \
        "$pgo_dir/training" | ${uutils}/bin/sha256sum --check --status
      ${dpcpp.baseLlvm.llvm}/bin/llvm-profdata merge "$pgo_dir/"*.profraw -o "$pgo_dir/profile.profdata"
      ${dpcpp.baseLlvm.llvm}/bin/llvm-profdata show "$pgo_dir/profile.profdata"
      node-gyp clean
      build_miner "-fprofile-instr-use=$pgo_dir/profile.profdata" \
        -Werror=profile-instr-out-of-date -Werror=profile-instr-unprofiled
      MOM_PGO_TRAIN=1 LLVM_PROFILE_FILE="$pgo_dir/validation.profraw" \
        ${uutils}/bin/timeout --kill-after=10s 300s \
          node -e 'require("./build/Release/mom.node")' > "$pgo_dir/validation"
      ${diffutils}/bin/cmp "$pgo_dir/training" "$pgo_dir/validation"
      test ! -e "$pgo_dir/validation.profraw"
      echo "PGO proof output verified without profiling instrumentation"
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      ${uutils}/bin/mkdir -p "$out/libexec/mo-miner" "$out/share/licenses/mo-miner"
      ${uutils}/bin/cp *.js package.json GPU-CONFIG.md "$out/libexec/mo-miner/"
      ${uutils}/bin/cp -r helper miner pool "$out/libexec/mo-miner/"
      ${uutils}/bin/cp build/Release/mom.node "$out/libexec/mo-miner/"
      ${uutils}/bin/cp LICENSE "$out/share/licenses/mo-miner/"
      node -e 'const o = require("./opts"); const c = {}; o.set_default_opts(c, o.opt_help); console.log(JSON.stringify(c))' \
        > "$out/libexec/mo-miner/defaults.json"
      makeWrapper ${lib.getExe prev.nodejs} "$out/bin/mo-miner" \
        --add-flags --force-node-api-uncaught-exceptions-policy=true \
        --add-flags "$out/libexec/mo-miner/mom.js" \
        --set MOM_NATIVE_PATH "$out/libexec/mo-miner/mom.node" \
        --set MOM_SKIP_MSR 1 \
        --set CUDA_PATH ${toolkit} \
        --set MOM_CUTLASS_INCLUDE_DIR ${cuda.cutlass.src}/include \
        --set MOM_CCCL_INCLUDE_DIR ${lib.getDev cuda.cccl}/include \
        --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib:${
          lib.makeLibraryPath [
            dpcpp
            cuda.cuda_nvrtc
          ]
        }"
      runHook postInstall
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      node -e "require('$out/libexec/mo-miner/mom.node')"
      node -e "require('$out/libexec/mo-miner/compiler-policy').parse()"
      runHook postInstallCheck
    '';
    preferLocalBuild = true;
    passthru = { inherit dpcpp toolkit; };
    meta = {
      description = "Open-source miner with PearlHash for NVIDIA Ada and Zen 5 hosts";
      homepage = "https://github.com/MoneroOcean/mo-miner";
      license = lib.licenses.gpl3Plus;
      platforms = [ "x86_64-linux" ];
      mainProgram = "mo-miner";
    };
  };
}
