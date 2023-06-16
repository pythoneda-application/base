{
  description = "Common classes for application layers of PythonEDA projects";

  inputs = rec {
    nixos.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    pythoneda-base = {
      url = "github:pythoneda/base/0.0.1a13";
      inputs.nixos.follows = "nixos";
      inputs.flake-utils.follows = "flake-utils";
    };
    pythoneda-infrastructure-base = {
      url = "github:pythoneda-infrastructure/base/0.0.1a9";
      inputs.nixos.follows = "nixos";
      inputs.flake-utils.follows = "flake-utils";
      inputs.pythoneda-base.follows = "pythoneda-base";
    };
  };
  outputs = inputs:
    with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixos { inherit system; };
        python = pkgs.python3;
        pythonPackages = python.pkgs;
        description =
          "Common classes for application layers of PythonEDA projects";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/pythoneda-application/base";
        maintainers = with pkgs.lib.maintainers; [ ];
        nixpkgsRelease = "nixos-23.05";
        shared = import ./nix/devShells.nix;
        pythoneda-application-base-for =
          { version, pythoneda-base, pythoneda-infrastructure-base, python }:
          let
            pname = "pythoneda-application-base";
            pythonVersionParts = builtins.splitVersion python.version;
            pythonMajorVersion = builtins.head pythonVersionParts;
            pythonMajorMinorVersion =
              "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
            pnameWithUnderscores =
              builtins.replaceStrings [ "-" ] [ "_" ] pname;
            wheelName =
              "${pnameWithUnderscores}-${version}-py${pythonMajorVersion}-none-any.whl";
          in python.pkgs.buildPythonPackage rec {
            inherit pname version;
            projectDir = ./.;
            src = ./.;
            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [ pip pkgs.jq poetry-core ];
            propagatedBuildInputs = with python.pkgs; [
              pythoneda-base
              pythoneda-infrastructure-base
            ];

            checkInputs = with python.pkgs; [ pytest ];

            pythonImportsCheck = [ "pythonedaapplication" ];

            preBuild = ''
              python -m venv .env
              source .env/bin/activate
              pip install ${pythoneda-base}/dist/pythoneda_base-${pythoneda-base.version}-py${pythonMajorVersion}-none-any.whl
              pip install ${pythoneda-infrastructure-base}/dist/pythoneda_infrastructure_base-${pythoneda-infrastructure-base.version}-py${pythonMajorVersion}-none-any.whl
              rm -rf .env
            '';
            postInstall = ''
              mkdir $out/dist
              cp dist/${wheelName} $out/dist
              jq ".url = \"$out/dist/${wheelName}\"" $out/lib/python${pythonMajorMinorVersion}/site-packages/${pnameWithUnderscores}-${version}.dist-info/direct_url.json > temp.json && mv temp.json $out/lib/python${pythonMajorMinorVersion}/site-packages/${pnameWithUnderscores}-${version}.dist-info/direct_url.json
            '';
            meta = { inherit description homepage license maintainers; };
          };
        pythoneda-application-base-0_0_1a9-for =
          { pythoneda-base, pythoneda-infrastructure-base, python }:
          pythoneda-application-base-for {
            version = "0.0.1a9";
            inherit pythoneda-base pythoneda-infrastructure-base python;
          };
      in rec {
        packages = rec {
          pythoneda-application-base-0_0_1a9-python38 =
            pythoneda-application-base-0_0_1a9-for {
              pythoneda-base =
                pythoneda-base.packages.${system}.pythoneda-base-latest-python38;
              pythoneda-infrastructure-base =
                pythoneda-infrastructure-base.packages.${system}.pythoneda-infrastructure-base-latest-python38;
              python = pkgs.python38;
            };
          pythoneda-application-base-0_0_1a9-python39 =
            pythoneda-application-base-0_0_1a9-for {
              pythoneda-base =
                pythoneda-base.packages.${system}.pythoneda-base-latest-python39;
              pythoneda-infrastructure-base =
                pythoneda-infrastructure-base.packages.${system}.pythoneda-infrastructure-base-latest-python39;
              python = pkgs.python39;
            };
          pythoneda-application-base-0_0_1a9-python310 =
            pythoneda-application-base-0_0_1a9-for {
              pythoneda-base =
                pythoneda-base.packages.${system}.pythoneda-base-latest-python310;
              pythoneda-infrastructure-base =
                pythoneda-infrastructure-base.packages.${system}.pythoneda-infrastructure-base-latest-python310;
              python = pkgs.python310;
            };
          pythoneda-application-base-latest-python38 =
            pythoneda-application-base-0_0_1a9-python38;
          pythoneda-application-base-latest-python39 =
            pythoneda-application-base-0_0_1a9-python39;
          pythoneda-application-base-latest-python310 =
            pythoneda-application-base-0_0_1a9-python310;
          pythoneda-application-base-latest =
            pythoneda-application-base-latest-python310;
          default = pythoneda-application-base-latest;
        };
        defaultPackage = packages.default;
        devShells = rec {
          pythoneda-application-base-0_0_1a9-python38 = shared.devShell-for {
            package = packages.pythoneda-application-base-0_0_1a9-python38;
            python = pkgs.python38;
            inherit pkgs nixpkgsRelease;
          };
          pythoneda-application-base-0_0_1a9-python39 = shared.devShell-for {
            package = packages.pythoneda-application-base-0_0_1a9-python39;
            python = pkgs.python39;
            inherit pkgs nixpkgsRelease;
          };
          pythoneda-application-base-0_0_1a9-python310 = shared.devShell-for {
            package = packages.pythoneda-application-base-0_0_1a9-python310;
            python = pkgs.python310;
            inherit pkgs nixpkgsRelease;
          };
          pythoneda-application-base-latest-python38 =
            pythoneda-application-base-0_0_1a9-python38;
          pythoneda-application-base-latest-python39 =
            pythoneda-application-base-0_0_1a9-python39;
          pythoneda-application-base-latest-python310 =
            pythoneda-application-base-0_0_1a9-python310;
          pythoneda-application-base-latest =
            pythoneda-application-base-latest-python310;
          default = pythoneda-application-base-latest;
        };
      });
}
