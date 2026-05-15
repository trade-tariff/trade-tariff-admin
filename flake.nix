{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
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
      nixpkgs-ruby,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          system = system;
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

        postgresqlBuildFlags = with pkgs; [
          "--with-pg-config=${lib.getDev postgresql_18.pg_config}/bin/pg_config"
        ];
        psychBuildFlags = with pkgs; [
          "--with-libyaml-include=${libyaml.dev}/include"
          "--with-libyaml-lib=${libyaml.out}/lib"
        ];
        zlibBuildFlags = with pkgs; [
          "--with-zlib-include=${zlib.dev}/include"
          "--with-zlib-lib=${zlib.out}/lib"
        ];
        postgresql = pkgs.postgresql_18;

        # Worktree isolation hook (same pattern as backend)
        worktree = rec {
          isWorktree = ''
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
              if [ "$(git rev-parse --git-dir 2>/dev/null)" != "$(git rev-parse --git-common-dir 2>/dev/null)" ]; then
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
              git rev-parse --show-toplevel | md5sum | cut -c1-8
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

          if [ ! -d $PGDATA ]; then
            mkdir -p $PGDATA
            ${postgresql}/bin/initdb $PGDATA --auth=trust
          fi

          ${postgresql}/bin/postgres -k $PGHOST -c listen_addresses=''' -c unix_socket_directories=$PGHOST
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

          if command -v dropdb >/dev/null 2>&1; then
            dropdb --if-exists "tariff_admin_development" || true
            dropdb --if-exists "tariff_admin_test" || true
          fi

          rm -rf "/tmp/pg-$WT_ID"
          rm -rf "$HOME/.local/share/postgres/worktrees/$WT_ID"
          rm -rf ".bundle"
          rm -rf "$HOME/.local/share/gem/worktrees/$WT_ID" 2>/dev/null || true
          rm -rf "$HOME/.cache/bundle/worktrees/$WT_ID" 2>/dev/null || true

          # Per-worktree Yarn cache + generated webpack packs (for bin/webpack)
          rm -rf "$HOME/.local/share/yarn/worktrees/$WT_ID"
          rm -rf public/packs public/packs-test 2>/dev/null || true

          rm -f "$HOME/.local/share/postgres/worktrees/$WT_ID/.worktree-initialized" 2>/dev/null || true

          echo "Worktree $WT_ID cleaned (Postgres + bundle + yarn + packs)."
        '';

        lint = pkgs.writeShellScriptBin "lint" ''
          changed_files=$(git diff --name-only --diff-filter=ACM --merge-base main)

          bundle exec rubocop --autocorrect-all --force-exclusion $changed_files Gemfile
        '';
        lint-all = pkgs.writeShellScriptBin "lint-all" ''
          bundle exec rubocop --autocorrect-all
        '';
        update-providers = pkgs.writeShellScriptBin "update-providers" ''
          cd terraform
          terraform init -backend=false -reconfigure -upgrade
        '';

        init = pkgs.writeShellScriptBin "init" ''
          cd terraform && terraform init -input=false -no-color -backend=false
        '';

      in
      {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            # For misbehaving gems that don't pick up the flags from BUNDLE_BUILD_*
            export CPATH="${pkgs.zlib.dev}/include:$CPATH"
            export LIBRARY_PATH="${pkgs.zlib.out}/lib:$LIBRARY_PATH"

            # Worktree-aware Bundler/Ruby isolation
            if [ "$(${worktree.isWorktree})" = "true" ]; then
              WT_ID=$(${worktree.id})
              export GEM_HOME="$HOME/.local/share/gem/worktrees/$WT_ID"
              export BUNDLE_PATH=".bundle"
              export BUNDLE_APP_CONFIG=".bundle"
              export BUNDLE_IGNORE_CONFIG=1
              export BUNDLE_FORCE_RUBY_PLATFORM=1
              mkdir -p "$GEM_HOME" ".bundle"
              echo "Worktree Bundler isolation enabled (ID: $WT_ID)"
            else
              export GEM_HOME=$PWD/.nix/ruby/$(${ruby}/bin/ruby -e "puts RUBY_VERSION")
              mkdir -p $GEM_HOME
            fi

            # Per-worktree Yarn cache (for bin/webpack after yarn)
            if [ "$(${worktree.isWorktree})" = "true" ]; then
              export YARN_CACHE_FOLDER="$HOME/.local/share/yarn/worktrees/$WT_ID"
              mkdir -p "$YARN_CACHE_FOLDER"
            fi

            export BUNDLE_BUILD__PG="${builtins.concatStringsSep " " postgresqlBuildFlags}"
            export GEM_PATH=$GEM_HOME
            export PATH=$GEM_HOME/bin:$PATH

            export BUNDLE_BUILD__PSYCH="${builtins.concatStringsSep " " psychBuildFlags}"
            export BUNDLE_BUILD__ZLIB="${builtins.concatStringsSep " " zlibBuildFlags}"

            ${pg-environment-variables}

            # === Automatic per-worktree database initialization ===
            if [ "$(${worktree.isWorktree})" = "true" ]; then
              WT_ID=$(${worktree.id})
              MARKER="$PGDATA/.worktree-initialized"

              if [ ! -f "$MARKER" ]; then
                echo ""
                echo "==> First time in this worktree (ID: $WT_ID)"
                echo "    Installing gems + initializing databases + assets..."
                echo ""

                # Start Postgres as a proper daemon on the short socket if not already running
                if ! pg_isready -h "$PGHOST" -p "${PGPORT:-5432}" >/dev/null 2>&1; then
                  echo "    Starting Postgres as daemon on short socket..."
                  pg_ctl start -D "$PGDATA" -l "/tmp/pg-$WT_ID.log" \
                    -o "-k $PGHOST -c listen_addresses=''" -w -t 30 || true
                fi

                rm -rf .bundle
                bundle install --jobs=4 --retry=3 2>&1 | tail -8 || true
                bundle exec rails db:prepare 2>&1 | tail -8 || true

                echo ""
                echo "    Preparing test database..."
                RAILS_ENV=test bundle exec rails db:prepare 2>&1 | tail -5 || true

                echo ""
                echo "    Installing JS dependencies and compiling webpack packs..."
                yarn install --frozen-lockfile 2>&1 | tail -5 || true
                bundle exec bin/webpack 2>&1 | tail -8 || true

                touch "$MARKER"
                echo ""
                echo "==> Worktree databases + assets ready."
                echo ""
              fi
            fi

            ${worktree-info}/bin/worktree-info

            # Ensure pre-commit hooks are installed (so they actually run on commit)
            if command -v pre-commit >/dev/null 2>&1; then
              pre-commit install --install-hooks 2>/dev/null || true
            fi
          '';

          buildInputs = [
            chrome
            init
            lint
            lint-all
            pkgs.pre-commit
            pkgs.circleci-cli
            pkgs.python3
            pkgs.rufo
            pkgs.socat
            pkgs.terraform-docs
            pkgs.yarn
            pkgs.zlib
            postgresql
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
