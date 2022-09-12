# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
source /usr/share/git/completion/git-prompt.sh

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  # We have color support; assume it's compliant with Ecma-48
  # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
  # a case would tend to support setf rather than setaf.)
  color_prompt=yes
    else
  color_prompt=
    fi
fi

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/';
}

if [ "$color_prompt" = yes ]; then
PS1='\[\e[1;31m\]\w \[\e[0m\]$(__git_ps1)\[\033[00m\] \[\e[1;34m\]> \[\e[0m\]'
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# add my scripts folder to my path
PATH=/home/paul/data/scripts/:"$PATH"

# custom functions
bu() { cp "$@" "$@.backup-`date +%s`"; echo "`date +%Y-%m-%d` backed up $PWD/$@" >> ~/.backups.log; } 
colortail() { tail -500 $*|ccze -A; }

sink()
{ 
    CURRENTSINK=$(pacmd list-sinks | awk '/index:/{i++} /* index:/{print $3}');
    SINK=$(pactl list short sinks | grep analog-stereo | awk '{print $1}');

    if [[ ! $CURRENTSINK == $SINK ]]; 
    then
        pacmd set-default-sink $SINK;
    fi
}

lspac()
{
    sudo pacman -Qei $(pacman -Qu|cut -d" " -f 1)|awk ' BEGIN {FS=":"}/^Name/{printf("\033[1;36m%s\033[1;37m", $2)}/^Description/{print $2}' &&
    echo "AUR: " &&
    sudo pacman -Qmi $(pacman -Qu|cut -d" " -f 1)|awk ' BEGIN {FS=":"}/^Name/{printf("\033[1;32m%s\033[1;37m", $2)}/^Description/{print $2}'
}

cheat()
{
    curl cheat.sh/$1
}

extbackup()
{
    rm -rdf $HOME/data/gnome-extensions
    cp -r $HOME/.local/share/gnome-shell/extensions $HOME/data/gnome-extensions
}

extrestore()
{
    cp -r $HOME/data/gnome-extensions $HOME/.local/share/gnome-shell/extensions
}

vm()
{
    read -p "Wanna set the governor to performance? [Y/n]: " perf
    if [ $perf = 'y' ]
    then
        for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "performance" | sudo tee -a $file; done
    fi

    sudo virsh allocpages 1G 8
    sudo virsh start win11
    sudo virsh attach-device win11 --file /home/paul/data/qemu/attach-mouse.xml --live
    sudo virsh attach-device win11 --file /home/paul/data/qemu/attach-bluetooth.xml --live
}

freevm()
{
    sudo virsh allocpages 1G 0
    read -p "Wanna set the governor to powersave? [Y/n]: " perf
    if [ $perf = 'y' ]
    then
        for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "powersave" | sudo tee -a $file; done
    fi
}

powersave() 
{
    for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "powersave" | sudo tee -a $file; done
}

turbo() 
{
    for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "performance" | sudo tee -a $file; done
}

omm(){
    shopt -s nullglob
    for g in `find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V`; do
        echo "IOMMU Group ${g##*/}:"
        for d in $g/devices/*; do
            echo -e "\t$(lspci -nns ${d##*/})"
        done;
    done;
}

# some more ls aliases
alias c='clear'
alias cdev='cd ~/data/dev'
alias ct='colortail'
alias ctl='sudo systemctl'
alias d='dotfiles'
alias dfa='dotfiles add'
alias dfc='dotfiles commit'
alias dfp='dotfiles push'
alias dfs='dotfiles status'
alias dg='echo "pacman -U /var/cache/pacman/pkg/"'
alias docker='sudo docker'
alias dotfiles='/usr/bin/git --git-dir=/home/paul/.dotfiles/ --work-tree=/home/paul'
alias eb='sudo nano ~/.bashrc'
alias egrep='egrep --color=auto'
alias errors='sudo journalctl -xb -p 0..3 && sudo dmesg -l err,warn'
alias fgrep='fgrep --color=auto'
alias firewall='sudo iptables -L -n -v --line-numbers'
alias fn='echo 0 | sudo tee /sys/module/hid_apple/parameters/fnmode'
alias fuck='sudo $(history -p \!\!)'
alias grep='grep --color=auto'
alias in='yay -S'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alhF'
alias lb='. ~/.bashrc'
alias logs='sudo find /var/log -type f -exec file {} \; | grep '\''text'\'' | cut -d'\'' '\'' -f1 | sed -e'\''s/:$//g'\'' | grep -v '\''[0-9]$'\'' | xargs tail -f'
alias ls='ls --color=auto'
alias moon='curl wttr.in/moon'
alias nan='sudo nano'
alias nocomment='sudo grep -Ev '\''^(#|$)'\'''
alias pacclean='sudo paccache -r && sudo pacman -Sc && sudo pacman -Rns $(pacman -Qtdq)'
alias pacman='sudo pacman'
alias ports='sudo netstat -tulpn'
alias ps='ps -elf | grep'
alias rd='ssh pi@rainbowdash -i ~/keys/pi-prvt-ssh'
alias remove-orphans='sudo pacman -Rns $(pacman -Qtdq)'
alias screen='xrandr --output DP-4 --mode 1920x1080 --rate 240 && xscreensaver'
alias tv='exp libreelec ssh root@libreelec.lan -p 22'
alias ug='less /var/log/pacman.log | grep upgraded'
alias update='yay -Syu'
alias vmbackup='sudo virsh dumpxml'
alias weather='curl wttr.in/London'
alias tpm='swtpm socket --tpmstate dir=/tmp/emulated_tpm --ctrl type=unixio,path=/tmp/emulated_tpm/swtpm-sock --log level=20 --tpm2'
alias cpu='sudo i7z'
alias snap='sudo snapper -c root create --description'
alias scrub='sudo btrfs scrub start -B /'
alias ff='wmctrl -r :ACTIVE: -b toggle,fullscreen'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi