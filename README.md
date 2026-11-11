# multibranch-cloner (`mb`)

One **full clone per branch/task**, each opened with its own AI coding agent session.
Every clone is isolated (its own `.git`), so tools that dislike git worktrees (Flutter/melos, hooks, ...) behave normally.

`mb clone my-task` clones your repo into `my-task/`, checks out a branch named `my-task` (continuing it if it already exists on the remote, otherwise starting from the remote's default branch), runs your repo-specific setup, and starts your agent. In Konsole, the tab gets a title and color.

## Install

Run this in the folder where your clones should live (they are created next to `mb`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lucas-zimerman/multibranch-cloner/main/.mb-cloner/install.sh)
```

It downloads the scripts, then asks for:

- the repo (`username/reponame`)
- the tab title and tab color
- your git name and email
- the agent name and the command that starts it (e.g. `Claude` / `claude`)

and writes your answers to `.mb-cloner/data.sh`. When it finishes it prints a prompt: give it to your agent so it analyses the repo and fills in `post_clone_setup()` (toolchain, dependencies, bootstrap, ...) in `.mb-cloner/env.local.sh`.

## Usage

```bash
./mb clone <folder>   # clone into <folder> on a branch named <folder>, then start the agent
./mb open <folder>    # start the agent inside an existing clone
./mb list             # clones with last access, branch and PR
./mb clear [-y]       # remove clones whose PR was merged
./mb update [-y]      # download the latest scripts (shows a diff first)
```

Requires `git`, `gh` (for `list` and `clear`) and `curl`. Tested on Linux/KDE; written to be portable to macOS.

## Windows (PowerShell)

The Linux/macOS bash scripts are kept as they are; Windows has a parallel set of `.ps1` files that live in the same folder. Works with Windows PowerShell 5.1 or PowerShell 7+.

Install (run it in the folder where your clones should live):

```powershell
irm https://raw.githubusercontent.com/lucas-zimerman/multibranch-cloner/main/.mb-cloner/install.ps1 | iex
```

This writes `.mb-cloner\data.ps1` and `.mb-cloner\env.local.ps1` (git-ignored). Put your repo setup in `post_clone_setup` (a PowerShell function) in `env.local.ps1`.

Usage is the same as on Linux/macOS, e.g. `./mb clone <folder>` (see [Usage](#usage)). In PowerShell `./mb` runs `mb.ps1`; in Git Bash it runs the bash script. `mb update` on Windows updates the files listed in `.mb-cloner\manifest.windows`.

- **cmd:** use `mb` or `.\mb` (cmd doesn't accept `./`); this runs `mb.cmd`.
- **"running scripts is disabled":** Windows PowerShell 5.1 blocks scripts by default. Either allow local scripts once with `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`, or use `.\mb.cmd`, which starts PowerShell with `-ExecutionPolicy Bypass`.

Requires `git` and `gh` (for `list` and `clear`). The tab title is set via the window title (Windows Terminal, conhost, VS Code); the tab color can't be set from a script on Windows, so `tab_color` is stored but unused there. Setting the title also sets `CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1` so Claude Code keeps the title instead of replacing it.

## Layout

```
mb                       the command
.mb-cloner/
  shared.sh              helpers shared by all commands
  commands/              one file per subcommand
  kde/konsole.sh         Konsole tab title and color
  data.example.sh        template for data.sh
  env.example.sh         template for env.local.sh
  install.sh             interactive setup
  manifest               list of files `mb update` and the installer download
  data.sh                generated: your answers (git-ignored)
  env.local.sh           generated: machine setup + post_clone_setup() (git-ignored)
```

Windows counterparts (same folder):

```
mb.cmd, mb.ps1           the command (cmd launcher / PowerShell entry point)
.mb-cloner/
  shared.ps1             helpers shared by all commands
  commands/*.ps1         one file per subcommand
  windows/terminal.ps1   tab title
  data.example.ps1       template for data.ps1
  env.example.ps1        template for env.local.ps1
  install.ps1            interactive setup
  manifest.windows       list of files `mb update` and the installer download
  data.ps1               generated: your answers (git-ignored)
  env.local.ps1          generated: machine setup + post_clone_setup (git-ignored)
```

`data.sh` and `env.local.sh` are never overwritten by `mb update`. If a new version adds a variable to `data.example.sh`, `mb update` warns that your `data.sh` is missing it.

## Customizing

- **Post-clone steps:** edit `post_clone_setup()` in `.mb-cloner/env.local.sh`. It runs inside the new clone right before the agent starts.
- **Other terminals:** `set_terminal_tab_header` lives in `.mb-cloner/kde/konsole.sh`; `install.sh` only loads it inside Konsole.
- **Different download source for `update`/install:** set `MB_CLONER_URL` to a raw base URL.
