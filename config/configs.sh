#!/bin/zsh

declare -A to_markdown=(
	["zsh"]="$HOME/.zshrc"
	["aliaszsh"]="$HOME/.aliasrc.zsh"
	["vim"]="$HOME/.vimrc"
	["nano"]="$HOME/.nanorc"
	["vscode_main"]="$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json"
	["vscode_git"]="$HOME/Documents/GIT/cursus/.vscode/settings.json"
	["vscode_keybindings"]="$HOME/.var/app/com.visualstudio.code/config/Code/User/keybindings.json"
	["sublimetext"]="$HOME/.config/sublime-text/Packages/User/Preferences.sublime-settings"
	["sublime_keymap"]="$HOME/.config/sublime-text/Packages/User/Default (Linux).sublime-keymap"
	["obsidian"]="$HOME/.var/app/md.obsidian.Obsidian/config/obsidian/Preferences"
	["bash"]="$HOME/.bashrc"
	["starship"]="$HOME/.config/starship.toml"
	["kitty"]="$HOME/.config/kitty/kitty.conf"
	["rofi"]="$HOME/.config/rofi/config.rasi"
	["frofi"]="$HOME/.config/rofi/favorites.sh"
	
)

#$HOME/Documents/Docs/configs
declare -A to_copy=(
	["zsh"]="$HOME/.zshrc"
	["aliaszsh"]="$HOME/.aliasrc.zsh"
	["vim"]="$HOME/.vimrc"
	["nano"]="$HOME/.nanorc"
	["vscode_git"]="$HOME/Documents/GIT/cursus/.vscode/settings.json"
	["vscode_keybindings"]="$HOME/.var/app/com.visualstudio.code/config/Code/User/keybindings.json"
	["vscode_snippets0"]="$HOME/.var/app/com.visualstudio.code/config/Code/User/snippets/markdown.json"
	["vscode_snippets1"]="$HOME/.var/app/com.visualstudio.code/config/Code/User/snippets/python.json"
	["vscode_snippets2"]="$HOME/.var/app/com.visualstudio.code/config/Code/User/snippets/shellscript.json"
	["sublimetext"]="$HOME/.config/sublime-text/Packages/User/Preferences.sublime-settings"
	["sublime_keymap"]="$HOME/.config/sublime-text/Packages/User/Default (Linux).sublime-keymap"
	["obsidian"]="$HOME/.var/app/md.obsidian.Obsidian/config/obsidian/Preferences"
	["bash"]="$HOME/.bashrc"
	["pip"]="$HOME/.config/pip/pip.conf"
	["npm"]="$HOME/package.json"
	["hzsh"]="$HOME/.zsh_history"
	["hbash"]="$HOME/.bash_history"
	["starship"]="$HOME/.config/starship.toml"
	["kitty"]="$HOME/.config/kitty/kitty.conf"
	["rofi"]="$HOME/.config/rofi/config.rasi"
	["frofi"]="$HOME/.config/rofi/favorites.sh"	
)
