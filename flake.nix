{
  description = "Bouncing game mobile game flake.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in 
  {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        zig
        sdl3
      ];
    };

    shellHook = ''
      echo "Entering shell..."
    '';
  };
}
