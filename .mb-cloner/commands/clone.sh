# mb clone <folder>: clones the repo into <folder>, on a branch named <folder>, then starts the agent.
cmd_clone() {
  if [ $# -ne 1 ]; then
    echo "Usage: mb clone <folder>" >&2
    return 1
  fi

  local target="$1" default_branch

  if [ -e "$target" ]; then
    echo "Error: '$target' already exists" >&2
    return 1
  fi

  set_tab "$target"

  git clone "$repo_url" "$target"
  cd "$target"
  git config user.name "$git_name"
  git config user.email "$git_email"
  # Continues the branch if it was pushed from another machine, else starts it from the remote default branch
  if git ls-remote --exit-code --heads origin "$target" >/dev/null; then
    git checkout "$target"
  else
    # origin/HEAD is set by clone; fall back to asking the remote
    default_branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null \
      || git ls-remote --symref origin HEAD | awk '/^ref:/ {sub("refs/heads/", "", $2); print "origin/" $2}')
    git checkout -b "$target" "$default_branch"
  fi

  # Repo-specific setup; defined in env.local.sh (see env.example.sh)
  if declare -F post_clone_setup >/dev/null; then post_clone_setup; fi

  exec "$agent_invoke_name"
}
