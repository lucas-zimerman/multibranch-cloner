# multibranch-cloner (`mb`)

One **full clone per branch/task**, each opened with its own AI coding agent session.
Every clone is isolated (its own `.git`), so tools that dislike git worktrees (Flutter/melos, hooks, ...) behave normally.

`mb clone my-task` clones your repo into `my-task/`, checks out a branch named `my-task` (continuing it if it already exists on the remote, otherwise starting from the remote's default branch), runs your repo-specific setup, and starts your agent. In Konsole, the tab gets a title and color.

## Requirements

- git
- gh
- curl (Linux/MacOS)
- powershell (Windows)

## Install

Run the installer in the folder where your clones should live (they are created next to `mb`).

### Linux/macOS

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lucas-zimerman/multibranch-cloner/main/.mb-cloner/install.sh)
```

### Windows

```powershell
irm https://raw.githubusercontent.com/lucas-zimerman/multibranch-cloner/main/.mb-cloner/install.ps1 | iex
```

### What the installer asks

It downloads the scripts, then asks for:

- the repo (`username/reponame`)
- the tab title and tab color
- your git name and email
- the agent name and the command that starts it (e.g. `Claude` / `claude`)

and writes your answers to `.mb-cloner/data.sh` (Windows: `data.ps1`). When it finishes it prints a prompt: give it to your agent so it analyses the repo and fills in `post_clone_setup()` (toolchain, dependencies, bootstrap, ...) in `.mb-cloner/env.local.sh` (Windows: `env.local.ps1`). Both generated files are git-ignored.

## Usage

```bash
mb clone <folder>   # clone into <folder> on a branch named <folder>, then start the agent
mb open <folder>    # start the agent inside an existing clone
mb list             # clones with last access, branch and PR
mb clear [-y]       # remove clones whose PR was merged
mb update [-y]      # download the latest scripts (shows a diff first)
```

- **"running scripts is disabled":** Windows PowerShell 5.1 blocks scripts by default. Either allow local scripts once with `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`, or use `.\mb.cmd`, which starts PowerShell with `-ExecutionPolicy Bypass`.

## Customizing

- **Post-clone steps:** edit `post_clone_setup()` in `.mb-cloner/env.local.sh/ps1`. It runs inside the new clone right before the agent starts.
