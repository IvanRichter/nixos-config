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
          if (( $# > 1 )); then echo "Usage: mine-setup [--help]" >&2; exit 2; fi
          case "''${1:-}" in
            --help|-h)
              echo "Usage: mine-setup"
              echo "Edit a private copy in Micro and install it after a non-mining check."
              exit 0
              ;;
            "") ;;
            *) echo "Usage: mine-setup [--help]" >&2; exit 2 ;;
          esac
          if [[ ! -t 0 || ! -t 1 ]]; then
            echo "Run mine-setup in an interactive terminal." >&2
            exit 1
          fi

          account=$(id -un)
          if [[ $account != xmrig-cpu ]]; then
            runtime_dir=''${XDG_RUNTIME_DIR:-/run/user/$UID}
            if [[ ! -d $runtime_dir || ! -O $runtime_dir ]]; then
              echo "Run mine-setup from desktop login." >&2
              exit 1
            fi
            umask 077
            exec 9>"$runtime_dir/xmrig-cpu.lock"
            flock --exclusive 9
          fi
          for mode in normal hard; do
            case "$(systemctl show "xmrig-cpu-$mode.service" --property=ActiveState --value)" in
              inactive|failed) ;;
              *) echo "Run mine stop before editing the configuration." >&2; exit 1 ;;
            esac
          done
          if [[ $account != xmrig-cpu ]]; then
            # Keep the lock in the caller while sudo closes inherited descriptors
            /run/wrappers/bin/sudo -u xmrig-cpu -- "$0" 9>&-
            exit
          fi

          if [[ ! -d /var/lib/xmrig-cpu || ! -w /var/lib/xmrig-cpu ]]; then
            echo "Rebuild the desktop configuration to prepare /var/lib/xmrig-cpu." >&2
            exit 1
          fi
          if [[ -L ${configFile} || ( -e ${configFile} && ! -f ${configFile} ) ]]; then
            echo "Expected a regular file at ${configFile}." >&2
            exit 1
          fi
          umask 077
          chmod 0700 /var/lib/xmrig-cpu
          edit_dir=$(mktemp -d /var/lib/xmrig-cpu/.edit.XXXXXX)
          trap 'rm -rf -- "$edit_dir"' EXIT
          trap 'exit 130' INT
          trap 'exit 143' TERM
          trap 'exit 129' HUP
          candidate="$edit_dir/config.json"
          if [[ -e ${configFile} ]]; then
            cp -- ${configFile} "$candidate"
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
          echo "Set pools[0].user to the Monero receiving address."
          ${lib.getExe pkgs.micro} "$candidate"
          ${lib.getExe checkConfig} "$candidate"
          chmod 0600 "$candidate"
          mv -T -- "$candidate" ${configFile}
          echo "Configuration checked. Run mine to start mining."
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
          # shellcheck shell=bash

          requested_mode=normal
          config_file=/var/lib/xmrig-cpu/config.json
          owned=""
          owned_unit=""
          owned_session=""
          follower=""
          locked=0
          interrupted=0

          usage() {
            cat <<'HELP'
          Usage: mine [hard|slow|stop|logs|--help]
            mine       Normal mode: up to 16 workers on 8 cores, 4 initialization threads.
            hard       All available CPUs.
            slow       Switch running mining back to normal mode.
            stop       Stop either mode.
            logs       Observe output. Ctrl+C only closes this observer.
          Run mine-setup to create or edit the local configuration.
          Normal mode starts in the background at boot.
          Normal mode gets promoted to hard after 1 hour idle and goes back to normal on activity.
          Manually started hard mode stays hard until mine slow or mine stop.
          INT, TERM and HUP stop an owned session. After SIGKILL, recover with mine stop.
          HELP
          }

          read_state() {
            local properties key value
            properties=$(systemctl show "$unit" --property=LoadState,ActiveState,SubState,InvocationID,Result,ConditionResult) || return
            state="" invocation="" result="" condition="" substate="" load=""
            while IFS='=' read -r key value; do
              case "$key" in
                LoadState) load=$value ;;
                ActiveState) state=$value ;;
                SubState) substate=$value ;;
                InvocationID) invocation=$value ;;
                Result) result=$value ;;
                ConditionResult) condition=$value ;;
              esac
            done <<<"$properties"
            if [[ $load != loaded || -z $state ]]; then
              echo "$unit is unavailable. Rebuild the desktop configuration first." >&2
              return 1
            fi
          }

          running() {
            [[ $state == active || $state == activating || $state == reloading || $state == deactivating ]]
          }

          find_session() {
            local candidate active="" failed=""
            for candidate in normal hard; do
              unit="xmrig-cpu-$candidate.service"
              read_state
              if running; then
                if [[ -n $active ]]; then
                  echo "Both mining modes are active. Inspect systemctl status 'xmrig-cpu-*.service'." >&2
                  return 1
                fi
                active=$unit
              elif [[ $state == failed && -z $failed ]]; then
                failed=$unit
              fi
            done
            if [[ -z $active && $command == logs ]]; then
              active=$failed
            fi
            unit=''${active:-$requested_unit}
            mode=''${unit#xmrig-cpu-}
            mode=''${mode%.service}
            read_state
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
            session_id="" session_unit="" session_invocation="" session_origin=""
            local extra=""
            [[ -f $session_file && ! -L $session_file ]] || return 1
            read -r session_id session_unit session_invocation session_origin extra <"$session_file" || return 1
            [[ $session_id =~ ^[0-9a-f]{32}$ && $session_invocation =~ ^[0-9a-f]{32}$ && -z $extra ]] || return 1
            [[ $session_unit == xmrig-cpu-normal.service || $session_unit == xmrig-cpu-hard.service ]] || return 1
            [[ $session_origin == manual || $session_origin == idle ]]
          }

          save_session() {
            local temporary
            temporary=$(mktemp "$runtime_dir/.xmrig-session.XXXXXX")
            printf '%s %s %s %s\n' "$1" "$unit" "$invocation" "$2" >"$temporary"
            mv -T -- "$temporary" "$session_file"
          }

          clear_session() {
            if read_session && [[ $session_unit == "$1" && $session_invocation == "$2" ]]; then
              rm -f -- "$session_file" "$runtime_dir/xmrig-cpu-idle/promotion"
            fi
          }

          run_job() {
            local job rc=0
            (
              trap "" INT TERM HUP
              exec systemctl --no-ask-password "$1" "$unit"
            ) 9>&- &
            job=$!
            while true; do
              if wait "$job"; then rc=0; break; else rc=$?; fi
              if ! kill -0 "$job" 2>/dev/null; then break; fi
            done
            return "$rc"
          }

          stop_service() {
            local stopped_unit=$unit stopped_invocation=$invocation
            systemctl --no-ask-password stop "$unit" || return
            read_state || return
            if running; then
              echo "Mining has not stopped ($state/$substate). Inspect mine logs." >&2
              return 1
            fi
            clear_session "$stopped_unit" "$stopped_invocation"
            echo "Mining stopped."
          }

          stop_follower() {
            if [[ -n $follower ]]; then
              # The journal observer must not delay graceful miner shutdown
              kill -KILL "$follower" 2>/dev/null || true
              wait "$follower" 2>/dev/null || true
              follower=""
            fi
          }

          adopt_session() {
            local previous_unit=$unit
            if read_session && [[ $session_id == "$1" ]]; then
              unit=$session_unit
              read_state || return
              if [[ $invocation == "$session_invocation" ]]; then
                mode=''${unit#xmrig-cpu-}
                mode=''${mode%.service}
                if [[ -n $owned_session && $session_id == "$owned_session" ]]; then
                  owned_unit=$unit
                  owned=$invocation
                fi
                return
              fi
            fi
            unit=$previous_unit
            read_state
          }

          cleanup() {
            local rc=$?
            trap - EXIT
            trap "" INT TERM HUP
            stop_follower
            if [[ -n $owned ]]; then
              if ((! locked)); then lock; fi
              unit=$owned_unit
              if ! adopt_session "$owned_session"; then rc=1; fi
              if read_state; then
                # Check and stop under the same lock used by every mine start/stop
                if [[ $invocation == "$owned" ]] && running; then
                  if ! stop_service; then
                    echo "Could not stop the owned session. Run mine stop." >&2
                    rc=1
                  fi
                else
                  clear_session "$owned_unit" "$owned"
                fi
              else
                echo "Could not inspect the owned session. Run mine stop." >&2
                rc=1
              fi
            fi
            exit "$rc"
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

          follow_session() {
            local session=$1 lines=$2 logical=$1 previous_unit=$unit
            if read_session && [[ $session_unit == "$unit" && $session_invocation == "$session" ]]; then
              logical=$session_id
            fi
            echo "Journal output only: use mine commands and owner Ctrl+C, XMRig h/p/r keys are not forwarded."
            while true; do
              lock
              adopt_session "$logical"
              if read_session && [[ $session_id == "$logical" && $session_unit == "$unit" && $session_invocation == "$invocation" ]]; then
                if [[ $unit != "$previous_unit" || $invocation != "$session" ]]; then
                  stop_follower
                  session=$invocation
                  previous_unit=$unit
                  lines=all
                  echo "Mining switched to $mode mode."
                fi
              fi
              unlock
              if [[ -n $invocation && $invocation != "$session" ]]; then
                echo "This mining session ended; a replacement session is left untouched."
                return
              fi
              if ! running; then
                if [[ $state == failed || $result != success ]]; then
                  echo "Mining failed ($result). Inspect mine logs." >&2
                  journalctl --quiet --no-pager --output=cat -n 20 "_SYSTEMD_INVOCATION_ID=$session"
                  return 1
                fi
                echo "Mining stopped."
                return
              fi
              if [[ -z $invocation ]]; then
                echo "This mining session ended."
                return
              fi
              if [[ -z $follower ]]; then
                # Record the follower before acting on a pending signal
                defer_signals
                journalctl --quiet --no-pager --output=cat --lines="$lines" --follow \
                  "_SYSTEMD_INVOCATION_ID=$session" 9>&- &
                follower=$!
                resume_signals
              elif ! kill -0 "$follower" 2>/dev/null; then
                echo "The journal follower ended unexpectedly." >&2
                return 1
              fi
              sleep 1
            done
          }

          switch_mode() {
            local target=$1 origin=$2 token=$invocation rc=0
            local ticket="$runtime_dir/xmrig-cpu-idle/promotion"
            if read_session && [[ $session_unit == "$unit" && $session_invocation == "$invocation" ]]; then
              token=$session_id
            fi
            defer_signals
            run_job stop || return 1
            read_state
            if running; then return 1; fi
            unit="xmrig-cpu-$target.service"
            run_job start || rc=$?
            read_state
            if [[ -n $invocation ]]; then
              save_session "$token" "$origin"
            else
              rm -f -- "$session_file"
            fi
            if [[ $state == active && $origin == idle ]]; then
              printf '%s %s\n' "$token" "$invocation" >"$ticket"
            else
              rm -f -- "$ticket"
            fi
            resume_signals
            if ((rc)) || [[ $state != active ]]; then
              echo "Transition to $target failed; inspect mine logs." >&2
              return 1
            fi
            echo "Mining switched to $target mode."
          }

          idle_transition() {
            local expected_unit expected_invocation target origin ticket ticket_session ticket_invocation
            ticket=''${MINE_IDLE_TICKET:-$runtime_dir/xmrig-cpu-idle/promotion}
            [[ $ticket == "$runtime_dir/xmrig-cpu-idle/promotion" && -d ''${ticket%/*} ]] || return 0
            find_session
            [[ $state == active && -n $invocation ]] || return 0
            expected_unit=$unit
            expected_invocation=$invocation
            lock
            unit=$expected_unit
            read_state
            [[ $state == active && $invocation == "$expected_invocation" ]] || return 0
            if ! read_session || [[ $session_unit != "$unit" || $session_invocation != "$invocation" ]]; then
              # Boot-started normal mining has no foreground session marker
              [[ $command == idle-hard && $unit == xmrig-cpu-normal.service ]] || return 0
              session_origin=manual
            fi
            if [[ $command == idle-hard ]]; then
              if [[ $unit == xmrig-cpu-hard.service && $session_origin == idle ]]; then
                printf '%s %s\n' "$session_id" "$invocation" >"$ticket"
                return 0
              fi
              [[ $unit == xmrig-cpu-normal.service && $session_origin == manual ]] || return 0
              target=hard origin=idle
            else
              [[ $unit == xmrig-cpu-hard.service && $session_origin == idle && -f $ticket ]] || return 0
              read -r ticket_session ticket_invocation <"$ticket" || return 0
              [[ $ticket_session == "$session_id" && $ticket_invocation == "$invocation" ]] || return 0
              target=normal origin=manual
            fi
            switch_mode "$target" "$origin"
          }

          offer_stop() {
            local prompted=$invocation prompted_unit=$unit answer

            if ((locked)); then
              unlock
            fi

            if [[ ! -t 0 || ! -t 1 ]]; then
              echo "Mining is already running in $mode mode ($state). Use mine stop to stop it." >&2
              exit 1
            fi

            printf 'Mining is already running in %s mode. Stop it? [y/N] ' "$mode"
            answer=""

            if ! read -r answer; then
              printf '\n'
              exit 0
            fi

            if [[ $answer != [yY] ]]; then
              echo "Mining left running."
              exit 0
            fi

            lock
            unit=$prompted_unit
            read_state

            if [[ $invocation != "$prompted" ]]; then
              echo "The session changed; leaving the replacement untouched."
            elif running; then
              stop_service
            else
              echo "Mining is already stopped ($state)."
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
            hard) requested_mode=hard; command=start ;;
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
          if [[ $command == idle-hard || $command == idle-resume ]]; then
            idle_transition
            exit
          fi
          find_session

          if [[ $command == logs ]]; then
            if running && [[ -n $invocation ]]; then
              follow_session "$invocation" 30
            else
              journalctl --quiet --no-pager --output=cat --unit=xmrig-cpu-normal.service --unit=xmrig-cpu-hard.service -n 30
            fi
            exit 0
          fi

          case "$command:$state" in
            start:active | start:activating | start:reloading) offer_stop ;;
          esac
          lock
          find_session

          if [[ $command == stop ]]; then
            if running; then stop_service; else echo "Mining is already stopped ($state)."; fi
            rm -f -- "$session_file" "$runtime_dir/xmrig-cpu-idle/promotion"
            exit 0
          fi

          if [[ $command == slow ]]; then
            case "$state" in
              active)
                if [[ $mode == normal ]]; then
                  rm -f -- "$runtime_dir/xmrig-cpu-idle/promotion"
                  echo "Mining is already in normal mode."
                else
                  switch_mode normal manual
                fi
                ;;
              inactive | failed) echo "Mining is stopped. Run mine to start it." ;;
              *) echo "Mining is $state. Wait for the transition to finish." >&2; exit 1 ;;
            esac
            exit 0
          fi

          case "$state" in
            active | activating | reloading)
              offer_stop
              ;;
            deactivating)
              echo "Mining is stopping. Wait for shutdown before starting another session."
              exit 1
              ;;
            inactive | failed) ;;
            *)
              echo "Cannot start mining in state $state." >&2
              exit 1
              ;;
          esac

          previous=$invocation
          defer_signals
          # Let the bounded systemd start job settle even if terminal is interrupted
          start_rc=0
          run_job start || start_rc=$?
          read_state
          if [[ -n $invocation && $invocation != "$previous" ]]; then
            owned=$invocation
            owned_unit=$unit
            owned_session=$invocation
            save_session "$owned_session" manual
            rm -f -- "$runtime_dir/xmrig-cpu-idle/promotion"
          fi
          resume_signals

          if ((start_rc != 0)) || [[ $state != active || -z $owned ]]; then
            if [[ $condition == no ]]; then
              echo "Mining did not start. Create $config_file (xmrig-cpu:xmrig-cpu, mode 0600) first." >&2
            else
              echo "Mining did not start ($state/$substate, result: $result). Check $config_file and mine logs." >&2
              if [[ -n $owned ]]; then
                journalctl --quiet --no-pager --output=cat --lines=all "_SYSTEMD_INVOCATION_ID=$owned"
              fi
            fi
            exit 1
          fi
          unlock
          echo "Mining started in $mode mode. Ctrl+C to stop."
          follow_session "$owned" all
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
    in
    {
      environment.systemPackages = [
        mine
        mineSetup
      ];

      users.groups.xmrig-cpu.gid = 492;
      users.users.xmrig-cpu = {
        isSystemUser = true;
        group = "xmrig-cpu";
      };

      # Provision before the first start, even when ConditionPathExists skips it
      systemd.tmpfiles.rules = [
        "d /var/lib/xmrig-cpu 0700 xmrig-cpu xmrig-cpu -"

        # Fixes metadata only if the config already exists
        "z ${configFile} 0600 xmrig-cpu xmrig-cpu -"
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
      services.system76-scheduler.exceptions = [ ''"${lib.getExe pkgs.xmrig}"'' ];

      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.user === "ivan" &&
              action.id === "org.freedesktop.systemd1.manage-units" &&
              (action.lookup("unit") === "xmrig-cpu-normal.service" ||
               action.lookup("unit") === "xmrig-cpu-hard.service") &&
              (action.lookup("verb") === "start" || action.lookup("verb") === "stop")) {
            return polkit.Result.YES;
          }
        });
      '';

      systemd.services = lib.genAttrs [ "xmrig-cpu-normal" "xmrig-cpu-hard" ] (
        name:
        let
          mode = lib.removePrefix "xmrig-cpu-" name;
          other = if mode == "normal" then "hard" else "normal";
          runtimeDir = "/run/${name}";
          effectiveFile = "${runtimeDir}/config.json";
        in
        {
          description = "Monero CPU mining (${mode})";
          wantedBy = lib.optional (mode == "normal") "multi-user.target";
          conflicts = [ "xmrig-cpu-${other}.service" ];

          # Make systemd finish stopping one mode before starting the other
          before = lib.optional (mode == "normal") "xmrig-cpu-hard.service";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];

          # Do not restart an active service on rebuild
          restartIfChanged = false;
          unitConfig = {
            ConditionPathExists = configFile;
          };
          serviceConfig = {
            Type = "exec";
            User = "xmrig-cpu";
            Group = "xmrig-cpu";
            UMask = "0077";
            WorkingDirectory = "/var/lib/xmrig-cpu";
            RuntimeDirectory = name;
            RuntimeDirectoryMode = "0700";
            ExecStartPre = [
              "${lib.getExe prepareConfig} ${mode}"
              "${lib.getExe checkConfig} ${effectiveFile}"
            ];
            ExecStart = "${lib.getExe pkgs.xmrig} --config=${effectiveFile}";
            Restart = "no";
            TimeoutStartSec = 30;
            TimeoutStopSec = 30;
            KillSignal = "SIGTERM";
            KillMode = "control-group";
            StandardOutput = "journal";
            StandardError = "journal";
            Nice = 19;
            CPUWeight = 10;
            LimitMEMLOCK = "4G";
            NoNewPrivileges = true;

            # Linux msr_open requires RAWIO and device perms
            CapabilityBoundingSet = "CAP_SYS_RAWIO";
            AmbientCapabilities = "CAP_SYS_RAWIO";
            PrivateTmp = true;
            PrivateDevices = false;
            DevicePolicy = "closed";
            DeviceAllow = [ "char-cpu/msr rw" ];

            SystemCallFilter = [ "~iopl ioperm" ];
            ProtectHome = true;
            ProtectSystem = "strict";

            # Keep private files writable
            ReadWritePaths = [
              "/var/lib/xmrig-cpu"
              runtimeDir
            ];

            ReadOnlyPaths = [ configFile ];
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            RestrictRealtime = true;
            LockPersonality = true;
            SystemCallArchitectures = "native";

            # RandomX JIT needs executable writable memory
            MemoryDenyWriteExecute = false;
          };
        }
      );
    };
}
