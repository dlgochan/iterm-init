#!/usr/bin/env bash
set -euo pipefail

# ---------- helpers ----------
log() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    err "This script is for macOS."
    exit 1
  fi
}

# macOS sed in-place suffix helper
sedi() { # sedi <pattern> <file>
  sed -i '' "$1" "$2"
}

# ---------- prerequisites ----------
require_macos

# Detect arch and set brew prefix
if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# ---------- Homebrew ----------
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "Homebrew already installed."
fi

# Ensure brew in PATH for this session
if ! echo ":$PATH:" | grep -q ":${BREW_PREFIX}/bin:"; then
  export PATH="${BREW_PREFIX}/bin:${PATH}"
fi

# Append brew init to shell profiles if missing
BREW_SHELL_LINE='eval "$('"${BREW_PREFIX}"'/bin/brew shellenv)"'
if ! grep -qsF "$BREW_SHELL_LINE" "$HOME/.zprofile" 2>/dev/null; then
  log "Configuring brew shellenv in ~/.zprofile"
  echo "$BREW_SHELL_LINE" >> "$HOME/.zprofile"
fi

# ---------- iTerm2 ----------
if ! brew list --cask iterm2 >/dev/null 2>&1; then
  log "Installing iTerm2 (cask)..."
  brew install --cask iterm2
else
  log "iTerm2 already installed."
fi

# ---------- oh-my-zsh ----------
export ZSH="$HOME/.oh-my-zsh"
if [[ ! -d "$ZSH" ]]; then
  log "Installing oh-my-zsh (non-interactive)..."
  export RUNZSH=no CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "oh-my-zsh already present."
fi

# ---------- brew packages ----------
log "Installing CLI packages (fzf, autojump, bat, git if missing)..."
brew install fzf autojump bat git || true

# fzf key-bindings & completion (non-interactive, no shell rc changes)
if [[ -x "$(brew --prefix)/opt/fzf/install" ]]; then
  log "Configuring fzf key bindings & completion..."
  yes | "$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc >/dev/null
fi

# ---------- zsh plugins (external) ----------
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

install_or_update_plugin() {
  local repo="$1" target="$2"
  if [[ -d "$target/.git" ]]; then
    log "Updating plugin $(basename "$target") ..."
    git -C "$target" pull --ff-only || true
  elif [[ -d "$target" ]]; then
    log "Plugin directory exists (non-git): $target"
  else
    log "Cloning plugin $(basename "$target") ..."
    git clone --depth=1 "$repo" "$target"
  fi
}

install_or_update_plugin "https://github.com/zsh-users/zsh-autosuggestions" \
  "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"

install_or_update_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
  "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

# ---------- powerlevel10k ----------
P10K_DIR="${ZSH_CUSTOM}/themes/powerlevel10k"
install_or_update_plugin "https://github.com/romkatv/powerlevel10k.git" "$P10K_DIR"

# ---------- .zshrc edits ----------
ZSHRC="$HOME/.zshrc"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
if [[ -f "$ZSHRC" ]]; then
  cp "$ZSHRC" "$ZSHRC.bak.$TIMESTAMP"
  log "Backed up current .zshrc -> $ZSHRC.bak.$TIMESTAMP"
else
  touch "$ZSHRC"
  log "Created new ~/.zshrc"
fi

# Ensure ZSH path line
if ! grep -qs '^export ZSH=' "$ZSHRC"; then
  echo 'export ZSH="$HOME/.oh-my-zsh"' >> "$ZSHRC"
fi

# Set theme to powerlevel10k
if grep -qs '^ZSH_THEME=' "$ZSHRC"; then
  sedi 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$ZSHRC"
else
  printf '\nZSH_THEME="powerlevel10k/powerlevel10k"\n' >> "$ZSHRC"
fi

# Normalize plugins block
# Target plugin set per your list:
# git extract colored-man-pages zsh-autosuggestions zsh-syntax-highlighting autojump fzf history-substring-search
PLUGINS_LINE='plugins=(git extract colored-man-pages zsh-autosuggestions zsh-syntax-highlighting autojump fzf history-substring-search)'

if grep -qs '^plugins=' "$ZSHRC"; then
  sedi "s|^plugins=.*|$PLUGINS_LINE|" "$ZSHRC"
else
  printf '\n%s\n' "$PLUGINS_LINE" >> "$ZSHRC"
fi

# Ensure oh-my-zsh is sourced exactly once
if ! grep -qs '^source \$ZSH/oh-my-zsh\.sh' "$ZSHRC"; then
  printf '\nsource $ZSH/oh-my-zsh.sh\n' >> "$ZSHRC"
fi

# fzf shell integration (if brew installed it)
FZF_ZSH="$("$(brew --prefix)"/bin/brew --prefix fzf 2>/dev/null)/shell/key-bindings.zsh"
if [[ -f "$FZF_ZSH" ]] && ! grep -qsF "$FZF_ZSH" "$ZSHRC"; then
  printf '\n# fzf key bindings\n[ -f "%s" ] && source "%s"\n' "$FZF_ZSH" "$FZF_ZSH" >> "$ZSHRC"
fi

# autojump init (oh-my-zsh plugin usually handles this; add safety source)
AUTOJUMP_ZSH="$("$(brew --prefix)"/bin/brew --prefix autojump 2>/dev/null)/etc/profile.d/autojump.sh"
if [[ -f "$AUTOJUMP_ZSH" ]] && ! grep -qsF "$AUTOJUMP_ZSH" "$ZSHRC"; then
  printf '\n# autojump init (safety)\n[ -f "%s" ] && source "%s"\n' "$AUTOJUMP_ZSH" "$AUTOJUMP_ZSH" >> "$ZSHRC"
fi

# Ensure p10k per-user config is sourced if present
if ! grep -qs '\[\[ -r ~/.p10k\.zsh \]\] && source ~/.p10k\.zsh' "$ZSHRC"; then
  printf '\n[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh\n' >> "$ZSHRC"
fi

# NOTE: zsh-syntax-highlighting는 마지막에 로드되는 것이 권장.
# oh-my-zsh plugin 메커니즘을 쓰므로 plugins 배열의 마지막쪽에 배치되어 있음.

# ---------- final ----------
log "Done. Reloading ~/.zshrc"
# Reload only if we are in zsh
if [[ -n "${ZSH_VERSION:-}" ]]; then
  # shellcheck disable=SC1090
  source "$ZSHRC" || warn "Could not source ~/.zshrc in current shell."
else
  warn "You are not in zsh. Open a new terminal or run: zsh -l"
fi

log "Tip: If Powerlevel10k wizard doesn't start automatically, run: p10k configure"

