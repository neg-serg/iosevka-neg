{
  description = "Iosevka - custom neg variant";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    allSystems =
      flake-utils.lib.eachDefaultSystem
      (
        system: let
          pkgs = nixpkgs.legacyPackages.${system};
          buildPlan = builtins.readFile ./iosevka-neg.toml;

          mkPlain = set: pkgs.iosevka.override {
            inherit set;
            privateBuildPlan = buildPlan;
          };

          mkNerd = plain: pkgs.runCommand "iosevka-nerd-font-${plain.version}" {
            buildInputs = [pkgs.nerd-font-patcher];
          } ''
            set -euo pipefail
            outDir="$out/share/fonts/truetype"

            mkdir -p "$outDir"

            for fontfile in ${plain}/share/fonts/truetype/*; do
              nerd-font-patcher "$fontfile" \
                --complete -s --makegroups '-1' --careful \
                --outputdir "$outDir" &
            done
            wait
          '';

          plainMono = mkPlain "";
          plainQuasi = mkPlain "quasi";
          plainProp = mkPlain "prop";

          packages = {
            normal = plainMono;
            quasi = plainQuasi;
            prop = plainProp;
            nerd-font = mkNerd plainMono;
            nerd-font-quasi = mkNerd plainQuasi;
            nerd-font-prop = mkNerd plainProp;
          };
        in {
          inherit packages;
          defaultPackage = packages.nerd-font;
        }
      );
  in {
    packages = allSystems.packages;
    defaultPackage = allSystems.defaultPackage;
    overlay = final: prev: {
      iosevka = allSystems.packages.${final.system};
    };
  };
}
