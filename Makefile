copy:
	echo "copying ~/.vimrc"
	@cp ~/.vimrc ./.vimrc
	echo "copying ~/.config/ghostty"
	@cp -R ~/.config/ghostty ./.config/
	echo "copying ~/.config/alacritty"
	@cp -R ~/.config/alacritty ./.config/
	echo "copying ~/.config/coc"
	@cp -R ~/.config/coc ./.config/
	echo "copying ~/.config/gh"
	@cp -R ~/.config/gh ./.config/
	echo "copying ~/.config/sioyek"
	@cp  ~/.config/sioyek/*.config ./.config/sioyek
	echo "copying ~/.vim/*.json"
	@cp  ~/.vim/coc-settings.json ./.vim/coc-settings.json
	echo "copying ~/.tmux.conf"
	@cp ~/.tmux.conf ./.tmux.conf
	@cp ~/bin/chth ./chth

write:
	@cp -R ./.config/ ~/.config/
	@cp -R ./.tmux.conf ~/.tmux.conf
	@cp -R ./.vimrc ~/.vimrc
	@cp -R ./chth ~/bin/chth
	@cp -R ./.vim/coc-settings.json ~/.vim/coc-settings.json
