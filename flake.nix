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
          plainPackage = pkgs.iosevka.override {
            set = "neg";
            privateBuildPlan = builtins.readFile ./iosevka-neg.toml;
          };

          nerdFontPackage =
            pkgs.runCommand "iosevka-nerd-font-${plainPackage.version}" {
              buildInputs = [pkgs.nerd-font-patcher];
            } ''
              set -euo pipefail
              outDir="$out/share/fonts/truetype"

              mkdir -p "$outDir"

              for fontfile in ${plainPackage}/share/fonts/truetype/*; do
                nerd-font-patcher "$fontfile" \
                  --complete -s --makegroups '-1' --careful \
                  --outputdir "$outDir" &
              done
              wait
            '';

          packages = {
            normal = plainPackage;
            nerd-font = nerdFontPackage;
          };
        in {
          inherit packages;
          defaultPackage = nerdFontPackage;
        }
      );
  in {
    packages = allSystems.packages;
    defaultPackage = allSystems.defaultPackage;
    overlay = final: prev: {
      iosevka = allSystems.packages.${final.system}; # either `normal` or `nerd-font`
    };
  };
}
