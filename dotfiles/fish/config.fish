# Fish configuration file

if status is-interactive
	# Commands to run in interactive sessions can go here

	# Initialize tools and environment variables
	if type -q fastfetch
		fastfetch
	end

	# Initialize Starship prompt if installed
	if type -q starship
		starship init fish | source
	end

	# Initialize Zoxide if available
	if type -q zoxide
		zoxide init fish | source
	end

	# Initialize Atuin if available
	if type -q atuin
		atuin init fish | source
	end

	# Set GPG_TTY for gpg-agent
	if type -q tty
		set -gx GPG_TTY (tty)
	end
end

# Load Homebrew environment if available
set -l __brew_path /home/linuxbrew/.linuxbrew/bin/brew
if test -x $__brew_path
	command $__brew_path shellenv | source
end

# Set the default editor
set -gx EDITOR micro
set -gx VISUAL micro
alias vim 'micro'
alias nano 'micro'

# Automatically list directory contents on cd
function cd
    builtin cd $argv
    ls
end

# Alias to remove a directory and all files (explicit command path)
function rmd
	command /bin/rm --recursive --force --verbose $argv
end

# Disable the bell (Fish equivalent)
set -U fish_bell off

# Expand the history size (Fish equivalent)
set -U fish_history_max_count 10000

# Enable colorized output for ls-compatible tools
set -gx CLICOLOR 1
set -gx LS_COLORS 'no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Color for manpages in less makes manpages a little easier to read
set -gx LESS_TERMCAP_mb '\e[01;31m'
set -gx LESS_TERMCAP_md '\e[01;31m'
set -gx LESS_TERMCAP_me '\e[0m'
set -gx LESS_TERMCAP_se '\e[0m'
set -gx LESS_TERMCAP_so '\e[01;44;33m'
set -gx LESS_TERMCAP_ue '\e[0m'
set -gx LESS_TERMCAP_us '\e[01;32m'

############################################
#                 ALIAS'S                  #
############################################
# Alias's to change the directory
alias web 'cd /var/www/html'
alias config 'cd ~/.config'
alias dl 'cd ~/Downloads'
alias docs 'cd ~/Documents'
alias pics 'cd ~/Pictures'
alias vids 'cd ~/Videos'
alias music 'cd ~/Music'
alias desk 'cd ~/Desktop'
alias projects 'cd ~/Projects'
# Edit this fish config file
alias efish 'micro ~/.config/fish/config.fish'
# alias to show the date
alias da 'date "+%Y-%m-%d %A %T %Z"'
# Miscellaneous aliases
alias cp 'cp -i' # Interactive copy
alias mv 'mv -i' # Interactive move
alias rm 'trash -v' # Move to trash
alias mkdir 'mkdir -p' # Create parent directories
alias ps 'ps auxf' # Tree view of processes
alias ping 'ping -c 10' # Ping with count
alias less 'less -R' # Less with raw control chars
alias multitail 'multitail --no-repeat -c' # Multitail with no repeat and color
alias a 'aichat' # AI chat alias
alias grep 'ugrep --color=always -T' # Grep with color and tree view
# Alias's for TUI tools
alias sysctl 'systemctl-tui' # Systemctl TUI alias
alias stui 'systemctl-tui' # Systemctl TUI alias
alias blui 'bluetui' # Bluetui alias
# Change directory aliases
alias home 'cd ~'
alias cd.. 'cd ..'
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
# Remove a directory and all files (defined above)
# Alias's for multiple directory listing commands
# Use `command` to prevent alias-chaining and ensure coreutils ls is called
alias la 'command ls -Alh'
alias ls 'command ls -aFh --color=always'
alias lx 'command ls -lXBh'
alias lk 'command ls -lSrh'
alias lc 'command ls -ltcrh'
alias lu 'command ls -lturh'
alias lr 'command ls -lRh'
alias lt 'command ls -ltrh'
alias lw 'command ls -xAh'
alias ll 'command ls -Fls'
alias labc 'command ls -lap'
alias lla 'command ls -Al'
alias las 'command ls -A'
alias lls 'command ls -l'

# Pipeline-based list helpers as functions for clarity and correctness
function lm
	command ls -alh | command more
end

function lf
	command ls -l | ugrep -E -v '^d'
end

function ldir
	command ls -l | ugrep -E '^d'
end
# alias chmod commands
alias mx 'chmod a+x'
alias 000 'chmod -R 000'
alias 644 'chmod -R 644'
alias 666 'chmod -R 666'
alias 755 'chmod -R 755'
alias 777 'chmod -R 777'
# Search command line history
function h
	history | ugrep 
end
# Search running processes
function p
	command ps aux | ugrep 
end

function topcpu
	/bin/ps -eo pcpu,pid,user,args | command sort -k 1 -r | command head -10
end
# Search files in the current folder
function f
	command find . | ugrep 
end
# Show open ports
alias openports 'netstat -nape --inet'
# Alias's for safe and forced reboots
alias rebootsafe 'sudo shutdown -r now'
alias rebootforce 'sudo shutdown -r -n now'
# Alias's to show disk space and space used in a folder
function diskspace
	command du -S | command sort -n -r | command more
end
alias folders 'du -h --max-depth=1'
function folderssort
	command find . -maxdepth 1 -type d -print0 | command xargs -0 du -sk | command sort -rn
end
alias tree 'tree -CAhF --dirsfirst'
alias treed 'tree -CAFd'
alias mountedinfo 'df -hT'
# Alias's for archives
alias mktar 'tar -cvf'
alias mkbz2 'tar -cvjf'
alias mkgz 'tar -cvzf'
alias untar 'tar -xvf'
alias unbz2 'tar -xvjf'
alias ungz 'tar -xvzf'
# alias to cleanup unused podman containers, images, networks, and volumes
function podman-clean
	podman container prune -f
	podman image prune -f
	podman network prune -f
	podman volume prune -f
end
