# Git identity and defaults. A machine overrides them in ~/.config/git/local,
# which isn't in git (e.g. the work Mac sets its work email there).
{ lib, ... }: {
    programs.git = {
        enable = true;
        includes = [ { path = "~/.config/git/local"; } ];
        ignores = [ ".DS_Store" "**/.claude/settings.local.json" ];
        settings = {
            user.name = "jmin-pingu";
            user.email = lib.mkDefault "jonathanheromin@gmail.com";
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
        };
    };
}
