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
	@cp ~/bin/chth ./chth

write:
	@cp -R ./.config/ ~/.config/
	@cp -R ./.vimrc ~/.vimrc
	@cp -R ./chth ~/bin/chth
