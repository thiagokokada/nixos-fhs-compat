{ config, pkgs, lib, ... }:
# Based on work by matthewbauer <matthewbauer.us>
{

  options = {
    environment.lsb.enable = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Enable approximate LSB binary compatibility. This allows
        binaries that run on other distros to run on NixOS.
      '';
      default = false;
    };

    environment.lsb.enableDesktop = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Enable LSB Desktop extensions.
      '';
      default = true;
    };

    environment.lsb.support32Bit = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Enable LSB binary compatibility.
      '';
      default = false;
    };
    
    environment.lsb.extraLibs = lib.mkOption {
      type = with lib.types; listOf package;
      description = ''
        Extra libraries to be included.
      '';
      default = [ ];
    };

  };

  config = let
    # based on LSB 5.0
    # reference: http://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/requirements.html#RLIBRARIES

    libsFromPkgs = pkgs:
      with pkgs;
      [
        # Core
        glibc
        gcc.cc
        zlib
        ncurses5
        linux-pam
        nspr
        nspr
        nss
        openssl

        # Runtime Languages
        libxml2
        libxslt

        # Bonus (not in LSB)
        bzip2
        curl
        expat
        libusb1
        libcap
        dbus
        libuuid

      ] ++ lib.optionals config.environment.lsb.enableDesktop [
        # Desktop

        ## Graphics Libraries (X11)
        xorg.libX11
        xorg.libxcb
        xorg.libSM
        xorg.libICE
        xorg.libXt
        xorg.libXft
        xorg.libXrender
        xorg.libXext
        xorg.libXi
        xorg.libXtst
        xorg.libXcursor
        xorg.libXcomposite
        xorg.libXfixes
        xorg.libXdamage
        xorg.libXrandr
        xorg.libXScrnSaver
        xorg.libXfixes
        libxkbcommon

        ## OpenGL Libraries
        libGL
        libGLU

        ## Misc. desktop
        libpng12
        libjpeg
        fontconfig
        freetype
        libtiff
        cairo
        pango
        atk

        ## GTK+ Stack Libraries
        gtk2
        gdk-pixbuf
        glib
        dbus-glib
        at-spi2-core
        at-spi2-atk

        ## Qt Libraries
        qt4

        ## Sound libraries
        alsaLib
        openal

        ## SDL
        SDL
        SDL_image
        SDL_mixer
        SDL_ttf
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf

        # Imaging
        cups
        sane-backends

        # Trial Use
        libpng
        gtk3

      ] ++ config.environment.lsb.extraLibs;

    base-libs32 = pkgs.buildEnv {
      name = "fhs-base-libs32";
      paths = map lib.getLib (libsFromPkgs pkgs.pkgsi686Linux);
      extraOutputsToInstall = [ "lib" ];
      pathsToLink = [ "/lib" ];
      ignoreCollisions = true;
    };

    base-libs64 = pkgs.buildEnv {
      name = "fhs-base-libs64";
      paths = map lib.getLib (libsFromPkgs pkgs);
      extraOutputsToInstall = [ "lib" ];
      pathsToLink = [ "/lib" ];
      ignoreCollisions = true;
    };
  in lib.mkIf config.environment.lsb.enable (lib.mkMerge [
    {
      environment.sessionVariables.LD_LIBRARY_PATH_AFTER = "${base-libs64}/lib${
          lib.optionalString config.environment.lsb.support32Bit
          ":${base-libs32}/lib"
        }";

      environment.etc."lsb".source = pkgs.symlinkJoin {
        name = "lsb-combined";
        paths = [
          base-libs64
          base-libs32
        ];
      };

      environment.systemPackages = with pkgs;
        [
          # Core
          bc
          gnum4
          man
          lsb-release
          file
          psmisc
          ed
          gettext
          utillinux

          # Languages
          python2
          perl
          python3

          # Misc.
          pciutils
          which
          usbutils

          # Bonus
          bzip2
        ] ++ lib.optionals config.environment.lsb.enableDesktop [
          # Desktop
          xdg_utils
          xorg.xrandr
          fontconfig
          cups

          # Imaging
          foomatic_filters
          ghostscript
        ] ++ libsFromPkgs pkgs
        ++ lib.optionals (config.environment.lsb.support32Bit)
        (libsFromPkgs pkgs.pkgsi686Linux);

      # environment.ld-linux = true;
    }
  ]);

}
