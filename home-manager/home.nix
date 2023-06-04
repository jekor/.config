# -*- compile-command: "home-manager switch -b backup" -*-

{ config, pkgs, ... }:
let
  private = import ./private-vars.nix;
in {
  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        insert_final_newline = false;
        indent_size = 2;
        indent_style = "space";
      };
      "*.py"= {
        indent_size = 4;
      };
      "*.rs" = {
        indent_size = 4;
      };
      "Makefile" = {
        indent_style = "tab";
      };
    };
  };

  fonts.fontconfig.enable = true;

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    theme = {
      name = "Obsidian-2";
      package = pkgs.theme-obsidian2;
    };
    iconTheme = {
      name = "Obsidian";
      package = pkgs.iconpack-obsidian;
    };
  };

  home = {
    username = "jekor";
    homeDirectory = "/home/jekor";
    stateVersion = "22.11";
  };

  home.pointerCursor = {
    name = "Quintom_Ink";
    package = pkgs.quintom-cursor-theme;
    x11.enable = true;
    gtk.enable = true;
  };

  home.file.".aspell.conf".text = "data-dir ${pkgs.aspell}/lib/aspell";

  home.packages = with pkgs; [ # applications
    blender # https://www.blender.org/
    dbeaver # https://dbeaver.io/
    digikam # https://www.digikam.org/
    gimp # https://www.gimp.org/
    inkscape # https://inkscape.org/
    ipe # https://ipe.otfried.org/
    libreoffice-fresh # https://www.libreoffice.org/
    qbittorrent # https://www.qbittorrent.org/
    remmina # https://remmina.org/
    scribus # https://www.scribus.net/
    signal-desktop # https://signal.org/en/download/
    xfce.thunar # https://docs.xfce.org/xfce/thunar/start
  ] ++ [ # utilities
    buku # https://github.com/jarun/buku
    choose # https://github.com/theryangeary/choose
    diskonaut # https://github.com/imsnif/diskonaut
    dogdns # https://github.com/ogham/dog
    dua # https://github.com/Byron/dua-cli/
    duf # https://github.com/muesli/duf
    gping # https://github.com/orf/gping
    lsof # https://github.com/lsof-org/lsof
    trippy # https://trippy.cli.rs/
    xorg.xev # https://gitlab.freedesktop.org/xorg/app/xev
  ] ++ [ # DBus
    gnome3.file-roller # Thunar
    gnome3.sushi # Thunar
    xfce.tumbler # Thunar
  ] ++ [ # fonts
    nerdfonts # https://www.nerdfonts.com/
  ] ++ (with aspellDicts; [ # aspell, used by recoll and Emacs
    aspell
    en
    en-computers
    en-science
    es
    fr
  ]);

  home = {
    sessionPath = ["$HOME/bin"];
    sessionVariables = {
      BROWSER = "${config.programs.firefox.package}/bin/firefox";
      EDITOR = "${config.programs.emacs.package}/bin/emacsclient";
    };
  };

  imports = [
    ./private.nix
  ];

  nix = {
    enable = true;
    package = pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      nerdfonts = super.nerdfonts.override {
        fonts = [
          "CodeNewRoman"
          "DejaVuSansMono"
          "Inconsolata"
        ];
      };
      xfce = with super; xfce // {
        thunar = (xfce.thunar.override {
          thunarPlugins = [ xfce.thunar-archive-plugin ];
        });
      };
    })
  ];

  programs.broot.enable = true;

  programs.btop.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.emacs =
    let findPackages = pattern: pkgSet: with builtins; with pkgs.lib;
          map (x: attrsets.getAttrFromPath (splitString "." x) pkgSet) (flatten (filter isList (split pattern (readFile ../emacs/init.org + readFile ../emacs/private.org))));
    in {
    enable = true;
    package = with pkgs; emacs.overrideAttrs (old: {
      postFixup = old.postFixup + ''
        wrapProgram "$out/bin/emacs" --prefix PATH : ${lib.makeBinPath (findPackages "https://search\\.nixos\\.org/packages\\?show=([a-zA-Z0-9\\.-]+)" pkgs)}
      '';
    });
    extraPackages = epkgs: findPackages "https://elpa\\.gnu\\.org/packages/([a-z0-9-]+)" epkgs
                        ++ findPackages "https://melpa\\.org/#/([a-z0-9-]+)" epkgs.melpaPackages;
  };

  programs.firefox = let
    defaults = {
      extensions = map (x: pkgs.fetchFirefoxAddon (with builtins; {
        name = head (builtins.match ".*/file/[0-9]+/([a-zA-Z_]+)-.*" (head x));
        url = head x;
        hash = pkgs.lib.last x;
      })) ([
        ["https://addons.mozilla.org/firefox/downloads/file/3769984/bukubrow-5.0.3.0.xpi" "sha256-TJQk0PE9+PH2rGBTAsQrsw88E463bI1M7V1FpjeUKRM="]
        ["https://addons.mozilla.org/firefox/downloads/file/4053589/darkreader-4.9.62.xpi" "sha256-5TeizuRe18JveezT7TYmIOPwDSTBWFMqWOFjpjo9YMw="]
        ["https://addons.mozilla.org/firefox/downloads/file/4036604/tridactyl_vim-1.23.0.xpi" "sha256-CLevl77wUwCrOsOtchMi/wBQVjEjNIJWj8RInBbVG3E="]
      ] ++ private.firefox.extensions);
      settings = {
        "browser.newtab.extensionControlled" = true;
        "browser.startup.page" = 3; # restore previous session
      };
    };
  in {
    enable = true;
    package = with pkgs; wrapFirefox ((firefox-unwrapped.override {
      drmSupport = false;
      privacySupport = true;
    }).overrideAttrs (old: {
      MOZ_REQUIRE_SIGNING = false;
    })) {
      cfg = {
        enableBukubrow = true;
        enableTridactylNative = true;
      } // private.firefox.cfg;
      extraPolicies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        EnableTrackingProtection.Value = true;
        EncryptedMediaExtensions.Enabled = false;
        EncryptedMediaExtensions.Locked = true;
        FirefoxHome.Pocket = false;
        FirefoxHome.Snippets = false;
        NewTabPage = false;
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
        UserMessaging = {
          ExtensionRecommendations = false;
          FeatureRecommendations = false;
          MoreFromMozilla = false;
          SkipOnboarding = true;
          WhatsNew = false;
        };
      };
      nixExtensions = defaults.extensions;
    };
    profiles = builtins.mapAttrs (n: p: {
      id = p.id;
      settings = (p.settings or {}) // defaults.settings // {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
      userChrome = ''
        @namespace url(http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul);

        #navigator-toolbox {
          --toolbar-field-focus-border-color: ${p.color};
        }
      '' + builtins.readFile ../userChrome-firefox.css;
    }) ({
      jekor = {
        id = 0;
        color = "hsl(150, 100%, 60%)";
      };
    } // private.firefox.profiles);
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
    '';
    plugins = with pkgs.fishPlugins; [
      { name = "autopair.fish"; src = autopair-fish.src; } # skeleton pairs
      { name = "done"; src = done.src; } # notify when long-running command completes
      { name = "fzf"; src = fzf-fish.src; } # fuzzy find
      { name = "hydro"; src = hydro.src; } # prompt
      { name = "sponge"; src = sponge.src; } # clean errors from command history
    ];
    package = with pkgs; fish.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs or [] ++ [pkgs.makeWrapper];
      postFixup = ''
        wrapProgram "$out/bin/fish" --prefix PATH : ${lib.makeBinPath (with pkgs; [
          bat
          fd
          fzf
        ])}
      '';
    });
  };

  programs.git = {
    enable = true;
    extraConfig = {
      pull.ff = "only";
      init.defaultBranch = "master";
    };
    ignores = [
      "*~"
    ];
    signing = {
      key = null;
      signByDefault = true;
    };
    userName = "Chris Forno";
    userEmail = "jekor@jekor.com";
  };

  programs.home-manager.enable = true;

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      mpris
    ];
  };

  programs.nix-index.enable = true;

  programs.obs-studio = {
    enable = true;
    package = with pkgs; obs-studio.overrideAttrs (old: {
      postFixup = old.postFixup + ''
        wrapProgram "$out/bin/obs" --set QT_SCALE_FACTOR 2
      '';
    });
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  programs.pandoc.enable = true;

  programs.rofi = {
    enable = true;
    extraConfig = {
      dpi = 1;
    };
    plugins = with pkgs; [
      rofi-calc
    ];
    theme = ../rofi/theme.rasi;
  };

  programs.yt-dlp.enable = true;

  programs.zathura = {
    enable = true;
    options = {
      recolor = true;
    };
  };

  services.dunst.enable = true;

  services.flameshot = {
    enable = true;
    settings = {
      General = {
        disabledTrayIcon = true;
        savePath = "${config.home.homeDirectory}/screenshots";
        showHelp = false;
      };
    };
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  services.picom = {
    enable = true;
    inactiveOpacity = 0.8;
  };

  services.playerctld.enable = true;

  services.screen-locker = {
    enable = true;
    lockCmd = "XDG_SEAT_PATH=/org/freedesktop/DisplayManager/Seat0 ${pkgs.lightdm}/bin/dm-tool lock";
  };

  services.syncthing.enable = true;

  services.unclutter = {
    enable = true;
    extraOptions = [
      "exclude-root"
    ];
  };

  services.xsuspender = {
    enable = true;
    defaults = {
      resumeEvery = 55;
      resumeFor = 5;
      sendSignals = true;
    };
    rules = {
      chromium = {
        matchWmClassContains = "chromium";
        suspendSubtreePattern = "chromium";
      };
      firefox = {
        matchWmClassContains = "Navigator";
        matchWmClassGroupContains = "firefox";
        suspendDelay = 20;
        suspendSubtreePattern = "\/(firefox|plugin-container)";
      };
      qBittorrent = {
        matchWmClassContains = "qbittorrent";
        resumeEvery = 5;
        resumeFor = 1;
        suspendDelay = 60;
      };
    };
  };

  systemd.user.services.barriers = {
    Unit = {
      Description = "Barrier Server daemon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service.ExecStart = "${pkgs.barrier}/bin/barriers --address :24800 --profile-dir ${config.home.homeDirectory}/.config/barrier -f";
  };

  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = with pkgs.lib.attrsets;
        genAttrs ["application/pdf" "application/epub+zip"] (x: "org.pwmt.zathura.desktop") //
        genAttrs (map (s: "x-scheme-handler/${s}") ["chrome" "http" "https"] ++ ["text/html"]) (x: "firefox.browser");
    };
  };

  xresources.properties = {
    "Xft.antialias" = true;
    "Xft.rgba" = "rgb";
    "Xft.hinting" = true;
    "Xft.hintstyle" = "hintslight";
    "Xft.autohint" = false;
    "Xft.lcdfilter" = "lcddefault";
  };

  xsession = {
    enable = true;
    initExtra = ''
      ibus-daemon --xim &
    '';
    windowManager.xmonad = let
      rofi = "${config.programs.rofi.finalPackage}/bin/rofi";
      shortcuts = {
        "M-a" = "${pkgs.autorandr}/bin/autorandr --change";
        "M-b" = "${rofi} -show windowcd -show-icons -window-format '{t}'";
        "M-w" = "${rofi} -show window -show-icons";
        "M-c" = "${rofi} -show calc -modi calc -no-show-match -no-sort";
        "M-f" = "${pkgs.xfce.thunar}/bin/thunar";
        "M-i" = "${pkgs.xcolor}/bin/xcolor -s"; # copy color from screen to clipboard
        "M-n" = "${pkgs.playerctl}/bin/playerctl --player playerctld next";
        "M-p" = "${pkgs.playerctl}/bin/playerctl --player playerctld play-pause";
        "M-r" = "${rofi} -show run";
        "M-s" = "${pkgs.maim}/bin/maim -u -s ~/screenshots/$(date +%s).png";
        "M-t" = "${pkgs.mlterm}/bin/mlterm -e ${config.programs.fish.package}/bin/fish";
        "M-u" = "${pkgs.rofimoji}/bin/rofimoji -a clipboard --files all"; # 😄
        "M-=" = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "M--" = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "M-S-a" = "${pkgs.pavucontrol}/bin/pavucontrol";
        "M-S-b" = "${pkgs.rofi-bluetooth}/bin/rofi-bluetooth";
        "M-S-r" = "${rofi} -show drun -modi drun -show-icons";
        "M-S-s" = "${config.services.flameshot.package}/bin/flameshot gui";
        "M-C-a" = "${pkgs.arandr}/bin/arandr";
        "M-S-t" = "${pkgs.mlterm}/bin/mlterm -e ${config.programs.btop.package}/bin/btop";
        "M-C-l" = config.services.screen-locker.lockCmd;
      };
    in {
      enable = true;
      enableContribAndExtras = true;
      config = pkgs.writeText "xmonad.hs" ''
        ${builtins.readFile ../xmonad.hs}
        shortcuts = [${builtins.concatStringsSep "," (pkgs.lib.attrsets.mapAttrsToList (k: v: ''("${k}", spawn "${v}")'') shortcuts)}]
      '';
    };
  };
}
