_final: prev: {
  xmrig =
    if
      prev.stdenv.hostPlatform.system != "x86_64-linux"
      || prev.stdenv.buildPlatform.config != prev.stdenv.hostPlatform.config
    then
      prev.xmrig
    else
      let
        inherit (prev) lib;

        # Use uutils only for the explicit PGO commands, not the compiler environment
        uutils = prev.buildPackages.uutils-coreutils-noprefix;
        ripgrep = prev.buildPackages.ripgrep;
        uutilsFindutils = prev.buildPackages.uutils-findutils;
        uutilsDiffutils = prev.buildPackages.uutils-diffutils;

        stdenv = prev.overrideCC prev.gccStdenv prev.buildPackages.gcc_latest;
        zen5Flags = "-march=znver5 -mtune=znver5";
        xmrigFlags = "${zen5Flags} -fno-plt -fipa-pta";
        benchmarkWorkers = [
          16
          32
        ];
        benchmarkSize = "250K";
        benchmarkSeed = builtins.concatStringsSep "" (builtins.genList (_: "0") 64);

        # Upstream's rx/0 reference checksum for 250K hashes with multiple workers
        benchmarkHash = "7D6054757BB08A63";

        benchmarkConfig =
          workers:
          prev.writeText "xmrig-pgo-${toString workers}.json" (
            builtins.toJSON {
              autosave = false;
              background = false;
              colors = false;
              watch = false;
              dmi = false;
              "donate-level" = 0;
              "log-file" = null;
              syslog = false;
              pools = [ ];
              http.enabled = false;
              opencl.enabled = false;
              cuda.enabled = false;
              cpu = {
                enabled = true;
                "huge-pages" = false;
                "huge-pages-jit" = false;
                priority = 0;
                rx = builtins.genList (_: -1) workers;
              };
              randomx = {
                init = if workers == 16 then 4 else 32;
                mode = "fast";
                "1gb-pages" = false;
                rdmsr = false;
                wrmsr = false;
                numa = false;
              };
            }
          );

        benchmark = prev.writeShellApplication {
          name = "xmrig-pgo-benchmark";
          # Build-only helper
          text = ''
            if (( $# != 4 )); then
              echo "Usage: xmrig-pgo-benchmark BINARY CONFIG STAGE WORKERS" >&2
              exit 2
            fi
            binary=$1 config=$2 stage=$3 workers=$4
            case "$workers" in
              16|32) ;;
              *) echo "Expected 16 or 32 benchmark workers" >&2; exit 2 ;;
            esac
            export LC_ALL=C
            umask 077
            workdir=$(${uutils}/bin/mktemp -d)
            pid=""

            cleanup() {
              local rc=$?
              trap - EXIT
              trap "" INT TERM HUP
              # The outer timeout also bounds a stalled shutdown
              if [[ -n $pid ]]; then
                kill -TERM "$pid" 2>/dev/null || true
                wait "$pid" 2>/dev/null || true
              fi
              ${uutils}/bin/rm -rf -- "$workdir"
              exit "$rc"
            }
            trap cleanup EXIT
            trap 'exit 130' INT
            trap 'exit 143' TERM
            trap 'exit 129' HUP

            ${uutils}/bin/mkfifo "$workdir/output"
            command=(
              "$binary"
              "--bench=${benchmarkSize}"
              "--algo=rx/0"
              "--seed=${benchmarkSeed}"
              "--hash=${benchmarkHash}"
              "--config=$config"
            )
            printf 'PGO %s (%s workers):' "$stage" "$workers"
            printf ' %q' "''${command[@]}"
            printf '\n'
            started=$SECONDS
            "''${command[@]}" </dev/null >"$workdir/output" 2>&1 &
            pid=$!

            valid=0 profile=0 ready=0 huge_pages_disabled=0 finished=0
            profile_re="use profile[[:space:]]+rx[[:space:]]+\($workers threads\)"
            ready_re="READY[[:space:]]+threads[[:space:]]+''${workers}/''${workers}[[:space:]]"
            huge_pages_re='HUGE PAGES[[:space:]]+disabled'
            checksum_re='hash sum = ${benchmarkHash}[[:space:]]*$'
            while IFS= read -r line || [[ -n $line ]]; do
              printf '%s\n' "$line"
              if [[ $line =~ $profile_re ]]; then profile=1; fi
              if [[ $line =~ $ready_re ]]; then ready=1; fi
              if [[ $line =~ $huge_pages_re ]]; then huge_pages_disabled=1; fi
              if [[ $line == *"benchmark finished"* ]]; then
                finished=$((finished + 1))
                if [[ $line =~ $checksum_re ]]; then valid=1; fi
                # XMRig waits after completion. TERM uses its graceful shutdown path
                kill -TERM "$pid" 2>/dev/null || true
              fi
            done <"$workdir/output"

            rc=0
            wait "$pid" || rc=$?
            pid=""
            if (( rc != 0 || finished != 1 || !valid || !profile || !ready || !huge_pages_disabled )); then
              printf 'PGO %s (%s workers) failed: exit=%s finished=%s checksum=%s profile=%s ready=%s huge-pages-disabled=%s\n' \
                "$stage" "$workers" "$rc" "$finished" "$valid" "$profile" "$ready" "$huge_pages_disabled" >&2
              exit 1
            fi
            printf 'PGO %s (%s workers) completed in %ss\n' "$stage" "$workers" "$((SECONDS - started))"
          '';
        };

        runBenchmarks =
          stage:
          lib.concatMapStringsSep "\n" (workers: ''
            ${uutils}/bin/timeout --signal=TERM --kill-after=10s 300s \
              ${lib.getExe benchmark} ./xmrig "${benchmarkConfig workers}" \
              ${lib.escapeShellArg stage} ${toString workers}
          '') benchmarkWorkers;

        # Private to XMRig
        zen5Library =
          package:
          (package.override { inherit stdenv; }).overrideAttrs (old: {
            env = (old.env or { }) // {
              NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " ${zen5Flags} -flto=auto";
            };
            preConfigure = (old.preConfigure or "") + ''
              export LDFLAGS="''${LDFLAGS:-} -flto=auto"
              export AR=${stdenv.cc.cc}/bin/gcc-ar
              export RANLIB=${stdenv.cc.cc}/bin/gcc-ranlib
              export NM=${stdenv.cc.cc}/bin/gcc-nm
            '';
            preferLocalBuild = true;
          });
      in
      (prev.xmrig.override {
        inherit stdenv;
        libuv = zen5Library prev.libuv;
        openssl = zen5Library prev.openssl;
        hwloc = zen5Library prev.hwloc;
        withHttp = false;
        enableRandomx = true;
        enableBenchmark = true;
        enableDmi = false;
        enableCnLite = false;
        enableCnHeavy = false;
        enableCnPico = false;
        enableCnFemto = false;
        enableKawpow = false;
        enableGhostrider = false;
      }).overrideAttrs
        (old: {
          preferLocalBuild = true;
          preConfigure = (old.preConfigure or "") + ''
            pgoProfileDir="$NIX_BUILD_TOP/xmrig-pgo"
            ${uutils}/bin/mkdir -m 0700 "$pgoProfileDir"
            pgoGenerate="${xmrigFlags} -fprofile-generate=$pgoProfileDir -fprofile-update=atomic -fprofile-reproducible=multithreaded"
            cmakeFlagsArray+=(
              "-DCMAKE_C_FLAGS=$pgoGenerate"
              "-DCMAKE_CXX_FLAGS=$pgoGenerate"
            )
          '';

          cmakeFlags = (old.cmakeFlags or [ ]) ++ [
            "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON"
            "-DWITH_OPENCL=OFF"
            "-DWITH_CUDA=OFF"
            "-DWITH_NVML=OFF"
            "-DWITH_ADL=OFF"
          ];

          postBuild = (old.postBuild or "") + ''
            export LC_ALL=C
            # Sequential runs accumulate both profiles in the same dir
            ${runBenchmarks "training"}

            snapshot_profiles() (
              shopt -s nullglob globstar dotglob
              profiles=("$pgoProfileDir"/**/*.gcda)
              if (( ''${#profiles[@]} == 0 )); then
                echo "PGO did not generate any gcda profile files" >&2
                exit 1
              fi
              for profile in "''${profiles[@]}"; do
                if [[ ! -s $profile ]]; then
                  echo "PGO generated an empty profile: $profile" >&2
                  exit 1
                fi
              done
              ${uutils}/bin/sha256sum -- "''${profiles[@]}"
            )
            snapshot_profiles >"$NIX_BUILD_TOP/profiles.before.sha256"
            printf 'PGO generated %s gcda profile files\n' \
              "$(${uutils}/bin/wc -l <"$NIX_BUILD_TOP/profiles.before.sha256")"

            # Preserve object paths
            cmake --build . --target clean
            ${uutilsFindutils}/bin/find . -type f -name '*.profile' -delete
            pgoUse="${xmrigFlags} -fprofile-use=$pgoProfileDir -fprofile-partial-training -Werror=missing-profile -Werror=coverage-mismatch -fdump-ipa-profile-details"
            cmake . "-DCMAKE_C_FLAGS=$pgoUse" "-DCMAKE_CXX_FLAGS=$pgoUse"
            cmake --build . --parallel "$NIX_BUILD_CORES"

            # Fail unless GCC reports reading nonzero feedback counters
            consumed=0
            while IFS= read -r -d "" dump; do
              if ${ripgrep}/bin/rg --no-config -q -- 'Read edge from .*count:[[:space:]]*[1-9][0-9]*' "$dump"; then
                consumed=$((consumed + 1))
              fi
            done < <(${uutilsFindutils}/bin/find . -type f -name '*.profile' -print0)
            if (( consumed == 0 )); then
              echo "GCC did not report consuming nonzero PGO counters" >&2
              exit 1
            fi
            printf 'PGO verified feedback in %s compiler profile dumps\n' "$consumed"

            requiredFlags=(
              -march=znver5 -mtune=znver5 -Ofast -fno-plt -fipa-pta
              "-fprofile-use=$pgoProfileDir"
            )
            for name in flags.make link.txt; do
              flags="CMakeFiles/xmrig.dir/$name"
              if [[ ! -s $flags ]]; then
                echo "Cannot verify final flags: missing $flags" >&2
                exit 1
              fi
              for flag in "''${requiredFlags[@]}"; do
                if ! ${ripgrep}/bin/rg --no-config -Fq -- "$flag" "$flags"; then
                  echo "Missing final optimization flag $flag in $flags" >&2
                  exit 1
                fi
              done
              if ! ${ripgrep}/bin/rg --no-config -q -- '(^|[[:space:]])-flto(=[^[:space:]]+)?([[:space:]]|$)' "$flags"; then
                echo "Missing final LTO flag in $flags" >&2
                exit 1
              fi
              if ${ripgrep}/bin/rg --no-config -q -- '-fprofile-generate|-fprofile-arcs|-ftest-coverage' "$flags"; then
                echo "Profiling instrumentation remains enabled in $flags" >&2
                exit 1
              fi
            done
            echo "PGO final compile and link flags verified"

            ${runBenchmarks "validation"}
            # Detect added/deleted profiles and modified profile contents
            snapshot_profiles >"$NIX_BUILD_TOP/profiles.after.sha256"
            if ! ${uutilsDiffutils}/bin/cmp -s "$NIX_BUILD_TOP/profiles.before.sha256" "$NIX_BUILD_TOP/profiles.after.sha256"; then
              echo "The optimized build or validation changed the gcda profile set" >&2
              exit 1
            fi
            echo "PGO profile set is unchanged after optimized validation"
          '';
        });
}
