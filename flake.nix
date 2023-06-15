{
  description = "Common classes for application layers of PythonEDA projects";

  inputs = rec {
    nixos.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    poetry2nix = {
      url = "github:nix-community/poetry2nix/v1.28.0";
      inputs.nixpkgs.follows = "nixos";
      inputs.flake-utils.follows = "flake-utils";
    };
    pythoneda-base = {
      url = "github:pythoneda/base/0.0.1a12";
      inputs.nixos.follows = "nixos";
      inputs.flake-utils.follows = "flake-utils";
      inputs.poetry2nix.follows = "poetry2nix";
    };
    pythoneda-infrastructure-base = {
      url = "github:pythoneda-infrastructure/base/0.0.1a8";
      inputs.nixos.follows = "nixos";
      inputs.flake-utils.follows = "flake-utils";
      inputs.poetry2nix.follows = "poetry2nix";
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
            pythonMajorVersion =
              builtins.head (builtins.splitVersion python.version);
          in python.pkgs.buildPythonPackage rec {
            pname = "pythoneda-application-base";
            inherit version;
            projectDir = ./.;
            src = ./.;
            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [ pip poetry-core ];
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
              cp dist/*.whl $out/dist
            '';
            meta = { inherit description license homepage maintainers; };
          };
        pythoneda-application-base-0_0_1a8-for =
          { pythoneda-base, pythoneda-infrastructure-base, python }:
          pythoneda-application-base-for {
            version = "0.0.1a8";
            inherit pythoneda-base pythoneda-infrastructure-base python;
          };
      in rec {
        packages = rec {
          pythoneda-application-base-0_0_1a8-python38 =
            pythoneda-application-base-0_0_1a8-for {
              pythoneda-base =
                pythoneda-base.packages.${system}.pythoneda-base-latest-python38;
              pythoneda-infrastructure-base =
                pythoneda-infrastructure-base.packages.${system}.pythoneda-infrastructure-base-latest-python38;
              python = pkgs.python38;
            };
          pythoneda-application-base-0_0_1a8-python39 =
            pythoneda-application-base-0_0_1a8-for {
              pythoneda-base =
                pythoneda-base.packages.${system}.pythoneda-base-latest-python39;
              pythoneda-infrastructure-base =
                pythoneda-infrastructure-base.packages.${system}.pythoneda-infrastructure-base-latest-python39;
              python = pkgs.python39;
            };
          pythoneda-application-base-0_0_1a8-python310 =
            pythoneda-application-base-0_0_1a8-for {
              pythoneda-base =
                pythoneda-base.packages.${system}.pythoneda-base-latest-python310;
              pythoneda-infrastructure-base =
                pythoneda-infrastructure-base.packages.${system}.pythoneda-infrastructure-base-latest-python310;
              python = pkgs.python310;
            };
          pythoneda-application-base-latest-python38 =
            pythoneda-application-base-0_0_1a8-python38;
          pythoneda-application-base-latest-python39 =
            pythoneda-application-base-0_0_1a8-python39;
          pythoneda-application-base-latest-python310 =
            pythoneda-application-base-0_0_1a8-python310;
          pythoneda-application-base-latest =
            pythoneda-application-base-latest-python310;
          default = pythoneda-application-base-latest;
        };
        defaultPackage = packages.default;
        devShells = rec {
          pythoneda-application-base-0_0_1a8-python38 = shared.devShell-for {
            package = packages.pythoneda-application-base-0_0_1a8-python38;
            python = pkgs.python38;
            inherit pkgs nixpkgsRelease;
          };
          pythoneda-application-base-0_0_1a8-python39 = shared.devShell-for {
            package = packages.pythoneda-application-base-0_0_1a8-python39;
            python = pkgs.python39;
            inherit pkgs nixpkgsRelease;
          };
          pythoneda-application-base-0_0_1a8-python310 = shared.devShell-for {
            package = packages.pythoneda-application-base-0_0_1a8-python310;
            python = pkgs.python310;
            inherit pkgs nixpkgsRelease;
          };
          pythoneda-application-base-latest-python38 =
            pythoneda-application-base-0_0_1a8-python38;
          pythoneda-application-base-latest-python39 =
            pythoneda-application-base-0_0_1a8-python39;
          pythoneda-application-base-latest-python310 =
            pythoneda-application-base-0_0_1a8-python310;
          pythoneda-application-base-latest =
            pythoneda-application-base-latest-python310;
          default = pythoneda-application-base-latest;
        };
      });
}
