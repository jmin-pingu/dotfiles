copy:
	echo "copying ~/.vimrc"
	@cp ~/.vimrc ./.vimrc
	echo "copying ~/.config/ghostty"
	@cp -R ~/.config/ghostty ./.config/ghostty
	echo "copying ~/.config/alacritty"
	@cp -R ~/.config/alacritty ./.config/alacritty
	echo "copying ~/.config/coc"
	@cp -R ~/.config/coc ./.config/coc
	echo "copying ~/.config/gh"
	@cp -R ~/.config/gh ./.config/gh
	echo "copying ~/.config/sioyek"
	@cp -R ~/.config/sioyek ./.config/sioyek

write:
	@cp -R ./.config/sioyek ~/.config/sioyek 
	@cp -R ./.vimrc ~/.vimrc
