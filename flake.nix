{
  description = "Iosevka - custom neg variant";
  nixConfig = {
    env-keep = [
      "SOPS_AGE_KEY"
      "SOPS_AGE_KEY_FILE"
    ];
  };
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
          faFonts = pkgs.runCommand "fontawesome-pro" {
            buildInputs = [pkgs.sops pkgs.gnutar pkgs.gzip pkgs.coreutils];
          } ''
            set -euo pipefail

            tmp_key=""
            cleanup() {
              if [ -n "$tmp_key" ] && [ -f "$tmp_key" ]; then
                rm -f "$tmp_key"
              fi
            }
            trap cleanup EXIT

            if [ -z "${SOPS_AGE_KEY_FILE:-}" ] && [ -n "${SOPS_AGE_KEY:-}" ]; then
              tmp_key="$(mktemp)"
              printf '%s\n' "$SOPS_AGE_KEY" > "$tmp_key"
              export SOPS_AGE_KEY_FILE="$tmp_key"
            fi

            if [ -z "${SOPS_AGE_KEY_FILE:-}" ] || [ ! -r "${SOPS_AGE_KEY_FILE}" ]; then
              echo "Missing age key: set SOPS_AGE_KEY or SOPS_AGE_KEY_FILE" >&2
              exit 1
            fi

            sops -d ${./fa.tar.gz.enc} | tar -xz
            install -Dm644 Font\ Awesome*.otf -t "$out/share/fonts/fontawesome"
          '';
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
                fa_path="${faFonts}/share/fonts/fontawesome/Font Awesome 6 Pro-Regular-400.otf"

                for fontfile in ${plainPackage}/share/fonts/truetype/*; do
                    nerd-font-patcher "$fontfile" \
                    --complete -s --makegroups '-1' --careful \
                    --outputdir ${outDir} &
                done
                wait
                nerd-font-patcher "${outDir}/Iosevka-Regular.ttf" --custom "$fa_path" -s --makegroups '-1' --outputdir ${outDir}/../ &
                nerd-font-patcher "${outDir}/Iosevka-Italic.ttf" --custom "$fa_path" -s --makegroups '-1' --outputdir ${outDir}/../ &
                nerd-font-patcher "${outDir}/Iosevka-Medium.ttf" --custom "$fa_path" -s --makegroups '-1' --outputdir ${outDir}/../ &
                nerd-font-patcher "${outDir}/Iosevka-MediumItalic.ttf" --custom "$fa_path" -s --makegroups '-1' --outputdir ${outDir}/../ &
                nerd-font-patcher "${outDir}/Iosevka-Bold.ttf" --custom "$fa_path" -s --makegroups '-1' --outputdir ${outDir}/../ &
                nerd-font-patcher "${outDir}/Iosevka-BoldItalic.ttf" --custom "$fa_path" -s --makegroups '-1' --outputdir ${outDir}/../ &
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
