{
  description = "paper-studio-summarize runtime: uv + poppler + python3 + jq + curl. Python packages (mineru) are NOT in this flake — they are declared in pyproject.toml and resolved by `uv run --project` (auto-synced from uv.lock). nix only supplies uv + poppler so that path works with no external setup.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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
              pkgs.python3 # runs mineru_to_paper_md.py (stdlib only)
              pkgs.poppler-utils # pdftotext / pdfinfo / pdftoppm
              pkgs.uv # runs mineru via `uv run --project` (deps from pyproject/uv.lock)
              pkgs.jq # dblp_lookup.sh
              pkgs.curl # dblp_lookup.sh / dblp_bibtex.sh
            ];
          };
        }
      );
    };
}
