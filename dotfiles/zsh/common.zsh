#------------------------------
# Exports
#------------------------------

typeset -U path PATH
path=($path "$HOME/.local/bin")
export PATH

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export ZSH_PLUGINS="$HOME/.config/zsh/plugins"

#------------------------------
# History
#------------------------------
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

#------------------------------
# Navigation
#------------------------------

setopt AUTO_PUSHD           # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.
setopt GLOBDOTS

zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"

export _ZO_DATA_DIR=$XDG_CACHE_HOME
eval "$(zoxide init --cmd cd zsh)"

function fuzzy_open {

    local HOME_DIRS PWD_DIRS RECENT_DIRS DESTINATION

    HOME_DIRS=$(find -H -d 2 . $(echo $COMMON_DIRS))

    if [ "$(pwd)" = "$HOME" ]; then
        PWD_DIRS=""
    else
        PWD_DIRS=$(find -H . .)
    fi

    RECENT_DIRS=$(dirs | sed 's/\ /\n/g')

    DESTINATION=$(echo $HOME_DIRS $PWD_DIRS $RECENT_DIRS | fzf --preview "bat --color=always --style=numbers --line-range=:500 {}")

    if [[ "${DESTINATION:0:1}" == "~" ]]; then
        DESTINATION="${HOME}${DESTINATION:1}"
    fi

    if [ -d "$DESTINATION" ]; then
        cd $DESTINATION
    elif [ -f "$DESTINATION" ]; then
        opend $DESTINATION
    fi

    zle accept-line
}

zle -N fuzzy_open

#------------------------------
# Default Apps
#------------------------------
export EDITOR="nvim"

#------------------------------
# Alias
#------------------------------
alias find='fd'
alias grep='rg'
alias cat='bat --style=plain'
alias vim='nvim'

alias ll='ls -hlF --color'
alias lla='ls -ahlF --color'
alias free='free -m'
alias ..="cd .."
alias cp="cp -i"
alias mkdir="mkdir -pv"
alias bathelp='bat --plain --language=help'

# Text suffix aliases
alias -s md=nvim
alias -s txt=nvim
alias -s yml=nvim
alias -s yaml=nvim
alias -s toml=nvim
alias -s cfg=nvim
alias -s conf=nvim
alias -s ini=nvim
alias -s log=nvim
alias -s py=nvim
alias -s rs=nvim
alias -s go=nvim
alias -s ts=nvim
alias -s js=nvim
alias -s xml=nvim
alias -s json=code
alias -s csv=code

# Archive suffix aliases
alias -s zip='ex -d'
alias -s tar='ex -d'
alias -s tgz='ex -d'
alias -s gz='ex -d'
alias -s bz2='ex -d'
alias -s tbz2='ex -d'
alias -s xz='ex -d'
alias -s tarxz='ex -d'
alias -s zst='ex -d'
alias -s '7z'='ex -d'
alias -s rar='ex -d'
alias -s deb='ex -d'

#------------------------------
# Suggestions
#------------------------------
ZSH_AUTOSUGGEST_STRATEGY=(history_no_multiline completion)
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=forward-word

source $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh

_zsh_autosuggest_strategy_history_no_multiline() {
    emulate -L zsh
    setopt EXTENDED_GLOB

    local prefix="${1//(#m)[\\*?[\]<>()|^~#]/\\$MATCH}"
    local pattern="$prefix*"
    local entry
    local -i i

    for (( i = ${#history}; i >= 1; i-- )); do
        entry=${history[$i]}
        if [[ $entry == ${~pattern} && $entry != *$'\n'* ]]; then
            typeset -g suggestion="$entry"
            return 0
        fi
    done

    typeset -g suggestion=""
    return 1
}

#------------------------------
# Completions
#------------------------------
fpath=($ZSH_PLUGINS/zsh-completions/src $fpath)

autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit -i
done
compinit -i -C

zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"
zstyle ':completion:*' menu no

source $ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh
zstyle ':fzf-tab:*' continuous-trigger 'tab'

#------------------------------
# FZF
#------------------------------
FZF_ALT_C_COMMAND= FZF_CTRL_T_COMMAND= source <(fzf --zsh)

#------------------------------
# Keybindings
#------------------------------

bindkey -v
bindkey '^f' fuzzy_open
bindkey '^y' autosuggest-accept
bindkey '^n' forward-word
bindkey '^z' undo
bindkey "^[[3~" delete-char

#------------------------------
# Custom Functions
#------------------------------

### Extract file
# usage: ex [-d] <file>
ex () {
  local create_dir=false

  if [ "$1" = "-d" ] || [ "$1" = "--dir" ]; then
    create_dir=true
    shift
  fi

  if [ ! -f "$1" ] ; then
    echo "'$1' is not a valid file"
    return 1
  fi

  local file="$1"
  local base="${file%.*}"

  _ex_needs_dir() {
    local f="$1"
    case $f in
      *.zip)
        local entries
        entries=$(unzip -l "$f" 2>/dev/null | awk 'NR>3 {print $4}' | head -n -2)
        ;;
      *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.tar.zst|*.gz|*.bz2|*.xz|*.zst)
        entries=$(tar tf "$f" 2>/dev/null)
        ;;
      *.rar)
        entries=$(unrar l "$f" 2>/dev/null | awk 'NR>8 {print $NF}' | head -n -2)
        ;;
      *.7z)
        entries=$(7za l "$f" 2>/dev/null | awk 'NR>13 {print $NF}' | head -n -1)
        ;;
      *)
        return 1
        ;;
    esac
    local roots
    roots=$(echo "$entries" | sed 's|/.*||' | sort -u)
    [ "$(echo "$roots" | wc -l)" -gt 1 ] || echo "$entries" | grep -q '/'
  }

  if $create_dir && _ex_needs_dir "$file"; then
    mkdir -p "$base"
    case $file in
      *.zip)       unzip "$file" -d "$base" ;;
      *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.tar.zst)
          tar xf "$file" -C "$base" ;;
      *.gz)        gunzip -c "$file" > "$base/$(basename "$file" .gz)" && mv "$base/$(basename "$file" .gz)" "$base/" 2>/dev/null;;
      *.bz2)       bunzip2 -c "$file" > "$base/$(basename "$file" .bz2)" ;;
      *.xz)        xz -dc "$file" > "$base/$(basename "$file" .xz)" ;;
      *.zst)       unzstd -c "$file" > "$base/$(basename "$file" .zst)" ;;
      *.rar)       unar x "$file" -o "$base" ;;
      *.7z)        7za x "$file" -o"$base" ;;
      *.deb)       dpkg-deb -x "$file" "$base" ;;
      *.Z)         uncompress -c "$file" > "$base/$(basename "$file" .Z)" ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    case $file in
      *.tar.bz2)   tar xjf "$file"   ;;
      *.tar.gz)    tar xzf "$file"   ;;
      *.bz2)       bunzip2 "$file"   ;;
      *.rar)       unar x "$file"    ;;
      *.gz)        gunzip "$file"    ;;
      *.tar)       tar xf "$file"    ;;
      *.tbz2)      tar xjf "$file"   ;;
      *.tgz)       tar xzf "$file"   ;;
      *.zip)       unzip "$file"     ;;
      *.Z)         uncompress "$file";;
      *.7z)        7za x "$file"     ;;
      *.deb)       ar x "$file"      ;;
      *.tar.xz)    tar xf "$file"    ;;
      *.tar.zst)   unzstd "$file"    ;;
      *)           echo "'$file' cannot be extracted via ex()" ;;
    esac
  fi
}

### Open file in background in detached shell
# usage: opend <file>
opend() {
  if [ -f "$1" ] ; then
    nohup open "$1" > /dev/null 2>&1 &
  else
    echo "'$1' is not a valid file"
  fi
}

### Open colorized help
# usage: help <command>
help() {
    "$@" --help | bathelp
}

#------------------------------
# Theme
#------------------------------

autoload -Uz colors; colors
setopt PROMPT_SUBST

ZSH_THEME_GIT_PROMPT_PREFIX="%F{214}git:(%F{226}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{214}) %F{226}%1{✗%f"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{214})"

function git_prompt_info {
  local git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  if [[ -n $git_branch ]]; then
    local git_status=$(git status --porcelain 2>/dev/null)
    local git_dirty=""
    local git_clean=""

    if [[ -n $git_status ]]; then
      git_dirty="${ZSH_THEME_GIT_PROMPT_DIRTY}"
    else
      git_clean="${ZSH_THEME_GIT_PROMPT_CLEAN}"
    fi

    echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${git_branch}${git_dirty}${git_clean}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
  fi
}

PROMPT="%(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} ) %{$fg_bold[red]%}%~%{$reset_color%}"
PROMPT+=' $(git_prompt_info)'
PROMPT+='$ '

export BAT_THEME="Visual Studio Dark+"

#------------------------------
# Syntax Highlighting
#------------------------------
source $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ -f ~/.config/zsh/multiplexer.zsh ]] && source ~/.config/zsh/multiplexer.zsh
