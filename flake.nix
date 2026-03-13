{
  description = "Compilar mcpelauncher WAYLAND (Qt6 - Manifest Repo)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    
    # Se usa stdenv de LLVM para compilar directamente con Clang
    stdenv = pkgs.llvmPackages_latest.stdenv;
  in {
    packages.${system}.default = stdenv.mkDerivation {
      pname = "mcpelauncher-wayland";
      version = "qt6-latest";

      # Clonación equivalente a actions/checkout con submódulos
      src = pkgs.fetchgit {
        url = "https://github.com/minecraft-linux/mcpelauncher-manifest.git";
        rev = "refs/heads/qt6";
        fetchSubmodules = true;
        deepClone = false;
        # Nota: Al usar fetchgit por primera vez, Nix pedirá un hash (sha256). 
        # Puedes usar pkgs.lib.fakeSha256 temporalmente para obtener el correcto.
        sha256 = pkgs.lib.fakeSha256; 
      };

      nativeBuildInputs = with pkgs; [
        cmake
        pkg-config
        ninja
        qt6.wrapQtAppsHook
      ];

      # Dependencias inferidas para Qt6, Wayland, SDL3 y McpeLauncher
      buildInputs = with pkgs; [
        qt6.qtbase
        qt6.qtwayland
        qt6.qtwebengine
        sdl3
        openssl
        zlib
        curl
        libzip
        libpng
        wayland
        libxkbcommon
        vulkan-headers
        vulkan-loader
        alsa-lib
        pulseaudio
      ];

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_POLICY_DEFAULT_CMP0074=NEW"
        "-DJNI_USE_JNIVM=ON"
        "-DGAMEWINDOW_SYSTEM=SDL3"
      ];

      # Variables de entorno para aplicar los flags de optimización a Clang
      env.NIX_CFLAGS_COMPILE = "-march=x86-64 -mtune=generic -msse4.1 -msse4.2 -mpopcnt";

      # En lugar de subir artefactos, los instalamos en la salida del paquete ($out/bin)
      installPhase = ''
        mkdir -p $out/bin
        
        # Copiamos los binarios que especificaste en upload-artifact
        cp mcpelauncher-client $out/bin/ || true
        cp mcpelauncher-ui-qt/mcpelauncher-ui-qt $out/bin/ || true
        cp mcpelauncher-webview $out/bin/ || true
        cp mcpelauncher-error $out/bin/ || true
        cp mcpelauncher-extract $out/bin/ || true
      '';
    };
  };
}
