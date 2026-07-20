{
  description = "understanding-html-docs-generate runtime: pandoc. Renders a semantic IR (Markdown + fenced divs) into an understanding-html-docs page via a template + Lua filter. pandoc is the only dependency; nix supplies it so the generator works with no host setup.";

  # nixpkgs-weekly (flakehub): its pandoc is built WITH Lua on darwin. Plain
  # github NixOS/nixpkgs unstable ships a Lua-less pandoc on darwin at some revs,
  # which breaks --lua-filter (the filter is load-bearing here).
  inputs.nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1.tar.gz";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              # haskellPackages.pandoc-cli is the full CLI *with Lua* — the plain
              # `pandoc` attr resolves to a Lua-less build on darwin at some revs,
              # which breaks --lua-filter (the filter is load-bearing here).
              pkgs.haskellPackages.pandoc-cli
            ];
          };
        }
      );
    };
}
