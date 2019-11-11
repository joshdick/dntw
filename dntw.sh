#!/bin/sh

# Starts a new dntw session.
function dntw () {
  for requirement in tmux nvim; do
    if ! type "$requirement" >/dev/null 2>&1; then
      >&2 echo "dntw error: \"$requirement\" is required, but does not appear to be installed."
      return 1
    fi
  done
  if ! type nvr >/dev/null 2>&1; then
    >&2 echo "dntw error: \"neovim-remote\" is required, but does not appear to be installed.
Try running \`pip3 install neovim-remote\`, or see https://github.com/mhinz/neovim-remote#installation
for more detailed instructions."
    return 1
  fi
  local DNTW_ID=$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 | head -c16)
  local TMUX_SESSION_ID="dntw_$DNTW_ID"
  tmux set-environment -g DNTW_ID "$DNTW_ID" \; new-session -s "$TMUX_SESSION_ID"
}

# Invokes Neovim inside a running dntw session with the following behavior:
#   * Starts a new Neovim process if one is not already running in the active tmux window
#   * Resuses an existing Neovim process if one is already running in the active tmux window
# Starts Neovim normally if not inside a running dntw session.
# If you wish to use a custom Neovim binary (defualt: `nvim`), set $DNTW_NVIM_CMD in your environment.
function dntw_edit () {
  local DNTW_NVIM_CMD="${DNTW_NVIM_CMD:-nvim}"
  # Ensure that we're running inside a dntw session
  if [[ ! -z "$TMUX" ]] && [[ ! -z "$DNTW_ID" ]]; then
    # This window ID is unique across all tmux sessions and won't change if windows are rearranged
    local TMUX_WINDOW_ID=$(tmux display-message -p '#{window_id}')
    if [[ -z "$TMUX_WINDOW_ID" ]]; then
      >&2 echo "dntw error: Could not determine tmux window ID!"
      return 1
    fi
    local NVIM_TMUX_PANE_ID_KEY="dntw_${DNTW_ID}_${TMUX_WINDOW_ID}"
    local NVIM_LISTEN_ADDRESS="/${TMPDIR-/tmp/}dntw_${DNTW_ID}_${TMUX_WINDOW_ID}"
    if [ $(nvr --serverlist | grep -ic "$NVIM_LISTEN_ADDRESS") -eq 1 ]; then
      # A dedicated nvim is already running for this tmux window; reuse it
      NVR_CMD="$DNTW_NVIM_CMD" nvr --nostart --servername "$NVIM_LISTEN_ADDRESS" "$@"
      # Attempt to automatically focus nvim by selecting its pane
      # `tmux showenv` output format is `key=value`; `key=` needs to be stripped out
      local NVIM_TMUX_PANE_ID="${$(tmux showenv "${NVIM_TMUX_PANE_ID_KEY}" 2> /dev/null)##${NVIM_TMUX_PANE_ID_KEY}=}"
      if [[ ! -z "$NVIM_TMUX_PANE_ID" ]]; then
        tmux select-pane -t "${NVIM_TMUX_PANE_ID}"
      fi
    else
      # A dedicated nvim is not yet running for this tmux window;
      # start one and remember which pane it's running in
      local NVIM_TMUX_PANE_ID=$(tmux display-message -p '#{pane_id}')
      if [[ -z "$NVIM_TMUX_PANE_ID" ]]; then
        >&2 echo "dntw error: Could not determine tmux pane ID!"
        return 1
      fi
      tmux setenv "${NVIM_TMUX_PANE_ID_KEY}" "${NVIM_TMUX_PANE_ID}"
      NVIM_LISTEN_ADDRESS="$NVIM_LISTEN_ADDRESS" "$DNTW_NVIM_CMD" "$@"
    fi
  else
    "$DNTW_NVIM_CMD" "$@"
  fi
}

# Exactly like `dntw_edit` above, but works outside dntw sessions/inside an existing tmux session,
# and can thus be used without running `dntw` first.
# Useful when you only want a dedicated nvim in specifc tmux windows.
# Can be aliased independently from `dntw_edit` above.
#
# Advanced usage:
# This even works inside an existing dntw session, which makes it possible to have two nvim instances
# per window where one is controlled by `dntw_edit` and the other is controlled by `dntw_edit_unmanaged`,
# but this gets confusing quickly.
function dntw_edit_unmanaged () {
  local DNTW_ID=""
  if [[ ! -z "$TMUX" ]]; then
    local TMUX_SESSION_ID=$(tmux display-message -p '#{session_id}')
    if [[ -z "$TMUX_SESSION_ID" ]]; then
      >&2 echo "dntw error: Could not determine tmux session ID!"
      return 1
    fi
    DNTW_ID="dntw_${TMUX_SESSION_ID}"
  fi
  # Uses generated $DNTW_ID that corresponds to the existing tmux session (if any)
  dntw_edit "$@"
}
