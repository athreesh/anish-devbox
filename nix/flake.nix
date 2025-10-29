{
  description = "Anish's GPU Development Box Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations = {
        # Replace with your username
        "anish" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
        };
      };

      # Development shell for quick testing
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          kubectl
          kubernetes-helm
          k9s
          nodejs_20
          python311
        ];

        shellHook = ''
          echo "GPU Dev Box Environment"
          echo "======================="
          echo "Kubernetes: $(kubectl version --client --short 2>/dev/null || echo 'not configured')"
          echo "Node: $(node --version 2>/dev/null || echo 'not found')"
          echo "Python: $(python --version 2>/dev/null || echo 'not found')"
        '';
      };
    };
}
