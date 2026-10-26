{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
      nixpkgs-ruby,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.permittedInsecurePackages = [
            "google-chrome-144.0.7559.97"
          ];
          overlays = [ nixpkgs-ruby.overlays.default ];
        };

        rubyVersion = builtins.head (builtins.split "\n" (builtins.readFile ./.ruby-version));
        ruby = pkgs."ruby-${rubyVersion}";

        chrome = pkgs.writeShellScriptBin "chrome" ''
          binary=$(find ${pkgs.google-chrome.outPath} -type f -name 'google-chrome-stable')
          exec $binary "$@"
        '';

        postgresql = pkgs.postgresql_18;
        pgConfig = postgresql.pg_config;

        postgresqlBuildFlags = [
          "--with-pg-config=${pgConfig}/bin/pg_config"
        ];
        psychBuildFlags = with pkgs; [
          "--with-libyaml-include=${libyaml.dev}/include"
          "--with-libyaml-lib=${libyaml.out}/lib"
        ];
        zlibBuildFlags = with pkgs; [
          "--with-zlib-include=${zlib.dev}/include"
          "--with-zlib-lib=${zlib.out}/lib"
        ];

        # Worktree isolation hook (same pattern as backend)
        # Disable Git fsmonitor for hook-local probes. If these git commands start
        # fsmonitor--daemon inside direnv's shellHook, the daemon can inherit a
        # nix-direnv pipe and keep the first `direnv exec ...` blocked after setup.
        worktree = rec {
          isWorktree = ''
            if git -c core.fsmonitor=false rev-parse --is-inside-work-tree >/dev/null 2>&1; then
              if [ "$(git -c core.fsmonitor=false rev-parse --git-dir 2>/dev/null)" != "$(git -c core.fsmonitor=false rev-parse --git-common-dir 2>/dev/null)" ]; then
                echo "true"
              else
                echo "false"
              fi
            else
              echo "false"
            fi
          '';

          id = ''
            if [ "$(${isWorktree})" = "true" ]; then
              git -c core.fsmonitor=false rev-parse --show-toplevel | md5sum | cut -c1-8
            else
              echo "main"
            fi
          '';
        };

        pg-environment-variables = ''
          if [ "$(${worktree.isWorktree})" = "true" ]; then
            WT_ID=$(${worktree.id})
            export PGHOST="/tmp/pg-$WT_ID"
            export PGDATA="$HOME/.local/share/postgres/worktrees/$WT_ID"
            mkdir -p "$PGHOST" "$PGDATA"
          else
            export PGDATA=$PWD/.nix/postgres/data
            export PGHOST=$PWD/.nix/postgres
            export PGPORT=5432
          fi
          export DB_USER=""
        '';

        postgresql-start = pkgs.writeShellScriptBin "pg-start" ''
          ${pg-environment-variables}

          if [ ! -f "$PGDATA/PG_VERSION" ]; then
            mkdir -p "$PGDATA"
            ${postgresql}/bin/initdb "$PGDATA" --auth=trust
          fi

          ${postgresql}/bin/postgres -k "$PGHOST" -c listen_addresses=''' -c unix_socket_directories="$PGHOST"
        '';

        worktree-info = pkgs.writeShellScriptBin "worktree-info" ''
          if [ "$(${worktree.isWorktree})" = "true" ]; then
            WT_ID=$(${worktree.id})
            echo "Worktree mode enabled"
            echo "  ID:          $WT_ID"
            echo "  PGHOST:      /tmp/pg-$WT_ID"
            echo "  PGDATA:      $HOME/.local/share/postgres/worktrees/$WT_ID"
          else
            echo "Normal checkout (not a worktree)"
          fi
        '';

        worktree-clean = pkgs.writeShellScriptBin "worktree-clean" ''
          set -euo pipefail
          if [ "$(${worktree.isWorktree})" != "true" ]; then
            echo "Not inside a worktree. Nothing to clean."
            exit 0
          fi

          WT_ID=$(${worktree.id})
          echo "Cleaning worktree $WT_ID..."

          PGDATA="$HOME/.local/share/postgres/worktrees/$WT_ID"
          PGHOST="/tmp/pg-$WT_ID"
          PIDFILE="/tmp/pg-$WT_ID.pid"

          # Stop the daemonised Postgres for this worktree before removing its data.
          if [ -f "$PGDATA/postmaster.pid" ] || [ -f "$PIDFILE" ]; then
            echo "    Stopping Postgres..."
            ${postgresql}/bin/pg_ctl stop -D "$PGDATA" -s -m fast || true
          fi

          rm -f "$PIDFILE"

          rm -rf "$PGHOST"
          rm -rf "$PGDATA"
          rm -rf ".bundle"
          rm -rf "$HOME/.local/share/gem/worktrees/$WT_ID" 2>/dev/null || true
          rm -rf "$HOME/.cache/bundle/worktrees/$WT_ID" 2>/dev/null || true

          # Per-worktree Yarn cache + generated assets
          rm -rf "$HOME/.local/share/yarn/worktrees/$WT_ID"
          rm -rf public/packs public/packs-test 2>/dev/null || true
          bundle exec rails assets:clobber

          rm -f "$HOME/.local/share/postgres/worktrees/$WT_ID/.worktree-initialized" 2>/dev/null || true

          echo "Worktree $WT_ID cleaned (Postgres + bundle + yarn + packs)."
        '';

        lint = pkgs.writeShellScriptBin "lint" ''
          mapfile -t changed_files < <(git diff --name-only --diff-filter=ACM --merge-base main)

          if [ ''${#changed_files[@]} -eq 0 ]; then
            echo "No changed files to lint."
            exit 0
          fi

          pre-commit run --files "''${changed_files[@]}"
        '';
        update-providers = pkgs.writeShellScriptBin "update-providers" ''
          cd terraform
          terraform init -backend=false -reconfigure -upgrade
        '';

        init = pkgs.writeShellScriptBin "init" ''
          cd terraform && terraform init -input=false -no-color -backend=false
        '';

        reviewTools =
          import
            (builtins.fetchTree {
              type = "github";
              owner = "NixOS";
              repo = "nixpkgs";
              rev = "4a29d733e8a7d5b824c3d8c958a946a9867b3eb2";
              narHash = "sha256-f+JACbTqzZ+G92DSnXOUGRhGANb8Blh7CoeYOeBF8/U=";
            })
            {
              inherit system;
              config.allowUnfree = true;
            };
        reviewTerraformHooks = builtins.fetchTree {
          type = "github";
          owner = "antonbabenko";
          repo = "pre-commit-terraform";
          rev = "d61ded22bf9aa0f757303ebcbb0d6d71c4b54015";
          narHash = "sha256-IPONqvEUoGrsnQkD0RTLW28QKoKqv8wf/ooExmSTJmE=";
        };
        reviewRubyHooks = builtins.fetchTree {
          type = "github";
          owner = "mattlqx";
          repo = "pre-commit-ruby";
          rev = "1f893f2c0db4068fafa19b8ea7d7db1253ea0cc1";
          narHash = "sha256-7S84RvncmcXVIjgNhzFyN4HnKJk+tKxHYvfOLcuiw8c=";
        };
        reviewTrufflehog = reviewTools.trufflehog.overrideAttrs {
          version = "3.95.4";
          src = builtins.fetchTree {
            type = "github";
            owner = "trufflesecurity";
            repo = "trufflehog";
            rev = "d411fff7b8879a62509f3fa98c07f247ac089a51";
            narHash = "sha256-6n3gVr6+P5hWLFUAWByIYtlUkmpOmBF9Ffy5GC8awT0=";
          };
          vendorHash = "sha256-zA5CYHNhpbRhFrnjDNUV30sw+qXAJupMl7uvgOu62lU=";
        };
        reviewPreCommitConfig = pkgs.writeText "review-pre-commit.json" (
          builtins.toJSON {
            default_install_hook_types = [
              "pre-commit"
              "pre-push"
            ];
            default_stages = [ "pre-commit" ];
            repos = [
              {
                repo = "local";
                hooks = [
                  {
                    id = "terraform_fmt";
                    name = "Terraform fmt";
                    language = "system";
                    entry = "${reviewTerraformHooks}/hooks/terraform_fmt.sh";
                    files = "\\.(tf|tofu|tfvars|(tftest|tofutest|tfmock|tfquery)\\.hcl)$";
                    exclude = "\\.terraform/.*$";
                  }
                  {
                    id = "terraform_validate";
                    name = "Terraform validate";
                    language = "system";
                    entry = "${reviewTerraformHooks}/hooks/terraform_validate.sh";
                    files = "\\.(tf|tofu|tfvars|terraform\\.lock\\.hcl)$";
                    exclude = "\\.terraform/.*$";
                    require_serial = true;
                  }
                  {
                    id = "terraform_tflint";
                    name = "Terraform validate with tflint";
                    language = "system";
                    entry = "${reviewTerraformHooks}/hooks/terraform_tflint.sh";
                    files = "\\.(tf|tofu|tfvars)$";
                    exclude = "\\.terraform/.*$";
                    require_serial = true;
                  }
                  {
                    id = "terraform_docs";
                    name = "Terraform docs";
                    language = "system";
                    entry = "${reviewTerraformHooks}/hooks/terraform_docs.sh";
                    files = "\\.(tf|tofu|terraform\\.lock\\.hcl)$";
                    exclude = "\\.terraform/.*$";
                    require_serial = true;
                    args = [
                      "--hook-config=--add-to-existing-file=true"
                      "--hook-config=--path-to-file=README.md"
                      "--hook-config=--create-file-if-not-exist=true"
                    ];
                  }
                  {
                    id = "trailing-whitespace";
                    name = "trim trailing whitespace";
                    language = "system";
                    entry = "${reviewTools.python3Packages.pre-commit-hooks}/bin/trailing-whitespace-fixer";
                    types = [ "text" ];
                    stages = [
                      "pre-commit"
                      "pre-push"
                      "manual"
                    ];
                  }
                  {
                    id = "end-of-file-fixer";
                    name = "fix end of files";
                    language = "system";
                    entry = "${reviewTools.python3Packages.pre-commit-hooks}/bin/end-of-file-fixer";
                    types = [ "text" ];
                    stages = [
                      "pre-commit"
                      "pre-push"
                      "manual"
                    ];
                  }
                  {
                    id = "check-yaml";
                    name = "check yaml";
                    language = "system";
                    entry = "${reviewTools.python3Packages.pre-commit-hooks}/bin/check-yaml";
                    types = [ "yaml" ];
                    exclude = "config/database.yml";
                  }
                  {
                    id = "trufflehog";
                    name = "TruffleHog";
                    language = "system";
                    entry = "${reviewTrufflehog}/bin/trufflehog git file://. --since-commit HEAD --results=verified --fail --trust-local-git-config";
                    pass_filenames = false;
                  }
                  {
                    id = "markdownlint-fix";
                    name = "markdownlint-fix";
                    language = "system";
                    entry = "${reviewTools.markdownlint-cli}/bin/markdownlint --fix";
                    types = [ "markdown" ];
                    args = [
                      "--ignore"
                      "terraform"
                    ];
                  }
                  {
                    id = "rubocop";
                    name = "Check Ruby style with rubocop";
                    language = "system";
                    entry = "${reviewRubyHooks}/bin/rubocop-wrapper.sh";
                    pass_filenames = true;
                    types = [ "ruby" ];
                    args = [ "--autocorrect" ];
                  }
                  {
                    id = "actionlint-docker";
                    name = "Lint GitHub Actions workflow files";
                    language = "system";
                    entry = "${reviewTools.actionlint}/bin/actionlint";
                    types = [ "yaml" ];
                    files = "^\\.github/workflows/";
                  }
                ];
              }
            ];
          }
        );

        reviewEnvironment = ''
          if [ "''${REVIEW_SANDBOX:-}" != 1 ] || [ "$PWD" != /workspace ]; then exit 64; fi
          export TMPDIR=/workspace/.review/tmp PRE_COMMIT_HOME=/workspace/.review/pre-commit
          export XDG_CACHE_HOME="$TMPDIR/cache" GEM_HOME=/workspace/.review/gems
          export GEM_PATH="$GEM_HOME''${REVIEW_GEM_CACHE:+:$REVIEW_GEM_CACHE}"
          export PATH="$GEM_HOME/bin:${
            pkgs.lib.makeBinPath [
              reviewTools.terraform
              reviewTools.terraform-docs
              reviewTools.tflint
            ]
          }:$PATH" BUNDLE_BIN="$GEM_HOME/bin"
          export BUNDLE_IGNORE_CONFIG=1 BUNDLE_PATH__SYSTEM=true BUNDLE_FROZEN=true
          export RAILS_ENV=test CI=true PARALLEL_TEST_PROCESSORS=5 PARALLEL_RSPEC_CHILD=true
          export PGDATA=/workspace/.review/postgres PGHOST=/workspace/.review/pg PGUSER=postgres DB_USER=postgres PGPORT=5432
          LD_LIBRARY_PATH="$(${pgConfig}/bin/pg_config --libdir):${pkgs.libyaml.out}/lib:${pkgs.zlib.out}/lib:${pkgs.openssl.out}/lib"
          export LD_LIBRARY_PATH
          export npm_config_ignore_scripts=true YARN_IGNORE_SCRIPTS=true YARN_OFFLINE=true YARN_CACHE_FOLDER="$TMPDIR/yarn-cache"
          export TF_CLI_CONFIG_FILE=/workspace/.review/terraform.rc TF_IN_AUTOMATION=1 TF_INPUT=0 CHECKPOINT_DISABLE=1 AWS_EC2_METADATA_DISABLED=true
          unset BUNDLE_PATH BUNDLE_APP_CONFIG BUNDLE_WITHOUT TF_PLUGIN_CACHE_DIR DATABASE_URL
          mkdir -p "$TMPDIR" "$GEM_HOME" "$PGHOST"
        '';

        preCommitCheck = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          configPath = ".pre-commit-config-nix.yaml";
          default_stages = [ "pre-commit" ];
          hooks = {
            actionlint = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            check-added-large-files = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            check-case-conflicts = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            check-merge-conflicts = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            check-yaml = {
              enable = true;
              excludes = [ "^config/database\\.yml$" ];
              stages = [ "pre-commit" ];
            };
            deadnix = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            detect-private-keys = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            end-of-file-fixer = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            nixfmt-rfc-style = {
              package = pre-commit-hooks.inputs.nixpkgs.legacyPackages.${system}.nixfmt;
              enable = true;
              stages = [ "pre-commit" ];
            };
            shellcheck = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            sort-file-contents = {
              enable = true;
              files = "^\\.env\\.(development|test)$";
              stages = [ "pre-commit" ];
            };
            statix = {
              enable = true;
              settings.ignore = [ "{.direnv,.nix,.worktrees}/**" ];
              stages = [ "pre-commit" ];
            };
            terraform-format = {
              enable = true;
              package = pkgs.terraform;
              stages = [ "pre-commit" ];
            };
            terraform-validate = {
              enable = true;
              package = pkgs.terraform;
              entry = ''
                bash -c '
                  set -uo pipefail
                  status=0

                  while read -r dir; do
                    lockfile="$dir/.terraform.lock.hcl"
                    backup=$(mktemp)
                    had_lockfile=false

                    if [ -f "$lockfile" ]; then
                      cp "$lockfile" "$backup"
                      had_lockfile=true
                    fi

                    ${pkgs.terraform}/bin/terraform -chdir="$dir" init -backend=false
                    init_status=$?

                    if [ "$init_status" -eq 0 ]; then
                      ${pkgs.terraform}/bin/terraform -chdir="$dir" validate
                      validate_status=$?
                    else
                      validate_status=$init_status
                    fi

                    if [ "$had_lockfile" = true ]; then
                      cp "$backup" "$lockfile"
                    else
                      rm -f "$lockfile"
                    fi
                    rm -f "$backup"

                    if [ "$validate_status" -ne 0 ]; then
                      status=$validate_status
                    fi
                  done < <(for arg in "$@"; do dirname "$arg"; done | sort | uniq)

                  exit "$status"
                ' --
              '';
              stages = [ "pre-commit" ];
            };
            tflint = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            trim-trailing-whitespace = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            trufflehog = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            rubocop = {
              enable = true;
              name = "rubocop";
              description = "Run RuboCop through Bundler on changed Ruby files";
              entry = ''
                bash -c '
                  changed_files=$(git diff --name-only --diff-filter=ACM --merge-base main | grep -E "\\.(rb|rake)$|^(Gemfile|Rakefile|config\\.ru)$" || true)

                  if [ -n "$changed_files" ]; then
                    bundle exec rubocop --autocorrect --force-exclusion $changed_files
                  fi
                '
              '';
              files = "\\.(rb|rake)$|^(Gemfile|Rakefile|config\\.ru)$";
              pass_filenames = false;
              stages = [ "pre-commit" ];
            };
          };
        };

        preCommit = pkgs.writeShellScriptBin "pre-commit" ''
          set -euo pipefail

          has_config=false
          for arg in "$@"; do
            case "$arg" in
              -c|--config|--config=*)
                has_config=true
                ;;
            esac
          done

          if [ "$has_config" = true ]; then
            exec ${preCommitCheck.config.package}/bin/pre-commit "$@"
          fi

          if [ "''${1:-}" = "run" ]; then
            shift
            exec ${preCommitCheck.config.package}/bin/pre-commit run --config .pre-commit-config-nix.yaml "$@"
          fi

          exec ${preCommitCheck.config.package}/bin/pre-commit "$@"
        '';

      in
      {
        devShells.review = self.devShells.${system}.default.overrideAttrs (old: {
          shellHook = "";
          nativeBuildInputs = [
            pkgs.gitMinimal
            reviewTools.pre-commit
            reviewTools.terraform
            reviewTools.terraform-docs
            reviewTools.tflint
            pkgs.jq
            pkgs.util-linux
            (pkgs.writeShellApplication {
              name = "review-bootstrap";
              text = reviewEnvironment + ''
                IFS=: read -r -a caches <<< "''${REVIEW_GEM_CACHE:-}"
                mkdir -p "$GEM_HOME/bundler" "$GEM_HOME/cache/bundler"
                for cache in "''${caches[@]}"; do
                  if [ -d "$cache/bundler" ]; then cp -an "$cache/bundler/." "$GEM_HOME/bundler/"; fi
                  if [ -d "$cache/cache/bundler" ]; then cp -an "$cache/cache/bundler/." "$GEM_HOME/cache/bundler/"; fi
                done
                for archive in /deps/gem-archives/*.gem; do
                  [ -f "$archive" ] || continue
                  gem install --local --no-document --ignore-dependencies "$archive"
                done
                bundle check || bundle install --local
                bundle binstubs --all
                printf 'yarn-offline-mirror "/deps/yarn-archives"\n' > "$TMPDIR/yarnrc"
                yarn --use-yarnrc "$TMPDIR/yarnrc" install --offline --frozen-lockfile --ignore-scripts
                initdb -D "$PGDATA" -U postgres --auth=trust --encoding=UTF8 --no-locale
                pg_ctl -D "$PGDATA" -l "$TMPDIR/postgres.log" -o "-k $PGHOST -c listen_addresses=" -w start
                pg_isready -h "$PGHOST" -U postgres
                bundle exec rails db:test:prepare_parallel
                printf 'disable_checkpoint = true\nprovider_installation {\n filesystem_mirror {\n path = "/deps/terraform-inputs/providers"\n include = ["registry.terraform.io/*/*"]\n }\n}\n' > "$TF_CLI_CONFIG_FILE"
                files="$(git ls-files '*.tf')"
                test -n "$files"
                mapfile -t roots < <(printf '%s\n' "$files" | while IFS= read -r file; do dirname "$file"; done | sort -u)
                for root in "''${roots[@]}"; do
                  mkdir -p "$root/.terraform/modules"
                  if [ -f "/deps/terraform-inputs/roots/$root/modules.json" ]; then cp "/deps/terraform-inputs/roots/$root/modules.json" "$root/.terraform/modules/modules.json"; fi
                  if [ ! -f "$root/.terraform.lock.hcl" ]; then cp "/deps/terraform-inputs/roots/$root/lock.hcl" "$root/.terraform.lock.hcl"; fi
                  terraform -chdir="$root" init -backend=false -input=false -lockfile=readonly -no-color
                done
              '';
            })
            (pkgs.writeShellApplication {
              name = "review-check";
              text = reviewEnvironment + ''
                status=0
                pre-commit run --all-files --config ${reviewPreCommitConfig} || status=$?
                pre-commit run --all-files --hook-stage pre-push --config ${reviewPreCommitConfig} || status=$?
                bundle exec brakeman || status=$?
                yarn test || status=$?
                bin/rails assets:precompile || status=$?
                bundle exec parallel_test -n 5 --type rspec --serialize-stdout spec 2>&1 | tee "$TMPDIR/unit.log" || status=$?
                ruby -e 'r = File.read(ARGV[0]).scan(/(\d+) examples?, (\d+) failures?(?:, (\d+) pending)?/); abort "Unit tests failed or skipped" unless r.any? { |x| x[0].to_i.positive? } && r.all? { |x| x[1].to_i.zero? && x[2].to_i.zero? }' "$TMPDIR/unit.log" || status=$?
                exit "$status"
              '';
            })
          ]
          ++ (old.nativeBuildInputs or [ ]);
          BUNDLE_BUILD__PG = builtins.concatStringsSep " " postgresqlBuildFlags;
          BUNDLE_BUILD__PSYCH = builtins.concatStringsSep " " psychBuildFlags;
          BUNDLE_BUILD__ZLIB = builtins.concatStringsSep " " zlibBuildFlags;
          BROWSER_PATH = pkgs.writeShellScript "review-chrome" ''
            if [ "''${REVIEW_SANDBOX:-}" != 1 ]; then exit 64; fi
            exec ${pkgs.google-chrome}/bin/google-chrome-stable --no-sandbox "$@"
          '';
          FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; };
          TZDIR = "${pkgs.tzdata.outPath}/share/zoneinfo";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        });

        devShells.default = pkgs.mkShell {
          shellHook = ''
            # For misbehaving gems that don't pick up the flags from BUNDLE_BUILD_*
            export CPATH="${pkgs.zlib.dev}/include:$CPATH"
            export LIBRARY_PATH="${pkgs.zlib.out}/lib:$LIBRARY_PATH"

            # Worktree-aware Bundler/Ruby isolation
            if [ "$(${worktree.isWorktree})" = "true" ]; then
              WT_ID=$(${worktree.id})
              WT_ROOT=$(git -c core.fsmonitor=false rev-parse --show-toplevel)
              WT_BUNDLE_PATH="$WT_ROOT/.bundle"
              export GEM_HOME="$HOME/.local/share/gem/worktrees/$WT_ID"
              export BUNDLE_PATH="$WT_BUNDLE_PATH"
              export BUNDLE_APP_CONFIG="$WT_BUNDLE_PATH"
              export BUNDLE_IGNORE_CONFIG=1
              mkdir -p "$GEM_HOME" "$WT_BUNDLE_PATH"
              echo "Worktree Bundler isolation enabled (ID: $WT_ID)"
            else
              export GEM_HOME=$PWD/.nix/ruby/$(${ruby}/bin/ruby -e "puts RUBY_VERSION")
              mkdir -p $GEM_HOME
            fi

            # Per-worktree Yarn cache
            if [ "$(${worktree.isWorktree})" = "true" ]; then
              export YARN_CACHE_FOLDER="$HOME/.local/share/yarn/worktrees/$WT_ID"
              mkdir -p "$YARN_CACHE_FOLDER"
            fi

            export BUNDLE_BUILD__PG="${builtins.concatStringsSep " " postgresqlBuildFlags}"
            export GEM_PATH=$GEM_HOME
            export PATH=${ruby}/bin:$GEM_HOME/bin:$PATH

            export BUNDLE_BUILD__PSYCH="${builtins.concatStringsSep " " psychBuildFlags}"
            export BUNDLE_BUILD__ZLIB="${builtins.concatStringsSep " " zlibBuildFlags}"

            ${pg-environment-variables}

            # === Automatic per-worktree database initialization ===
            if [ "$(${worktree.isWorktree})" = "true" ]; then
              WT_ID=$(${worktree.id})
              MARKER="$PGDATA/.worktree-initialized"
              PIDFILE="/tmp/pg-$WT_ID.pid"

              if [ ! -f "$MARKER" ]; then
                echo ""
                echo "==> First time in this worktree ($WT_ID) - running full setup..."
                echo ""

                fail_worktree_setup() {
                  echo ""
                  echo "==> Worktree setup failed. Fix the error above, then re-enter the shell."
                  if [ -f "$PGDATA/postmaster.pid" ]; then
                    ${postgresql}/bin/pg_ctl stop -D "$PGDATA" -s -m fast || true
                  fi
                  exit 1
                }

                run_setup_step() {
                  label="$1"
                  shift
                  log_file="/tmp/worktree-$WT_ID-$(echo "$label" | tr '[:upper:] /:' '[:lower:]---').log"

                  echo "    $label..."
                  # Setup commands may spawn daemon helpers, such as git fsmonitor. Close
                  # inherited nix-direnv pipe fds so those helpers cannot block `direnv exec`.
                  if "$@" >"$log_file" 2>&1 \
                    3>&- 4>&- 5>&- \
                    6>&- 7>&- 8>&- 9>&-; then
                    echo "      ok (log: $log_file)"
                  else
                    status=$?
                    echo "      failed with exit $status (log: $log_file)"
                    echo "      last 80 log lines:"
                    tail -80 "$log_file" | sed 's/^/        /'
                    return "$status"
                  fi
                }

                # Start Postgres as a proper daemon on the short socket if not already running
                if ! ${postgresql}/bin/pg_isready -h "$PGHOST" -p "''${PGPORT:-5432}" >/dev/null 2>&1; then
                  echo "    Starting Postgres as daemon on short socket..."
                  if [ ! -f "$PGDATA/PG_VERSION" ]; then
                    mkdir -p "$PGDATA"
                    run_setup_step "Initialising Postgres data directory" ${postgresql}/bin/initdb "$PGDATA" --auth=trust || fail_worktree_setup
                  fi
                  rm -f "$PIDFILE"
                  # pg_ctl daemonises Postgres from inside direnv's shellHook. File descriptors
                  # 3+ are extra handles opened by the parent process; `>&-` closes them for this
                  # command. Without this, Postgres inherits a nix-direnv pipe and the first
                  # `direnv exec ...` stays blocked after setup instead of running its command.
                  if ! ${postgresql}/bin/pg_ctl start \
                    -D "$PGDATA" \
                    -l "/tmp/pg-$WT_ID.log" \
                    -o "-k $PGHOST -c listen_addresses= -c external_pid_file=$PIDFILE" \
                    -w \
                    -t 60 \
                    3>&- 4>&- 5>&- \
                    6>&- 7>&- 8>&- 9>&-; then
                    echo "      failed to start Postgres (log: /tmp/pg-$WT_ID.log)"
                    echo "      last 80 log lines:"
                    tail -80 "/tmp/pg-$WT_ID.log" | sed 's/^/        /' || true
                    fail_worktree_setup
                  fi
                  for i in {1..60}; do
                    if ${postgresql}/bin/pg_isready -h "$PGHOST" -p "''${PGPORT:-5432}" >/dev/null 2>&1; then
                      break
                    fi
                    sleep 1
                  done
                  if ! ${postgresql}/bin/pg_isready -h "$PGHOST" -p "''${PGPORT:-5432}" >/tmp/pg-$WT_ID-ready.log 2>&1; then
                    echo "      Postgres did not become ready on $PGHOST"
                    cat /tmp/pg-$WT_ID-ready.log | sed 's/^/        /' || true
                    fail_worktree_setup
                  fi
                fi

                rm -rf "$BUNDLE_PATH"
                mkdir -p "$BUNDLE_PATH"
                export BUNDLE_IGNORE_CONFIG=1
                run_setup_step "Installing gems" bundle install --jobs=4 --retry=3 || fail_worktree_setup
                run_setup_step "Preparing development database" bundle exec rails db:prepare || fail_worktree_setup
                run_setup_step "Preparing test database" env RAILS_ENV=test bundle exec rails db:prepare || fail_worktree_setup
                run_setup_step "Installing JS dependencies" yarn install --frozen-lockfile || fail_worktree_setup
                run_setup_step "Compiling assets" bundle exec rails assets:precompile || fail_worktree_setup

                touch "$MARKER"
                echo ""
                echo "==> Worktree first-time setup complete."
                echo ""
              else
                export BUNDLE_IGNORE_CONFIG=1
              fi
            fi

            ${preCommitCheck.shellHook}
            export PATH=${preCommit}/bin:$PATH
            ${worktree-info}/bin/worktree-info
          '';

          buildInputs = preCommitCheck.enabledPackages ++ [
            chrome
            init
            lint
            pkgs.circleci-cli
            pkgs.python3
            pkgs.rufo
            pkgs.socat
            pkgs.terraform-docs
            pkgs.yarn
            pkgs.zlib
            postgresql
            pgConfig
            postgresql-start
            ruby
            update-providers
            worktree-info
            worktree-clean
          ];
        };
      }
    );
}
