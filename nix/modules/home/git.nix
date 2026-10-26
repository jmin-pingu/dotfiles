# Git identity and defaults. Hosts can override the email (see hosts/work-mac/home.nix).
{ lib, ... }: {
    programs.git = {
        enable = true;
        userName = "jmin-pingu";
        userEmail = lib.mkDefault "jonathanheromin@gmail.com";
        ignores = [ ".DS_Store" ];
        extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
        };
    };
}
