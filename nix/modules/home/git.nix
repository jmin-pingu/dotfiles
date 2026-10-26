# Git identity and defaults. A machine overrides them in ~/.config/git/local,
# which isn't in git (e.g. the work Mac sets its work email there).
{ lib, ... }: {
    programs.git = {
        enable = true;
        userName = "jmin-pingu";
        userEmail = lib.mkDefault "jonathanheromin@gmail.com";
        includes = [ { path = "~/.config/git/local"; } ];
        ignores = [ ".DS_Store" ];
        extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
        };
    };
}
