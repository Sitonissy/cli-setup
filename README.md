# 💻 Sitonissy CLI Setup (Dotfiles)

> A smart repository for automatically configuring a minimalistic and fast terminal environment. 
> Tested and optimized for macOS (MacBook) and Linux (Ubuntu).

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Zsh](https://img.shields.io/badge/Zsh-111111?style=for-the-badge&logo=terminal&logoColor=white)

---

## 🚀 Features (Modern Unix Stack)

* **Config Management:** [GNU Stow](https://www.gnu.org/software/stow/)
* **Terminal Theme:** Dracula PRO Van Helsing *(protected by an encrypted archive)*
* **Prompt:** Powerlevel10k
* **Utilities:**
  * `zoxide` — smart replacement for standard `cd`
  * `eza` — modern replacement for `ls` with icons and Git status
  * `bat` / `batcat` — replacement for `cat` with beautiful syntax highlighting
  * `ripgrep` (`rg`) — blazingly fast search through file contents
  * `fzf` — interactive fuzzy finder (command history, paths)
  * `lazygit` — convenient TUI for working with Git
  * `zellij` — modern terminal multiplexer

## 🛠 Installation

1. Clone the repository to your home directory:
   ```bash
   # Clone the repository to the home directory
   git clone [https://github.com/Sitonissy/cli-setup.git](https://github.com/Sitonissy/cli-setup.git) ~/_git/cli-setup
   cd ~/_git/cli-setup
