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

  outputs = { self, nixpkgs, flake-utils, nixpkgs-ruby }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          system = system;
          config.allowUnfree = true;
          overlays = [nixpkgs-ruby.overlays.default];
        };

        rubyVersion = builtins.head (builtins.split "\n" (builtins.readFile ./.ruby-version));
        ruby = pkgs."ruby-${rubyVersion}";

        chrome = pkgs.writeShellScriptBin "chrome" ''
          binary=$(find ${pkgs.google-chrome.outPath} -type f -name 'google-chrome-stable')
          exec $binary "$@"
        '';

        psychBuildFlags = with pkgs; [
          "--with-libyaml-include=${libyaml.dev}/include"
          "--with-libyaml-lib=${libyaml.out}/lib"
        ];

        lint = pkgs.writeScriptBin "lint" ''
          changed_files=$(git diff --name-only --diff-filter=ACM --merge-base main)

          bundle exec rubocop --autocorrect-all --force-exclusion $changed_files Gemfile
        '';
        lint-all = pkgs.writeScriptBin "lint-all" ''
          bundle exec rubocop --autocorrect-all
        '';
        update-providers = pkgs.writeScriptBin "update-providers" ''
          cd terraform
          terraform init -backend=false -reconfigure -upgrade
        '';
      in {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            export GEM_HOME=$PWD/.nix/ruby/$(${ruby}/bin/ruby -e "puts RUBY_VERSION")
            mkdir -p $GEM_HOME

            export GEM_PATH=$GEM_HOME
            export PATH=$GEM_HOME/bin:$PATH

            export BUNDLE_BUILD__PSYCH="${
              builtins.concatStringsSep " " psychBuildFlags
            }"
          '';

          buildInputs = [
            chrome
            lint
            lint-all
            pkgs.circleci-cli
            pkgs.rufo
            pkgs.sqlite
            pkgs.yarn
            ruby
            update-providers
          ];
        };
      });
}
