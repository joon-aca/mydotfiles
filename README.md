# My Dotfiles - Modern macOS Development Setup

Optimized configuration files for a modern macOS development environment with focus on performance, productivity, and developer experience.

## Philosophy

- **Modern CLI tools** over traditional Unix utilities
- **Fast and minimal** shell configuration without Oh-My-Zsh bloat
- **AI-enhanced** development workflow
- **Apple Silicon optimized** where applicable

## Structure

```
mydotfiles/
├── Brewfile              # Homebrew packages (modern CLI tools)
├── shell/                # Shell configuration
│   ├── .zshrc           # Main zsh config (starship, zoxide, fzf)
│   ├── aliases.zsh      # Modern command aliases
│   └── functions.zsh    # Useful shell functions
├── git/                  # Git configuration
│   └── .gitconfig       # Git config with delta integration
├── starship/             # Starship prompt
│   └── starship.toml    # Prompt configuration
├── ssh/                  # SSH configuration (no private keys)
│   └── config
├── claude/               # Claude Code settings
│   ├── CLAUDE.md
│   └── .claude.json
├── cursor/               # Cursor IDE settings
│   ├── argv.json
│   ├── cli-config.json
│   ├── mcp.json
│   └── extensions_list.txt
└── vscode/               # VS Code settings
    ├── argv.json
    └── extensions_list.txt
```

## Key Features

### Shell Enhancements
- **Starship** - Beautiful, fast, customizable prompt
- **zoxide** - Smarter cd command with frecency
- **fzf** - Fuzzy finder for files, history, and more
- **zsh-autosuggestions** - Fish-like autosuggestions from history
- **zsh-syntax-highlighting** - Command syntax highlighting

### Modern CLI Replacements
- **eza** → Better `ls` with git integration and icons
- **bat** → Better `cat` with syntax highlighting
- **ripgrep** → Better `grep` (blazing fast)
- **fd** → Better `find` (simple and fast)
- **delta** → Better `git diff` with side-by-side view
- **dust** → Better `du` (disk usage)
- **procs** → Better `ps` (process viewer)
- **btop** → Better `top` (system monitor)

### Development Tools
- **Git & GitHub CLI** - Version control with enhanced workflows
- **fnm** - Fast Node Manager (faster than nvm)
- **Neovim & tmux** - Modern terminal-based editing
- **httpie** - User-friendly HTTP client

### AI & Productivity
- **Ollama** - Run LLMs locally
- **Gemini CLI** - Google's Gemini from terminal

## Installation

### Quick Start

1. **Clone this repo**
   ```bash
   git clone https://github.com/joon-aca/mydotfiles.git ~/mydotfiles
   cd ~/mydotfiles
   ```

2. **Install Homebrew packages**
   ```bash
   brew bundle install
   ```

3. **Copy shell configuration**
   ```bash
   cp shell/.zshrc ~/.zshrc
   cp -r shell/aliases.zsh shell/functions.zsh ~/.zsh/
   ```

4. **Install Starship config**
   ```bash
   mkdir -p ~/.config
   cp starship/starship.toml ~/.config/starship.toml
   ```

5. **Install Git config**
   ```bash
   cp git/.gitconfig ~/.gitconfig
   # Update user.name and user.email as needed
   ```

6. **Setup fzf shell integration**
   ```bash
   $(brew --prefix)/opt/fzf/install
   ```

### Selective Installation

You can also cherry-pick configurations:
- Shell only: Just copy `.zshrc` and `.zsh/` files
- Git only: Copy `.gitconfig`
- Packages only: Run `brew bundle install`

## Usage

### Shell Shortcuts

**Navigation**
- `z [directory]` - Jump to frecent directories (zoxide)
- `Ctrl+R` - Fuzzy search command history (fzf)
- `Ctrl+T` - Fuzzy find files (fzf)
- `Alt+C` - Fuzzy cd into directory (fzf)

**Modern CLI**
- `ls` → eza with icons
- `ll` → Long list with git status
- `cat` → bat with syntax highlighting
- `grep` → ripgrep (fast search)

**Git Aliases**
- `git s` - Short status
- `git l` - Pretty log graph
- `git d` - Diff with delta
- `git ds` - Diff staged
- `git cm "message"` - Quick commit
- `git pf` - Push force with lease (safer)

See `git/.gitconfig` for full list of aliases.

### Customization

**Starship Prompt**
Edit `~/.config/starship.toml` to customize your prompt appearance.

**Shell Aliases**
Edit `~/.zsh/aliases.zsh` for custom shortcuts.

**fzf Settings**
Modify `FZF_DEFAULT_OPTS` in `.zshrc` for preview and search behavior.

## Node Version Management

This setup uses **fnm** (Fast Node Manager) instead of nvm for better performance:

```bash
# Install specific Node version
fnm install 20

# Use specific version
fnm use 20

# Set default
fnm default 20

# Auto-switch based on .nvmrc
# (already configured in .zshrc)
```

If you prefer **nvm**, edit `.zshrc` and uncomment the nvm section.

## Maintenance

### Update packages
```bash
brew update && brew upgrade
brew bundle dump --force  # Update Brewfile
```

### Update shell plugins
```bash
brew upgrade zsh-autosuggestions zsh-syntax-highlighting
```

## Machine-Specific Branches

This repository uses machine-specific branches:
- `joon-m5` - MacBook Air M2 (2026)
- `joon-m1-2026-01-03` - Previous machine

Each branch contains optimizations specific to that machine's setup.

## Security Notes

- ✅ No private SSH keys included
- ✅ No API tokens or credentials
- ✅ No sensitive authentication data
- ⚠️ Review `.gitconfig` before committing (email addresses)

## Resources

- [Starship Documentation](https://starship.rs/)
- [fzf Usage](https://github.com/junegunn/fzf)
- [zoxide Guide](https://github.com/ajeetdsouza/zoxide)
- [Modern Unix Tools](https://github.com/ibraheemdev/modern-unix)

---

**Note**: This is a canonical reference collection. No automated symlink installer provided - manually copy files or create your own setup script based on your needs.
