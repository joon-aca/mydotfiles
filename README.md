# My Dotfiles

A cross-platform (macOS + Ubuntu/Debian) developer workstation setup. A work in progress and mostly for my benefit...

---

## ✨ Overview

This dotfiles repo configures a developer workstation optimized for:

* ⚡ **Performance** — fast shell startup, modern replacements for slow legacy tools
* 🧭 **Productivity** — smart navigation, helpful CLI enhancements, fewer keystrokes
* 🧑‍💻 **Developer ergonomics** — readable output, consistent workflows across projects
* 🍎 **Apple Silicon** — ARM-native tools on macOS
* 🐧 **Linux** — Ubuntu/Debian support via apt + targeted installs
* 🔁 **Portability** — easy setup across machines

> Think of this as a thoughtful refresh of classic Unix tooling — familiar workflows, but faster and friendlier.

---

## 🧰 Toolset (at a Glance)

| Area                    | Tools                                                       |
| ----------------------- | ----------------------------------------------------------- |
| Shell & Navigation      | Starship, fzf, zoxide, autosuggestions, syntax highlighting |
| Modern CLI Replacements | bat, eza, ripgrep, fd, dust, procs, git-delta               |
| Monitoring              | btop, htop, asitop (macOS only)                             |
| Dev & Editing           | git, gh, tmux, neovim, emacs, jq, yq                        |
| Networking              | httpie, wget, nmap                                          |
| Runtimes                | fnm, pipx, watchman                                         |
| AI / Productivity       | claude-code, codex, gemini-cli, mlx-lm (macOS)              |
| Utilities               | pv, watch, stress-ng                                        |
| Fonts                   | JetBrains Mono Nerd Font                                    |

---

## 🖥 Shell & Prompt

### **Starship** — Fast, Minimal, Cross-Shell Prompt

[https://starship.rs/](https://starship.rs/)

![Starship Prompt](https://starship.rs/img/demo.gif)

Features:

* instant rendering (even in large repos)
* git status, language versions, command timers
* consistent across machines

Other shell enhancements:

* `zsh-autosuggestions` — history-based inline suggestions
* `zsh-syntax-highlighting` — catch typos before you run them
* `fzf` — fuzzy finder for files, history, directories
* `zoxide` — smarter `cd` with learning behavior

---

## 🧾 Modern CLI Replacements

Classic Unix tools still work — but these are **faster, clearer, and easier to read**.

* **bat** → `cat`, but with syntax highlighting and git indicators
  [https://github.com/sharkdp/bat](https://github.com/sharkdp/bat)

* **eza** → modern `ls` with icons & git info
  [https://github.com/eza-community/eza](https://github.com/eza-community/eza)

* **ripgrep** → grep that searches entire repos in milliseconds
  [https://github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)

* **fd** → intuitive, fast `find`
  [https://github.com/sharkdp/fd](https://github.com/sharkdp/fd)

* **dust** → readable disk usage tree

* **procs** → improved `ps`

* **git-delta** → readable diffs for Git

These tools prioritize **speed, sensible defaults, and readable output**.

---

## 🧩 Developer Workflow Tools

* **tmux** — persistent sessions & panes (ideal for SSH and servers)
* **gh** — GitHub CLI (PRs, issues, repos from terminal)
* **neovim / emacs** — modern editors with extensibility options
* **jq / yq** — JSON / YAML processing
* **tree** — directory visualization
* **watch / pv** — repeating commands & pipe progress

---

## 📊 System Monitoring

* **btop** — rich graphical system dashboard
* **htop** — powerful interactive process viewer
* **asitop** — Apple Silicon CPU / GPU / Neural Engine metrics
  [https://github.com/tlkh/asitop](https://github.com/tlkh/asitop)

Great for debugging load, heat, and performance behavior.

---

## 🤖 AI & Productivity

* **Claude Code** — primary AI coding assistant (install via npm)
  `npm install -g @anthropic-ai/claude-code`
  Your go-to for daily development, codebase understanding, refactoring

* **gemini-cli** — secondary AI for intractable problems
  Great for alternative approaches, math, and cross-checking solutions

* **MLX** — run local LLMs on Apple Silicon (install via pipx)
  `pipx install mlx-lm`
  [https://github.com/ml-explore/mlx-examples](https://github.com/ml-explore/mlx-examples)
  Complete privacy, works offline, Apple's native ML framework
  _Note: Replaces ollama due to header bug in macOS 26.2_

---

## 🧱 Installation

Works on **macOS** (Homebrew) and **Ubuntu/Debian** (apt + targeted installs).

```bash
git clone git@github.com:joon-aca/mydotfiles.git ~/mydotfiles
cd ~/mydotfiles
./bootstrap.sh
exec zsh
```

The bootstrap script handles everything: package installation, config symlinking, shell change, and AI CLI tools. See `bootstrap.sh` for details.

### Server setup (optional)

For servers that need Docker, Caddy, and Dockge:

```bash
./server-setup.sh
```

This installs Docker (official apt repo), Caddy (official apt repo), sets up `/opt/stacks` with setgid docker, and deploys Dockge to `/opt/dockge`.

---

## 🧭 Everyday Shortcuts

**Navigation**

* `z project` — jump anywhere you’ve visited
* `Ctrl+R` — fuzzy history search
* `Ctrl+T` — fuzzy file finder

**Modern command replacements**

* `ls` → eza
* `cat` → bat
* `grep` → ripgrep
* `find` → fd

**Git aliases (see `.gitconfig`)**

* `git s` — short status
* `git l` — graph log
* `git cm "msg"` — commit message shortcut

---

## 🎨 Customization

* `~/.config/starship.toml` — prompt config
* `~/.zsh/aliases.zsh` — personal aliases
* `.zshrc` — fzf behavior, preview pane, and styles

---

## 🔄 Maintenance

**macOS:**
```bash
brew update && brew upgrade
brew bundle dump --force
```

**Linux:**
```bash
sudo apt update && sudo apt upgrade -y
```

Configs are symlinked — edit in `~/mydotfiles`, changes apply immediately (restart shell or `reload`).

---

## 🛠 Troubleshooting

* Slow shell? `time zsh -i -c exit`
* fzf missing? Re-run installer
* starship missing? Check config + init block
* git-delta not applied? `git config --get core.pager`

---

## 📚 References

* Modern Unix Tools — [https://github.com/ibraheemdev/modern-unix](https://github.com/ibraheemdev/modern-unix)
* Starship Docs — [https://starship.rs/](https://starship.rs/)
* fzf Examples — [https://github.com/junegunn/fzf](https://github.com/junegunn/fzf)
* zoxide Guide — [https://github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)
* Homebrew Bundle — [https://github.com/Homebrew/homebrew-bundle](https://github.com/Homebrew/homebrew-bundle)

---

## License

MIT — use freely, customize as you like.

