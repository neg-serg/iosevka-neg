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

          nerdFontPackage = let
            outDir = "$out/share/fonts/truetype/prepare";
          in
            pkgs.stdenv.mkDerivation {
              pname = "iosevka-nerd-font";
              version = plainPackage.version;
              src = builtins.path {
                path = ./.;
                name = "iosevka-neg";
              };
              buildInputs = [pkgs.nerd-font-patcher];
              configurePhase = ''
                mkdir -p ${outDir}
              '';
              buildPhase = ''
                for fontfile in ${plainPackage}/share/fonts/truetype/*; do
                    nerd-font-patcher $fontfile \
                    --complete -s --makegroups '-1' --careful \
                    --outputdir ${outDir} &
                done
                wait
                {
                    nerd-font-patcher "${outDir}/Iosevka-Regular.ttf" --custom '${self}/Font Awesome 6 Pro-Regular-400.otf' -s --makegroups '-1' --outputdir ${outDir}/../
                    nerd-font-patcher "${outDir}/Iosevka-Italic.ttf" --custom '${self}/Font Awesome 6 Pro-Regular-400.otf' -s --makegroups '-1' --outputdir ${outDir}/../
                    nerd-font-patcher "${outDir}/Iosevka-Medium.ttf" --custom '${self}/Font Awesome 6 Pro-Regular-400.otf' -s --makegroups '-1' --outputdir ${outDir}/../
                    nerd-font-patcher "${outDir}/Iosevka-Bold.ttf" --custom '${self}/Font Awesome 6 Duotone-Solid-900.otf' -s --makegroups '-1' --outputdir ${outDir}/../
                    nerd-font-patcher "${outDir}/Iosevka-BoldItalic.ttf" --custom '${self}/Font Awesome 6 Duotone-Solid-900.otf' -s --makegroups '-1' --outputdir ${outDir}/../
                }  &
                wait
                rm -r ${outDir}
              '';
            };

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
