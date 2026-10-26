# Environment variables for my personal Mac. Private values go in ~/.config/zsh/secrets.zsh.
{ ... }: {
    programs.zsh = {
        localVariables = {
            PATH="/usr/bin:$HOME/.ghcup/bin:$HOME/build/qt/6.8.2/macos/bin:$HOME/bin:/opt/homebrew/opt/zig/bin:/opt/homebrew/opt/qt@6/bin:/opt/homebrew/opt/postgresql@17/bin:/opt/homebrew/opt/libiconv/bin:$HOME/.cargo/bin:$HOME/.local/bin:/opt/homebrew/opt/openjdk@17/bin:$JAVA_HOME/bin:$HOME/Library/Application Support/Coursier/bin:$HOME/xpack-openocd-0.12.0-7/bin:$(brew --prefix)/opt/llvm/bin:$PATH";
            Qt6_DIR="$HOME/build/qt/6.8.2/macos";
            JAVA_HOME="$(/usr/libexec/java_home -v 17)";
            QT_PLUGIN_PATH="$HOME/build/qt/6.8.2/macos/plugins";
            PKG_CONFIG_PATH="$HOME/build/qt/6.8.2/macos/lib/pkgconfig";
            QML2_IMPORT_PATH="$HOME/build/qt/6.8.2/macos/qml";
            CXX=/usr/bin/clang++;
            RUST_BACKTRACE="1";
        };
    };
}
