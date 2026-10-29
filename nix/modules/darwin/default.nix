# Settings for every Mac. Hosts add their own in hosts/<name>/.
{ self, user, ... }: {
    imports = [
        ../core/packages.nix
        ./homebrew.nix
    ];

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    # Homebrew and other per-user settings apply to this user.
    system.primaryUser = user;

    # Caps Lock acts as Escape on every keyboard, built-in included.
    system.keyboard.enableKeyMapping = true;
    system.keyboard.remapCapsLockToEscape = true;

    # Free Ctrl-Space for zsh autosuggest. macOS uses it to switch input
    # sources (hotkey 60) by default.
    system.activationScripts.postActivation.text = ''
        launchctl asuser "$(id -u ${user})" sudo -u ${user} \
            defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
            -dict-add 60 '{ enabled = 0; value = { parameters = (32, 49, 262144); type = standard; }; }'
        activate=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
        if [ -x "$activate" ]; then
            launchctl asuser "$(id -u ${user})" sudo -u ${user} "$activate" -u
        fi
    '';

    # Set Git commit hash for darwin-version.
    system.configurationRevision = self.rev or self.dirtyRev or null;
}
