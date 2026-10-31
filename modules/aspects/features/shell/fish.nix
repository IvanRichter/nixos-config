{ den, ... }:

{
  den.aspects.fish.homeManager =
    { pkgs, ... }:

    {
      programs.fish = {
        enable = true;

        plugins = [
          {
            name = "async-prompt";
            src = pkgs.fishPlugins.async-prompt.src;
          }
          {
            name = "puffer";
            src = pkgs.fishPlugins.puffer.src;
          }
        ];

        functions = {
          fish_greeting = "";

          fish_user_key_bindings = ''
            bind ctrl-left backward-word
            bind ctrl-right forward-word
          '';

          gpf = {
            description = "Force-push a branch with lease and inclusion checks";
            body = ''
              argparse 'h/help' -- $argv; or return 2
              set -l usage 'Usage: gpf [REMOTE [BRANCH]]'
              if set -q _flag_help
                echo "$usage"
                return 0
              end
              if test (count $argv) -gt 2
                echo "$usage" >&2
                return 2
              end

              set -l remote origin
              if set -q argv[1]
                set remote "$argv[1]"
              end

              set -l branch
              if set -q argv[2]
                set branch "$argv[2]"
              else
                set branch (git symbolic-ref --quiet --short HEAD)
                or begin
                  echo 'Check out a local branch or pass its name explicitly' >&2
                  return 1
                end
              end
              git check-ref-format "refs/heads/$branch"; or return 2

              # Keep matching branch names and omit an expected SHA for the inclusion check
              git push --force-with-lease="refs/heads/$branch" --force-if-includes \
                -- "$remote" "refs/heads/$branch:refs/heads/$branch"
            '';
          };

          ghmerge = {
            description = "Squash-merge a PR while preserving authorship and sign-off trailers";
            body = ''
              argparse 'h/help' 'b/body=' 'bypass' -- $argv; or return 2
              set -l usage 'Usage: ghmerge PR_NUMBER [--body TEXT] [--bypass]'
              if set -q _flag_help
                echo "$usage"
                return 0
              end
              if test (count $argv) -ne 1; or not string match -rq '^[1-9][0-9]*$' -- $argv[1]
                echo "$usage" >&2
                return 2
              end

              set -l jq ${pkgs.jq}/bin/jq
              set -l repo (gh repo view --json nameWithOwner --jq .nameWithOwner); or return 1
              set -l pr (gh api "repos/$repo/pulls/$argv[1]"); or return 1
              if not printf '%s' "$pr" | $jq -e '.stack == null or .base.ref == .stack.base.ref' >/dev/null
                echo 'Merge the lowest unmerged PR in the stack first' >&2
                return 1
              end
              if not printf '%s' "$pr" | $jq -e '.state == "open" and .draft == false' >/dev/null
                echo 'The PR must be open and ready for review.' >&2
                return 1
              end

              set -l author_id (printf '%s' "$pr" | $jq -r .user.id)
              set -l title (printf '%s' "$pr" | $jq -r '.title + " (#" + (.number | tostring) + ")"')
              set -l sha (printf '%s' "$pr" | $jq -r .head.sha)
              set -l count (printf '%s' "$pr" | $jq -r .commits)
              set -l commits (gh api --paginate --slurp "repos/$repo/pulls/$argv[1]/commits?per_page=100"); or return 1
              if not printf '%s' "$commits" | $jq -e --arg sha "$sha" --argjson count "$count" \
                'add | length == $count and .[-1].sha == $sha' >/dev/null
                echo 'The PR changed or its complete commit list could not be read. Refresh and retry.' >&2
                return 1
              end

              # Preserve existing trailers without adding sign-offs
              set -l trailers
              for message in (printf '%s' "$commits" | $jq -j '.[][] | .commit.message, "\u0000"' | string split0)
                set -a trailers (printf '%s' "$message" | git interpret-trailers --parse); or return 1
              end

              # Credit commit authors other than the PR author
              set -a trailers (printf '%s' "$commits" | $jq -r --argjson author "$author_id" \
                '.[][] | select(.author == null or .author.id != $author) | .commit.author | "Co-authored-by: \(.name) <\(.email)>"')
              set -l footer (printf '%s\n' $trailers \
                | string match -ri '^(?:Co-authored-by|Signed-off-by):.*' \
                | string replace -ri '^co-authored-by:\s*' 'Co-authored-by: ' \
                | string replace -ri '^signed-off-by:\s*' 'Signed-off-by: ' \
                | ${pkgs.gawk}/bin/awk '!seen[$0]++' \
                | string collect --allow-empty)

              set -l body "$footer"
              if test -n "$_flag_body"
                set body (printf '%s\n\n%s' "$_flag_body" "$footer" | string collect)
              end
              set -l message (printf '%s\n\n%s' "$title" "$body" | string collect)

              set -l bypass false
              if set -q _flag_bypass
                set bypass true
              end

              set -l endpoint "repos/$repo/pulls/$argv[1]/merge-async"
              set -l result (gh api --method PUT "$endpoint" \
                -f merge_method=squash \
                -f merge_action=direct_merge \
                -F "bypass_rules=$bypass" \
                -f "sha=$sha" \
                -f "commit_title=$title" \
                -f "commit_message=$body")
              or begin
                echo "Could not confirm the merge request for #$argv[1]; check its status on GitHub before retrying" >&2
                return 1
              end

              set -l uuid (printf '%s' "$result" | $jq -r .details.uuid)
              for attempt in (seq 60)
                if test (printf '%s' "$result" | $jq -r .status) != pending
                  break
                end
                sleep 2
                set -l polled (gh api "$endpoint/$uuid"); or break
                set result "$polled"
              end
              switch (printf '%s' "$result" | $jq -r .status)
                case merged
                case failed
                  printf 'Merge failed: %s\n' (printf '%s' "$result" | $jq -r .details.message) >&2
                  return 1
                case '*'
                  echo "Stopped waiting for #$argv[1]; GitHub may still complete the merge" >&2
                  echo "Check: gh pr view $argv[1] --repo $repo" >&2
                  return 1
              end

              set -l merged_sha (printf '%s' "$result" | $jq -r .details.sha)
              echo "Merged #$argv[1] as $merged_sha"
              if not gh api "repos/$repo/commits/$merged_sha" | $jq -e --arg message "$message" --argjson author "$author_id" \
                '.author.id == $author and .commit.message == $message and .commit.verification.verified == true' >/dev/null
                echo 'Merge succeeded, but could not verify the author, message and signature' >&2
                return 1
              end
              echo 'Verified the squash author, message and commit signature'
            '';
          };

          clippy-pedantic = {
            description = "Run workspace-wide pedantic Clippy in a temporary target directory";
            body = ''
              set -l tmp (mktemp -d); or return 1

              env CARGO_TARGET_DIR="$tmp/target" \
                cargo clippy \
                  --workspace \
                  --all-targets \
                  --all-features \
                  --locked \
                  -- \
                  -W clippy::pedantic
              set -l code $status

              rm -r -- "$tmp"
              return $code
            '';
          };

          clippy-nursery = {
            description = "Run workspace-wide nursery Clippy in a temporary target directory";
            body = ''
              set -l tmp (mktemp -d); or return 1

              env CARGO_TARGET_DIR="$tmp/target" \
                cargo clippy \
                  --workspace \
                  --all-targets \
                  --all-features \
                  --locked \
                  -- \
                  -W clippy::nursery
              set -l code $status

              rm -r -- "$tmp"
              return $code
            '';
          };

          clippy-restriction = {
            description = "Run workspace-wide restriction Clippy in a temporary target directory";
            body = ''
              set -l tmp (mktemp -d); or return 1

              env CARGO_TARGET_DIR="$tmp/target" \
                cargo clippy \
                  --workspace \
                  --all-targets \
                  --all-features \
                  --locked \
                  -- \
                  -W clippy::restriction
              set -l code $status

              rm -r -- "$tmp"
              return $code
            '';
          };

          gibbor-update = {
            description = "Refresh the local Gibbor source checkout";
            body = ''
              set -l target /home/ivan/work/happy-end/gibbor-src
              set -l tmp (mktemp -d); or return 1
              set -l code 0

              scp -P 62884 richter@www.gibbor.eu:~/gibbor_source.tgz "$tmp/gibbor_source.tgz"; and \
                mkdir "$tmp/extract"; and \
                tar -xzf "$tmp/gibbor_source.tgz" -C "$tmp/extract"; and \
                rm -rf "$target"; and \
                mkdir -p "$target"
              set code $status

              if test $code -ne 0
                rm -rf "$tmp"
                return $code
              end

              set -l source "$tmp/extract"
              set -l entries "$source"/*
              if test (count $entries) -eq 1; and test -d "$entries[1]"
                set source "$entries[1]"
              end

              cp -a "$source/." "$target"/
              set code $status
              rm -rf "$tmp"
              return $code
            '';
          };
        };

        shellAliases = {
          g = "git";
          gst = "git status";
          gss = "git status --short";
          gd = "git diff";
          gds = "git diff --staged";
          ga = "git add";
          gc = "git commit --signoff";
          gb = "git branch";
          gsw = "git switch";
          gswc = "git switch -c";
          gf = "git fetch";
          gl = "git pull --ff-only";
          gp = "git push";
          glog = "git log --oneline --decorate --graph";
          gdeploy = "gh workflow run deploy.yaml --ref main";

          pbcopy = "wl-copy";
          pbpaste = "wl-paste";
          neofetch = "macchina";
          cat = "bat -pp";
          grep = "rg --no-heading --color=auto";
          find = "fd";
          top = "btm";
          dig = "doggo";
          jq = "jaq";
          du = "dust";
          nano = "micro";
          torrent = "xdg-open http://localhost:3030/web/";
        };
      };

      programs.eza = {
        enable = true;
        enableFishIntegration = true;
        extraOptions = [ "--group-directories-first" ];
      };

      programs.vivid = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = [
          "--cmd"
          "cd"
        ];
      };

      programs.nix-your-shell = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.direnv = {
        enable = true;
        enableFishIntegration = true;
        nix-direnv.enable = true;
      };
    };
}
