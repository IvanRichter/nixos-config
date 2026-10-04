{ den, ... }:

{
  den.aspects.crypto.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      configFile = "/var/lib/xmrig-cpu/config.json";
      pearlConfigFile = "/var/lib/pearl-gpu/config.json";
      gpuTemplate =
        pool: wallet:
        builtins.toJSON {
          inherit pool wallet;
          worker = "desktop-gpu";
          gpu = 0;
        };
      pearlTemplate = gpuTemplate "stratum+tcp://pearlpow.unmineable.com:3333" "RECEIVING_XMR_ADDRESS";
      gpuCheck =
        name: configFile:
        pkgs.writeShellApplication {
          name = "${name}-gpu-check";
          runtimeInputs = [ pkgs.jaq ];
          text = ''
            if (( $# > 1 )); then echo "Usage: ${name}-gpu-check [candidate.json]" >&2; exit 2; fi
            config_file=''${1:-${configFile}}
            # Check private JSON without starting the miner
            if [[ ! -f $config_file || -L $config_file ]] || ! jaq --slurp --exit-status '
              def filled:
                type == "string" and length > 0 and
                (test("(?i)[[:space:][:cntrl:]]|receiving|placeholder|your_|wallet_address|pool:port") | not);
              length == 1 and (.[0] |
                type == "object" and
                (keys | sort) == ["gpu", "pool", "wallet", "worker"] and
                (.pool | filled and test("^stratum\\+(tcp|ssl)://[a-zA-Z0-9.-]+:[0-9]+$")) and
                (.wallet | filled and (startswith("-") | not)) and
                (.worker | type == "string" and test("^[a-zA-Z0-9_-]+$")) and
                (.gpu | type == "number" and . >= 0 and . == floor))
            ' "$config_file" >/dev/null 2>&1; then
              echo "Invalid ${name} config. Run mine-setup ${name} and set wallet in ${configFile}." >&2
              echo "Set pool, wallet, worker and gpu; empty or placeholder values are not allowed." >&2
              exit 1
            fi
          '';
        };
      pearlCheck = gpuCheck "pearl" pearlConfigFile;
      pearlRun = pkgs.writeShellApplication {
        name = "pearl-gpu-run";
        runtimeInputs = [ pkgs.jaq ];
        text = ''
          ${lib.getExe pearlCheck}
          gpu=$(jaq --raw-output .gpu ${pearlConfigFile})
          smi=${lib.getBin config.hardware.nvidia.package}/bin/nvidia-smi
          device=$("$smi" --id="$gpu" --query-gpu=name,uuid --format=csv,noheader)
          IFS=, read -r name uuid <<<"$device"
          if [[ $name != "NVIDIA GeForce RTX 4060 Ti" ]]; then
            echo "GPU #$gpu is not an RTX 4060 Ti." >&2
            exit 1
          fi
          uuid=''${uuid# }
          export CUDA_VISIBLE_DEVICES="$uuid" ONEAPI_DEVICE_SELECTOR=cuda:0
          export MOM_GPU_BACKEND=nvidia MOM_GPU_INDEX=0
          export MOM_THERMAL_DEVICE="$uuid" MOM_NVIDIA_SMI="$smi"
          umask 077
          # Keep the upstream donation configuration and fee
          # shellcheck disable=SC2016
          jaq --exit-status --slurpfile defaults ${pkgs.mo-miner}/libexec/mo-miner/defaults.json '
            . as $c | ($c.pool | capture("^stratum\\+(?<scheme>tcp|ssl)://(?<host>[a-zA-Z0-9.-]+):(?<port>[0-9]+)$")) as $pool |
            $defaults[0] |
            .job += {algo: "pearlhash", dev: "gpu1", backend: "native"} |
            .bench_algo_params = 0 | .pool_time.stats = 30 |
            .pools += [{url: $pool.host, port: ($pool.port | tonumber), is_tls: ($pool.scheme == "ssl"),
              protocol: "pearlhash", tls_verify: true, use_subscribe: true,
              pearlhash_rank_penalty: true, worker: $c.worker,
              login: ("XMR:" + $c.wallet + "." + $c.worker), pass: "x", is_keepalive: false}] |
            .pool_ids.primary = 1
          ' ${pearlConfigFile} > /run/pearl-gpu/config.json
          echo "Pearl: pearlhash on NVIDIA RTX 4060 Ti, GPU #$gpu; payouts in XMR; thermal pause/resume 80C/65C"
          exec ${lib.getExe pkgs.mo-miner} mine /run/pearl-gpu/config.json
        '';
      };
      checkConfig = pkgs.writeShellApplication {
        name = "xmrig-cpu-check";
        runtimeInputs = [
          pkgs.uutils-coreutils-noprefix
          pkgs.jaq
        ];
        text = ''
          if (( $# > 1 )); then echo "Usage: xmrig-cpu-check [candidate.json]" >&2; exit 2; fi
          config_file=''${1:-${configFile}}
          if ! test -r "$config_file"; then
            echo "Create ${configFile} as xmrig-cpu:xmrig-cpu with mode 0600 first." >&2
            exit 1
          fi
          if ! jaq -e '
            (.pools | type == "array" and length > 0) and
            any(.pools[]; .enabled != false) and
            all(.pools[]; .enabled == false or
              (.user | type == "string" and
                (gsub("^\\s+|\\s+$"; "") |
                  length > 0 and . != "RECEIVING_XMR_ADDRESS")))
          ' "$config_file" >/dev/null; then
            echo "Set pools[0].user in ${configFile} to the Monero receiving address (no empty or placeholder wallets)." >&2
            exit 1
          fi
          if ! jaq -e '
            .cpu.enabled == true and .opencl.enabled == false and .cuda.enabled == false and
            .http.enabled == false and .background == false and
            (.randomx.wrmsr != true or .randomx.rdmsr == true)
          ' "$config_file" >/dev/null; then
            echo "Use foreground CPU mining with OpenCL, CUDA and HTTP disabled. Enable rdmsr when using wrmsr." >&2
            exit 1
          fi
          umask 077
          check_dir=$(mktemp -d "$(dirname -- "$config_file")/.check.XXXXXX")
          trap 'rm -rf -- "$check_dir"' EXIT
          trap 'exit 130' INT
          trap 'exit 143' TERM
          trap 'exit 129' HUP
          if ! ${lib.getExe pkgs.xmrig} --config="$config_file" --dry-run 2>&1 | cat >"$check_dir/output"; then
            # Filter variables are expanded by jaq, not Bash
            # shellcheck disable=SC2016
            if jaq --null-input --raw-output --join-output \
              --slurpfile config "$config_file" \
              --rawfile output "$check_dir/output" '
                reduce (
                  $config[].pools[].user
                  | select(type == "string" and length > 0)
                ) as $wallet (
                  $output;
                  split($wallet) | join("[wallet redacted]")
                )
              ' >"$check_dir/redacted" 2>/dev/null; then
              cat -- "$check_dir/redacted" >&2
            else
              echo "XMRig diagnostic output could not be safely redacted, output withheld." >&2
            fi
            echo "XMRig configuration validation failed." >&2
            exit 1
          fi
        '';
      };
      prepareConfig = pkgs.writeShellApplication {
        name = "xmrig-cpu-prepare";
        runtimeInputs = [
          pkgs.uutils-coreutils-noprefix
          pkgs.jaq
        ];
        text = ''
          if (( $# != 1 )) || [[ $1 != normal && $1 != hard ]]; then
            echo "Usage: xmrig-cpu-prepare normal|hard" >&2
            exit 1
          fi
          mode=$1
          source_file=${configFile}
          target="/run/xmrig-cpu-$mode/config.json"
          topology=/sys/devices/system/cpu
          temporary=""

          fail() {
            printf 'Cannot prepare config: %s\n' "$*" >&2
            exit 1
          }

          cleanup() {
            if [[ -n $temporary ]]; then
              rm -f -- "$temporary"
            fi
          }

          trap cleanup EXIT
          trap 'exit 130' INT
          trap 'exit 143' TERM
          trap 'exit 129' HUP
          umask 077

          # Read this process's allowed CPUs
          affinity=""
          while IFS=: read -r field value; do
            if [[ $field == Cpus_allowed_list ]]; then
              affinity=''${value//[[:space:]]/}
              break
            fi
          done <"/proc/$$/status" || fail "cannot read CPU affinity"
          [[ -n $affinity ]] || fail "CPU affinity is missing from /proc/$$/status"
          if [[ ! $affinity =~ ^[0-9]+(-[0-9]+)?(,[0-9]+(-[0-9]+)?)*$ ]]; then
            fail "invalid CPU affinity list"
          fi

          # Expand ranges and keep the same numeric ordering as sched_getaffinity
          available=()
          IFS=',' read -r -a ranges <<<"$affinity"
          for range in "''${ranges[@]}"; do
            first=''${range%-*}
            last=''${range#*-}
            first=$((10#$first))
            last=$((10#$last))
            (( first <= last )) || fail "invalid CPU affinity range"
            for (( cpu=first; cpu<=last; cpu++ )); do
              available+=("$cpu")
            done
          done
          sorted=$(printf '%s\n' "''${available[@]}" | sort -nu) || fail "cannot sort CPU IDs"
          mapfile -t available <<<"$sorted"

          # Select the first eight distinct sibling groups in normal mode
          declare -A selected_cores=()
          core_count=0
          workers=()
          for cpu in "''${available[@]}"; do
            if ! IFS= read -r siblings <"$topology/cpu$cpu/topology/thread_siblings_list"; then
              fail "cannot read topology for CPU $cpu"
            fi
            if [[ ! $siblings =~ ^[0-9]+(-[0-9]+)?(,[0-9]+(-[0-9]+)?)*$ ]]; then
              fail "invalid sibling list for CPU $cpu"
            fi

            if [[ $mode == hard ]]; then
              workers+=("$cpu")
              continue
            fi
            if [[ -z ''${selected_cores[$siblings]+present} ]] && (( core_count < 8 )); then
              selected_cores["$siblings"]=1
              core_count=$((core_count + 1))
            fi
            if [[ -n ''${selected_cores[$siblings]+present} ]] && (( ''${#workers[@]} < 16 )); then
              workers+=("$cpu")
            fi
          done
          if [[ $mode == normal ]] && (( core_count < 8 )); then
            fail "normal mode needs eight physical cores"
          fi
          worker_count=''${#workers[@]}
          (( worker_count > 0 )) || fail "no available CPUs"
          initialization=$worker_count
          if [[ $mode == normal ]]; then
            initialization=4
          fi
          cpu_json=$(printf '%s\n' "''${workers[@]}" | jaq --compact-output --slurp '.') \
            || fail "cannot encode CPU IDs"

          # Create the replacement beside its destination, with private perms
          temporary=$(mktemp "''${target%/*}/.config-XXXXXX") || fail "cannot create temporary config"
          # Filter variables are expanded by jaq, not Bash
          # shellcheck disable=SC2016
          if ! jaq --exit-status --slurp \
            --argjson cpus "$cpu_json" \
            --argjson initialization "$initialization" '
              if length != 1 then
                error("expected exactly one JSON document")
              else
                .[0]
              end
              | if type != "object" then
                  error("configuration must be an object")
                elif (.cpu | type) != "object" or (.randomx | type) != "object" then
                  error("cpu and randomx must be objects")
                else
                  .autosave = false
                  | .watch = false
                  | .["donate-level"] = 0
                  | .cpu += {
                      "rx": $cpus,
                      "rx/0": $cpus,
                      "priority": null,
                      "yield": true,
                      "huge-pages": true
                    }
                  | .randomx += {
                      "init": $initialization,
                      "1gb-pages": true,
                      "rdmsr": true,
                      "wrmsr": true,
                      "cache_qos": false
                    }
                end
            ' "$source_file" >"$temporary" 2>/dev/null; then
            fail "check source JSON, cpu and randomx must be objects"
          fi
          mv -fT -- "$temporary" "$target" || fail "cannot install effective config"
          temporary=""

          ids=$(IFS=,; printf '%s' "''${workers[*]}")
          printf 'Mining mode: %s; workers: %s; CPU IDs: %s; initialization threads: %s\n' \
            "$mode" "$worker_count" "$ids" "$initialization"
          if [[ $mode == hard ]]; then
            echo "Hard mode kills desktop responsiveness."
          fi
        '';
      };
      mineSetup = pkgs.writeShellApplication {
        name = "mine-setup";
        runtimeInputs = [
          pkgs.uutils-coreutils-noprefix
          pkgs.systemd
          pkgs.util-linux
        ];
        text = ''
          if (( $# > 1 )); then echo "Usage: mine-setup [pearl|--help]" >&2; exit 2; fi
          case "''${1:-}" in
            --help|-h)
              echo "Usage: mine-setup [pearl]"
              echo "Edit a private copy in Micro and install it after a non-mining check."
              exit 0
              ;;
            ""|pearl) ;;
            *) echo "Usage: mine-setup [pearl|--help]" >&2; exit 2 ;;
          esac
          if [[ ! -t 0 || ! -t 1 ]]; then
            echo "Run mine-setup in an interactive terminal." >&2
            exit 1
          fi

          kind=''${1:-xmr}
          case "$kind" in
            xmr) service_user=xmrig-cpu config_file=${configFile} check=${lib.getExe checkConfig} ;;
            pearl) service_user=pearl-gpu config_file=${pearlConfigFile} check=${lib.getExe pearlCheck} ;;
          esac
          state_dir=''${config_file%/*}
          account=$(id -un)
          if [[ $account != "$service_user" ]]; then
            runtime_dir=''${XDG_RUNTIME_DIR:-/run/user/$UID}
            if [[ ! -d $runtime_dir || ! -O $runtime_dir ]]; then
              echo "Run mine-setup from desktop login." >&2
              exit 1
            fi
            umask 077
            exec 9>"$runtime_dir/xmrig-cpu.lock"
            flock --exclusive 9
          fi
          for unit in xmrig-cpu-normal.service xmrig-cpu-hard.service pearl-gpu.service; do
            case "$(systemctl show "$unit" --property=ActiveState --value)" in
              inactive|failed) ;;
              *) echo "Run mine stop before editing the configuration." >&2; exit 1 ;;
            esac
          done
          if [[ $account != "$service_user" ]]; then
            # Hold the lock while sudo closes inherited descriptors
            /run/wrappers/bin/sudo -u "$service_user" -- "$0" "$@" 9>&-
            exit
          fi

          if [[ ! -d $state_dir || ! -w $state_dir ]]; then
            echo "Rebuild the desktop configuration to prepare $state_dir." >&2
            exit 1
          fi
          if [[ -L "$config_file" || ( -e "$config_file" && ! -f "$config_file" ) ]]; then
            echo "Expected a regular file at $config_file." >&2
            exit 1
          fi
          umask 077
          chmod 0700 "$state_dir"
          edit_dir=$(mktemp -d "$state_dir/.edit.XXXXXX")
          trap 'rm -rf -- "$edit_dir"' EXIT
          trap 'exit 130' INT
          trap 'exit 143' TERM
          trap 'exit 129' HUP
          candidate="$edit_dir/config.json"
          if [[ -e "$config_file" ]]; then
            cp -- "$config_file" "$candidate"
          elif [[ $kind == pearl ]]; then
            printf '%s\n' '${pearlTemplate}' >"$candidate"
          else
            cat >"$candidate" <<'JSON'
          {
            "autosave": true,
            "background": false,
            "colors": false,
            "http": { "enabled": false },
            "randomx": {
              "init": -1,
              "mode": "auto",
              "1gb-pages": true,
              "rdmsr": true,
              "wrmsr": true,
              "numa": true
            },
            "cpu": {
              "enabled": true,
              "huge-pages": true,
              "huge-pages-jit": false,
              "priority": null,
              "yield": true
            },
            "opencl": { "enabled": false },
            "cuda": { "enabled": false },
            "donate-level": 0,
            "print-time": 30,
            "log-file": null,
            "dmi": false,
            "watch": false,
            "pools": [
              {
                "coin": "monero",
                "url": "pool.hashvault.sh:443",
                "user": "RECEIVING_XMR_ADDRESS",
                "pass": "desktop-cpu",
                "keepalive": true,
                "tls": true
              }
            ]
          }
          JSON
          fi
          chmod 0600 "$candidate"
          if [[ $kind == pearl ]]; then
            echo "Edit wallet in ${pearlConfigFile}: use the Monero receiving address for XMR payouts."
          else
            echo "Set pools[0].user in ${configFile} to the Monero receiving address."
          fi
          ${lib.getExe pkgs.micro} "$candidate"
          "$check" "$candidate"
          if [[ ! -f $candidate || -L $candidate ]]; then exit 1; fi
          chmod 0600 "$candidate"
          mv -T -- "$candidate" "$config_file"
          echo "Configuration saved. Use mine for CPU mining or mine hard for both."
        '';
      };
      mine = pkgs.writeShellApplication {
        name = "mine";
        runtimeInputs = [
          pkgs.uutils-coreutils-noprefix
          pkgs.systemd
          pkgs.util-linux
        ];
        text = ''
          requested_mode=normal
          owned_session=""
          logical=""
          record_unit=xmrig-cpu-normal.service
          record_cpu=-
          record_gpu=-
          record_gpu_unit=pearl-gpu.service
          selected_gpu=pearl-gpu.service
          locked=0
          interrupted=0
          declare -A states invocations results followers followed
          units=(xmrig-cpu-normal.service xmrig-cpu-hard.service pearl-gpu.service)

          usage() {
            cat <<'HELP'
          Usage: mine [hard|slow|stop|logs|--help]
            mine       Normal CPU mining, GPU off
            hard       Full CPU and GPU mining
            slow       Return to normal CPU mining and stop the GPU
            stop       Stop both miners
            logs       Follow both miners; Ctrl+C closes the logs
          MO-Miner mines Pearl with XMR payouts
          Run mine-setup [pearl] to edit the private config in Micro
          Normal CPU-only mining starts at boot
          One hour without input enables hard CPU and GPU mining; activity returns to normal
          Manually selected hard mode stays hard until mine slow or mine stop
          Ctrl+C in mine stops mining; use mine stop if its terminal was killed
          HELP
          }

          read_state() {
            local properties key value
            local -A status=()
            properties=$(systemctl show "$unit" --property=LoadState,ActiveState,InvocationID,Result) || return
            while IFS='=' read -r key value; do
              [[ -z $key ]] || status[$key]=$value
            done <<<"$properties"
            states[$unit]=''${status[ActiveState]:-}
            invocations[$unit]=''${status[InvocationID]:-}
            results[$unit]=''${status[Result]:-}
            if [[ ''${status[LoadState]:-} != loaded || -z ''${states[$unit]} ]]; then
              if [[ $unit == *-gpu.service ]]; then
                states[$unit]=unavailable
              else
                echo "$unit is unavailable. Rebuild the desktop configuration." >&2
                return 1
              fi
            fi
          }

          running() {
            [[ ''${states[$1]} == @(active|activating|reloading|deactivating) ]]
          }

          find_session() {
            local candidate active="" active_gpu=""
            for candidate in "''${units[@]}"; do
              unit=$candidate
              read_state || return
              running "$unit" || continue
              if [[ $unit == *-gpu.service ]]; then
                active_gpu=$unit
              else
                if [[ -n $active ]]; then
                  echo "Both CPU modes are active; inspect systemctl status 'xmrig-cpu-*.service'." >&2
                  return 1
                fi
                active=$unit
              fi
            done
            gpu_unit=''${active_gpu:-$selected_gpu}
            unit=''${active:-$requested_unit}
            mode=''${unit#xmrig-cpu-}
            mode=''${mode%.service}
          }

          any_running() {
            running "$unit" || running "$gpu_unit"
          }

          report_gpu() {
            if ! running "$gpu_unit"; then
              if [[ $mode == normal ]] && running "$unit"; then
                echo "GPU mining is off in normal mode."
                return
              fi
              echo "$gpu_unit is stopped or unconfigured. Run mine-setup ''${gpu_unit%-gpu.service} to configure it."
              if [[ $command == logs && -n ''${invocations[$gpu_unit]} ]]; then
                journalctl --quiet --no-pager --output=short -n 30 \
                  "_SYSTEMD_INVOCATION_ID=''${invocations[$gpu_unit]}"
              fi
            fi
          }

          lock() {
            flock --exclusive 9
            locked=1
          }
          unlock() {
            flock --unlock 9
            locked=0
          }

          read_session() {
            session_id="" session_unit="" session_invocation="" session_origin="" session_gpu="" session_gpu_unit=""
            local extra=""
            [[ -f $session_file && ! -L $session_file ]] || return 1
            read -r session_id session_unit session_invocation session_origin session_gpu session_gpu_unit extra <"$session_file" || return 1
            # Older records track only the CPU
            session_legacy=0
            if [[ -z $session_gpu ]]; then
              session_legacy=1
              session_gpu=-
            fi
            session_gpu_unit=''${session_gpu_unit:-pearl-gpu.service}
            [[ $session_gpu_unit == pearl-gpu.service ]] || return 1
            [[ $session_id =~ ^[0-9a-f]{32}$ && -z $extra ]] || return 1
            [[ $session_invocation == - || $session_invocation =~ ^[0-9a-f]{32}$ ]] || return 1
            [[ $session_gpu == - || $session_gpu =~ ^[0-9a-f]{32}$ ]] || return 1
            [[ $session_unit == xmrig-cpu-@(normal|hard).service ]] || return 1
            [[ $session_origin == @(manual|idle) ]]
          }

          save_session() {
            local temporary legacy=0
            if read_session && [[ $session_id == "$logical" && $session_legacy == 1 && $record_gpu == - ]]; then legacy=1; fi
            temporary=$(mktemp "$runtime_dir/.xmrig-session.XXXXXX")
            if ((legacy)); then
              printf '%s %s %s %s\n' "$logical" "$record_unit" "$record_cpu" "$1" >"$temporary"
            else
              printf '%s %s %s %s %s %s\n' "$logical" "$record_unit" "$record_cpu" "$1" "$record_gpu" "$record_gpu_unit" >"$temporary"
            fi
            mv -T -- "$temporary" "$session_file"
          }

          capture_session() {
            record_unit=$unit
            record_gpu_unit=$gpu_unit
            record_cpu=''${invocations[$unit]:--}
            record_gpu=''${invocations[$gpu_unit]:--}
            running "$unit" || record_cpu=-
            running "$gpu_unit" || record_gpu=-
            logical=$record_cpu
            [[ $logical != - ]] || logical=$record_gpu
            if read_session && { [[ $session_unit == "$unit" && $session_invocation == "$record_cpu" && $record_cpu != - ]] ||
              [[ $record_cpu == - && $session_gpu == "$record_gpu" && $session_gpu_unit == "$record_gpu_unit" && $record_gpu != - ]]; }; then
              logical=$session_id
            fi
          }

          adopt_session() {
            if read_session && [[ $session_id == "$logical" ]]; then
              record_unit=$session_unit
              record_cpu=$session_invocation
              record_gpu=$session_gpu
              record_gpu_unit=$session_gpu_unit
            fi
          }

          clear_session() {
            if read_session && [[ $session_id == "$logical" ]]; then
              rm -f -- "$session_file" "$runtime_dir/xmrig-cpu-idle/promotion"
            fi
          }

          defer_signals() {
            trap 'interrupted=130' INT
            trap 'interrupted=143' TERM
            trap 'interrupted=129' HUP
          }

          resume_signals() {
            trap 'exit 130' INT
            trap 'exit 143' TERM
            trap 'exit 129' HUP
            if ((interrupted)); then exit "$interrupted"; fi
          }

          run_job() {
            local job rc=0
            (
              trap "" INT TERM HUP
              exec systemctl --no-ask-password "$1" "$unit"
            ) 9>&- &
            job=$!
            while true; do
              wait "$job" && return 0
              rc=$?
              kill -0 "$job" 2>/dev/null || return "$rc"
            done
          }

          stop_service() {
            read_state || return
            if ! running "$unit"; then return; fi
            # Leave replacement invocations alone during owner cleanup
            if [[ $# == 1 && ''${invocations[$unit]} != "$1" ]]; then return; fi
            echo "Stopping $unit..."
            run_job stop || return
            read_state || return
            if running "$unit"; then
              echo "$unit has not stopped. Check mine logs." >&2
              return 1
            fi
          }

          start_gpu() {
            local previous rc=0
            unit=$gpu_unit
            record_gpu_unit=$unit
            read_state
            # Keep an existing worker and its owner
            if running "$unit"; then return; fi
            previous=''${invocations[$unit]}
            echo "Starting $unit..."
            if [[ ''${states[$unit]} != unavailable ]]; then run_job start || rc=$?; fi
            read_state
            if [[ -n ''${invocations[$unit]} && ''${invocations[$unit]} != "$previous" ]]; then
              record_gpu=''${invocations[$unit]}
            fi
            if ((rc)) || [[ ''${states[$unit]} != active ]]; then
              echo "$unit could not start. CPU mining will continue. Check mine logs or mine-setup ''${unit%-gpu.service}." >&2
            else
              echo "$unit started."
            fi
          }

          stop_gpu() {
            unit=$record_gpu_unit
            read_state || return
            if running "$unit"; then
              if [[ ''${invocations[$unit]} != "$record_gpu" ]]; then
                echo "The GPU worker changed. Run mine stop before switching to normal mode." >&2
                return 1
              fi
              stop_service || return
            fi
            record_gpu=-
          }

          stop_session() {
            local candidate expected rc=0
            for candidate in "$record_unit" "$record_gpu_unit"; do
              expected=$record_cpu
              [[ $candidate != "$record_gpu_unit" ]] || expected=$record_gpu
              [[ $expected != - ]] || continue
              unit=$candidate
              stop_service "$expected" || rc=1
            done
            if ((rc == 0)); then clear_session; fi
            return "$rc"
          }

          stop_follower() {
            local source=$1 pid=''${followers[$1]:-}
            if [[ -n $pid ]]; then
              kill -KILL "$pid" 2>/dev/null || true
              wait "$pid" 2>/dev/null || true
              unset 'followers[$source]'
            fi
          }

          cleanup() {
            local rc=$?
            trap - EXIT
            trap "" INT TERM HUP
            stop_follower XMR
            stop_follower GPU
            if [[ -n $owned_session ]]; then
              echo "Stopping mining..."
              if ((! locked)); then lock; fi
              logical=$owned_session
              adopt_session
              if ! stop_session; then
                echo "Could not stop mining. Run mine stop." >&2
                rc=1
              fi
            fi
            exit "$rc"
          }

          follow_session() {
            local initial_lines=$1 source expected candidate alive lines
            declare -A reported=()
            echo "Showing logs; miner keyboard shortcuts are unavailable."
            while true; do
              lock
              adopt_session
              alive=0
              for source in XMR GPU; do
                candidate=$record_unit expected=$record_cpu
                [[ $source != GPU ]] || {
                  candidate=$record_gpu_unit
                  expected=$record_gpu
                }
                if [[ $expected == - ]]; then
                  stop_follower "$source"
                  continue
                fi
                unit=$candidate
                read_state
                if [[ ''${invocations[$unit]} == "$expected" ]] && running "$unit"; then
                  alive=1
                elif [[ -z ''${reported[$expected]:-} ]]; then
                  echo "$source mining stopped (''${results[$unit]})."
                  reported[$expected]=1
                fi
                if [[ ''${followed[$source]:-} != "$expected" ]]; then
                  lines=$initial_lines
                  [[ -z ''${followed[$source]:-} ]] || lines=all
                  stop_follower "$source"
                  defer_signals
                  # Follow each invocation once without replaying the other worker
                  journalctl --quiet --no-pager --output=short --lines="$lines" --follow \
                    "_SYSTEMD_INVOCATION_ID=$expected" 9>&- &
                  followers[$source]=$!
                  followed[$source]=$expected
                  resume_signals
                elif ! kill -0 "''${followers[$source]}" 2>/dev/null; then
                  echo "$source journal follower ended unexpectedly." >&2
                  return 1
                fi
              done
              unlock
              if ((! alive)); then
                echo "This mining session ended."
                return
              fi
              sleep 1
            done
          }

          switch_mode() {
            local target=$1 origin=$2 rc=0 legacy=0
            local ticket="$runtime_dir/xmrig-cpu-idle/promotion"
            capture_session
            # Preserve ownership across mode changes
            if read_session && [[ $session_id == "$logical" ]]; then
              record_gpu=$session_gpu
              record_gpu_unit=$session_gpu_unit
              legacy=$session_legacy
              gpu_unit=$record_gpu_unit
            fi
            defer_signals
            if [[ $target == normal ]]; then stop_gpu || return 1; fi
            unit=$record_unit
            if [[ $unit != "xmrig-cpu-$target.service" ]]; then
              stop_service || return 1
              unit="xmrig-cpu-$target.service"
              run_job start || rc=$?
              read_state
              record_unit=$unit record_cpu=''${invocations[$unit]:--}
            fi
            # Start the GPU only after the CPU transition succeeds
            if ((rc == 0)) && [[ ''${states[$record_unit]} == active && $target == hard ]]; then
              if ((legacy)); then
                echo "This older session is CPU-only. Run mine stop then mine hard to enable the GPU."
              else
                start_gpu
              fi
            fi
            save_session "$origin"
            if [[ ''${states[$record_unit]} == active && $origin == idle ]]; then
              printf '%s %s\n' "$logical" "$record_cpu" >"$ticket"
            else
              rm -f -- "$ticket"
            fi
            resume_signals
            if ((rc)) || [[ ''${states[$record_unit]} != active ]]; then
              echo "Could not switch CPU mining to $target. Check mine logs." >&2
              return 1
            fi
            echo "Mining switched to $target mode."
          }

          idle_transition() {
            local target origin ticket ticket_session ticket_invocation
            ticket=''${MINE_IDLE_TICKET:-$runtime_dir/xmrig-cpu-idle/promotion}
            [[ $ticket == "$runtime_dir/xmrig-cpu-idle/promotion" && -d ''${ticket%/*} ]] || return 0
            lock
            find_session
            [[ ''${states[$unit]} == active && -n ''${invocations[$unit]} ]] || return 0
            if ! read_session || [[ $session_unit != "$unit" || $session_invocation != "''${invocations[$unit]}" ]]; then
              # Boot mining has no session record yet
              [[ $command == idle-hard && $unit == xmrig-cpu-normal.service ]] || return 0
              session_origin=manual
            fi
            if [[ $command == idle-hard ]]; then
              if [[ $unit == xmrig-cpu-hard.service && $session_origin == idle ]]; then
                printf '%s %s\n' "$session_id" "''${invocations[$unit]}" >"$ticket"
                return 0
              fi
              [[ $unit == xmrig-cpu-normal.service && $session_origin == manual ]] || return 0
              target=hard origin=idle
            else
              [[ $unit == xmrig-cpu-hard.service && $session_origin == idle && -f $ticket ]] || return 0
              read -r ticket_session ticket_invocation <"$ticket" || return 0
              [[ $ticket_session == "$session_id" && $ticket_invocation == "''${invocations[$unit]}" ]] || return 0
              target=normal origin=manual
            fi
            switch_mode "$target" "$origin"
          }

          offer_stop() {
            local answer="" prompted_cpu prompted_gpu prompted_unit prompted_gpu_unit
            report_gpu
            capture_session
            prompted_cpu=$record_cpu prompted_gpu=$record_gpu prompted_unit=$record_unit prompted_gpu_unit=$record_gpu_unit
            unlock
            if [[ ! -t 0 || ! -t 1 ]]; then
              echo "Mining is already running. Use mine stop to stop it." >&2
              exit 1
            fi
            printf 'Mining is already running. Stop it? [y/N] '
            if ! IFS= read -r answer; then
              printf '\n'
              exit 0
            fi
            if [[ $answer != [yY] ]]; then
              echo "Mining left running."
              exit 0
            fi
            lock
            find_session
            capture_session
            # Don't stop workers started while the prompt was open
            if [[ $record_cpu != "$prompted_cpu" || $record_gpu != "$prompted_gpu" || $record_unit != "$prompted_unit" || $record_gpu_unit != "$prompted_gpu_unit" ]]; then
              echo "The session changed. Mining left running."
            else
              defer_signals
              stop_session
              resume_signals
              echo "Mining stopped."
            fi
            exit 0
          }

          if (($# > 1)); then
            usage >&2
            exit 2
          fi
          command=''${1:-start}
          case "$command" in
          --help | -h)
            usage
            exit 0
            ;;
          slow | stop | logs | idle-hard | idle-resume) ;;
          hard)
            requested_mode=hard
            command=start
            ;;
          start) if (($#)); then
            usage >&2
            exit 2
          fi ;;
          *)
            usage >&2
            exit 2
            ;;
          esac

          trap cleanup EXIT
          resume_signals
          requested_unit="xmrig-cpu-$requested_mode.service"
          runtime_dir=''${XDG_RUNTIME_DIR:-/run/user/$UID}
          if [[ ! -d $runtime_dir || ! -O $runtime_dir ]]; then
            [[ $command == idle-* ]] && exit 0
            echo "A user runtime directory is required. Run mine from desktop login." >&2
            exit 1
          fi
          umask 077
          exec 9>"$runtime_dir/xmrig-cpu.lock"
          session_file="$runtime_dir/xmrig-cpu.session"
          if [[ $command == idle-* ]]; then
            idle_transition
            exit
          fi
          lock

          if [[ $command == stop ]]; then
            # Stop surviving workers even if another unit is unavailable
            defer_signals
            stop_rc=0
            for unit in "''${units[@]}"; do
              stop_service || stop_rc=1
            done
            if ((stop_rc == 0)); then rm -f -- "$session_file" "$runtime_dir/xmrig-cpu-idle/promotion"; fi
            resume_signals
            echo "Mining stop completed."
            exit "$stop_rc"
          fi

          find_session
          if [[ $command == logs ]]; then
            report_gpu
            if any_running; then
              capture_session
              unlock
              follow_session 30
            else
              unlock
              journalctl --quiet --no-pager --output=short -n 30 \
                --unit=xmrig-cpu-normal.service --unit=xmrig-cpu-hard.service --unit=pearl-gpu.service
            fi
            exit 0
          fi

          if [[ $command == slow ]]; then
            if [[ ''${states[$unit]} == active ]]; then
              switch_mode normal manual
            else
              echo "CPU is stopped or transitioning; GPU is unchanged."
            fi
            exit 0
          fi

          if any_running; then offer_stop; fi
          record_gpu_unit=$gpu_unit

          defer_signals
          # Track the GPU before CPU startup can fail
          if [[ $requested_mode == hard ]]; then
            start_gpu
            if [[ $record_gpu != - ]]; then owned_session=$record_gpu; fi
          else
            echo "GPU mining is off in normal mode."
          fi

          echo "Starting XMR CPU mining ($requested_mode)..."
          unit=$requested_unit
          previous=''${invocations[$unit]}
          start_rc=0
          run_job start || start_rc=$?
          read_state
          record_unit=$unit
          if [[ -n ''${invocations[$unit]} && ''${invocations[$unit]} != "$previous" ]]; then
            record_cpu=''${invocations[$unit]}
            owned_session=''${owned_session:-$record_cpu}
          fi
          logical=$owned_session
          if [[ -n $logical ]]; then save_session manual; fi
          rm -f -- "$runtime_dir/xmrig-cpu-idle/promotion"
          resume_signals
          if ((start_rc)) || [[ ''${states[$unit]} != active || $record_cpu == - ]]; then
            echo "CPU mining did not start. Check mine logs and /var/lib/xmrig-cpu/config.json." >&2
            exit 1
          fi
          unlock
          echo "XMR started in $requested_mode mode. Ctrl+C stops mining."
          follow_session all
        '';
      };

      # Use real input idle time, don't interpret watcher shutdown as activity
      idleClient = (pkgs.swayidle.override { systemdSupport = false; }).overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace main.c \
            --replace-fail 'wl_registry_bind(registry, name, &ext_idle_notifier_v1_interface, 1)' \
              '(version >= 2 ? wl_registry_bind(registry, name, &ext_idle_notifier_v1_interface, 2) : NULL)' \
            --replace-fail 'register_timeout(cmd, cmd->timeout, true);' \
              'register_timeout(cmd, cmd->timeout, false);' \
            --replace-fail 'if (cmd->resume_pending) {' 'if (false && cmd->resume_pending) {'
        '';
      });

      mkMiningService = lib.recursiveUpdate {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        restartIfChanged = false;
        serviceConfig = {
          Type = "exec";
          UMask = "0077";
          Restart = "no";
          TimeoutStartSec = 30;
          KillSignal = "SIGTERM";
          KillMode = "control-group";
          StandardOutput = "journal";
          StandardError = "journal";
          Nice = 19;
          CPUWeight = 10;
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = false;
          DevicePolicy = "closed";
          ProtectHome = true;
          ProtectSystem = "strict";
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
          LockPersonality = true;
          SystemCallArchitectures = "native";
          # Both miners need JIT-generated code
          MemoryDenyWriteExecute = false;
        };
      };
      mkGpuService =
        name: description: check: run:
        mkMiningService {
          inherit description;
          after = [
            "network-online.target"
            "systemd-modules-load.service"
            "systemd-udev-trigger.service"
          ];
          # Don't add a GPU worker to an active session during rebuild
          unitConfig.X-OnlyManualStart = true;
          environment = {
            XDG_CACHE_HOME = "/var/cache/${name}-gpu";
            CUDA_CACHE_PATH = "/var/cache/${name}-gpu/nvidia";
            MOM_JIT_CACHE_DIR = "/var/cache/${name}-gpu/jit";
            SYCL_CACHE_DIR = "/var/cache/${name}-gpu/sycl";
            SYCL_CACHE_PERSISTENT = "1";
          };
          serviceConfig = {
            User = "${name}-gpu";
            Group = "${name}-gpu";
            StateDirectory = "${name}-gpu";
            StateDirectoryMode = "0700";
            RuntimeDirectory = "${name}-gpu";
            RuntimeDirectoryMode = "0700";
            CacheDirectory = "${name}-gpu";
            CacheDirectoryMode = "0700";
            WorkingDirectory = "/var/lib/${name}-gpu";
            ExecCondition = lib.getExe check;
            ExecStart = lib.getExe run;
            # Bound shutdown if the GPU hangs
            TimeoutStopSec = 5;
            SyslogIdentifier = lib.toUpper name;
            CapabilityBoundingSet = "";
            AmbientCapabilities = "";
            DeviceAllow = [
              "/dev/nvidia0 rw"
              "/dev/nvidiactl rw"
              "/dev/nvidia-uvm rw"
              "/dev/nvidia-uvm-tools rw"
            ];
            ReadOnlyPaths = [ "-/var/lib/${name}-gpu/config.json" ];
            # Allow outbound connections without listening sockets
            SocketBindDeny = "any";
          };
        };
    in
    {
      environment.systemPackages = [
        mine
        mineSetup
        pkgs.mo-miner
      ];

      users.groups.xmrig-cpu.gid = 492;
      users.users.xmrig-cpu = {
        isSystemUser = true;
        group = "xmrig-cpu";
      };
      users.groups.pearl-gpu = { };
      users.users.pearl-gpu = {
        isSystemUser = true;
        group = "pearl-gpu";
        home = "/var/lib/pearl-gpu";
      };

      # Provision before the first start, even when ConditionPathExists skips it
      systemd.tmpfiles.rules = [
        "d /var/lib/xmrig-cpu 0700 xmrig-cpu xmrig-cpu -"

        # Fixes metadata only if the config already exists
        "z ${configFile} 0600 xmrig-cpu xmrig-cpu -"
        "d /var/lib/pearl-gpu 0700 pearl-gpu pearl-gpu -"
        "z ${pearlConfigFile} 0600 pearl-gpu pearl-gpu -"
      ];

      boot.kernel.sysctl = {
        "vm.hugetlb_shm_group" = config.users.groups.xmrig-cpu.gid;
      };
      boot.kernelParams = [
        "default_hugepagesz=2M"
        "hugepagesz=1G"
        "hugepages=3"
        "hugepagesz=2M"
        "hugepages=128"
      ];

      hardware.cpu.x86.msr = {
        enable = true;
        group = "xmrig-cpu";
        mode = "0660";
        settings.allow-writes = "on";
      };

      systemd.user.services.xmrig-cpu-idle = {
        description = "Promote running mining after one hour without input";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session-pre.target" ];
        unitConfig = {
          ConditionUser = "ivan";
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        serviceConfig = {
          ExecStart = "${lib.getExe idleClient} -w -C /dev/null timeout 3600 '${lib.getExe mine} idle-hard' resume '${lib.getExe mine} idle-resume'";
          RuntimeDirectory = "xmrig-cpu-idle";
          RuntimeDirectoryMode = "0700";
          RuntimeDirectoryPreserve = "restart";
          Environment = "MINE_IDLE_TICKET=%t/xmrig-cpu-idle/promotion";
          Restart = "always";
          RestartSec = 30;
          TimeoutStopSec = 75;
          UMask = "0077";
          NoNewPrivileges = true;
        };
      };

      # Leave the service's Nice=19 intact
      services.system76-scheduler.exceptions = [
        ''"${lib.getExe pkgs.xmrig}"''
      ];
      # Match MO-Miner's service without changing other Node processes
      services.system76-scheduler.assignments.pearl-gpu = {
        nice = 19;
        matchers = [ ''include cgroup="/system.slice/pearl-gpu.service"'' ];
      };

      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.user === "ivan" &&
              action.id === "org.freedesktop.systemd1.manage-units" &&
              (action.lookup("unit") === "xmrig-cpu-normal.service" ||
               action.lookup("unit") === "xmrig-cpu-hard.service" ||
               action.lookup("unit") === "pearl-gpu.service") &&
              (action.lookup("verb") === "start" || action.lookup("verb") === "stop")) {
            return polkit.Result.YES;
          }
        });
      '';

      systemd.services = {
        pearl-gpu =
          mkGpuService "pearl" "Pearl GPU mining with XMR payouts on the NVIDIA RTX 4060 Ti" pearlCheck
            pearlRun;
      }
      // lib.genAttrs [ "xmrig-cpu-normal" "xmrig-cpu-hard" ] (
        name:
        let
          mode = lib.removePrefix "xmrig-cpu-" name;
          other = if mode == "normal" then "hard" else "normal";
          runtimeDir = "/run/${name}";
          effectiveFile = "${runtimeDir}/config.json";
        in
        mkMiningService {
          description = "Monero CPU mining (${mode})";
          wantedBy = lib.optional (mode == "normal") "multi-user.target";
          conflicts = [ "xmrig-cpu-${other}.service" ];

          # Make systemd finish stopping one mode before starting the other
          before = lib.optional (mode == "normal") "xmrig-cpu-hard.service";
          unitConfig = {
            ConditionPathExists = configFile;
          };
          serviceConfig = {
            User = "xmrig-cpu";
            Group = "xmrig-cpu";
            WorkingDirectory = "/var/lib/xmrig-cpu";
            RuntimeDirectory = name;
            RuntimeDirectoryMode = "0700";
            ExecStartPre = [
              "${lib.getExe prepareConfig} ${mode}"
              "${lib.getExe checkConfig} ${effectiveFile}"
            ];
            ExecStart = "${lib.getExe pkgs.xmrig} --config=${effectiveFile}";
            TimeoutStopSec = 30;
            SyslogIdentifier = "XMR-${mode}";
            LimitMEMLOCK = "4G";

            # Linux msr_open requires RAWIO and device perms
            CapabilityBoundingSet = "CAP_SYS_RAWIO";
            AmbientCapabilities = "CAP_SYS_RAWIO";
            DeviceAllow = [ "char-cpu/msr rw" ];

            SystemCallFilter = [ "~iopl ioperm" ];

            # Keep private files writable
            ReadWritePaths = [
              "/var/lib/xmrig-cpu"
              runtimeDir
            ];

            ReadOnlyPaths = [ configFile ];
          };
        }
      );
    };
}
