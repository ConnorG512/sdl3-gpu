{
  description = "SDL3 Application.";

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
        vulkan-loader
        vulkan-validation-layers
        zig
        sdl3
        shaderc
        lldb
        renderdoc
      ];
    };

    shellHook = ''
      echo "Entering shell..."
      export LD_LIBRARY_PATH"${
        pkgs.lib.makeLibraryPath [
            pkgs.vulkan-loader 
            pkgs.vulkan-validation-layers 
        ]
      }"
      export VK_LAYER_PATH="${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
    '';
  };
}
