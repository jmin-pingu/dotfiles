# Git identity and defaults.
{ ... }: {
    programs.git = {
        enable = true;
        userName = "jmin-pingu";
        userEmail = "jonathanheromin@gmail.com";
        ignores = [ ".DS_Store" ];
        extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
        };
    };
}
