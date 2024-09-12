#Removes created directory and export of chris titus config
rm -rf "$HOME/.config/zsh" && sudo sed -i '/export ZDOTDIR/d' /etc/zsh/zshenv
