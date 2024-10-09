{
  description = "Macbook Pro Catalina Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget

      nixpkgs.config.allowUnfree = true;
      environment.systemPackages =
        [ 
        pkgs.nano 
        pkgs.zsh
        pkgs.hyfetch 
        pkgs.tmux 
        pkgs.git 
        pkgs.gh 
        pkgs.python3
        pkgs.mkalias
        pkgs.obsidian
        ];

        homebrew = {
          enable = true;
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
          masApps = {
            "Onedrive" = 823766827;
          };
          brews = [
            "mas"
          ];
          casks = [
            "firefox"
            "sublime-text"
            "visual-studio-code"
            "freac"
            "keka"
            "raspberry-pi-imager"
            "bowtie"
            "vlc"
            "macs-fan-control"
            "makemkv"
            "iterm2"
            "alfred"
          ];
        };
      fonts.packages = [
        (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      ];
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
            '';

    system.defaults = {
      dock.autohide = false;
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
      dock.minimize-to-application = true;
      dock.orientation = "left";
      dock.persistent-apps = [
        "/System/Applications/Launchpad.app"
        "/System/Applications/Mission\ Control.app/"
        "/Applications/Firefox.app"
        "/System/Applications/Messages.app"
        "/Applications/iTerm.app"
        "/Applications/Visual\ Studio\ Code.app"
        "/System/Applications/System\ Preferences.app"

      ];
      dock.persistent-others = [
        "/Applications"
        "/Users/ethan/Documents"
        "/Users/ethan/Downloads"
      ];
      dock.show-process-indicators = true;
      dock.show-recents = false;
      dock.showhidden = true;
      dock.wvous-bl-corner = 4;
      finder.AppleShowAllExtensions = true;
      finder.FXDefaultSearchScope = "SCcf";
      finder.ShowPathbar = true;
      menuExtraClock.Show24Hour = true;
      menuExtraClock.ShowDate = 1;
      menuExtraClock.ShowDayOfMonth = true;
      menuExtraClock.ShowDayOfWeek = true;
      menuExtraClock.ShowSeconds = true;
      screencapture.disable-shadow = true;
      trackpad.Clicking = true;
      NSGlobalDomain.AppleInterfaceStyle = "Dark";
      NSGlobalDomain.KeyRepeat = 2;
      finder.FXPreferredViewStyle = "clmv";
      NSGlobalDomain.AppleICUForce24HourTime = true;

    };
      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "x86_64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."macbookpro" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration 
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user="ethan";
            autoMigrate = true;
          };
        } 
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."macbookpro".pkgs;
  };
}
