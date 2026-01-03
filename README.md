# My Dotfiles

Canonical collection of configuration files and settings harvested from my macOS setup.

## Structure

```
mydotfiles/
├── Brewfile              # Homebrew packages (formulae & casks)
├── shell/                # Shell configuration
│   ├── .zshrc
│   ├── .bashrc
│   ├── .bash_profile
│   └── .aliases
├── git/                  # Git configuration
│   └── .gitconfig
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

## Contents

### Homebrew (Brewfile)
Complete list of installed packages via Homebrew. Restore with:
```bash
brew bundle install
```

### Shell Configuration
- **zsh**: Primary shell configuration
- **bash**: Fallback bash settings
- **aliases**: Custom command aliases

### Git
Global git configuration including user info, aliases, and preferences.

### SSH
SSH client configuration (Host entries, connection settings).
**Note**: Does not include private keys or sensitive credentials.

### Claude
Claude Code CLI settings and personal instructions (CLAUDE.md).

### Cursor & VSCode
Editor configuration files and lists of installed extensions.

## Usage

This is a reference/canonical collection - no symlink installation required.
To use on a new machine, manually copy desired files or create your own install script.

## Security Notes

- No private SSH keys included
- No API tokens or credentials
- No sensitive authentication data
- Review files before pushing to public repos
