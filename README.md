# dntw - [D]edicated [N]eovim per [T]mux [W]indow 🤯

<p align="center">
  <img width="600" alt="dntw demo" src="https://raw.githubusercontent.com/joshdick/dntw/master/demo/demo.svg?sanitize=true">
</p>

## What

`dntw` is a small shell script that allows you to have a **d**edicated **N**eovim instance per **t**mux **w**indow. It accomplishes this by acting as simple wrapper around the excellent tool [neovim-remote](https://github.com/mhinz/neovim-remote).

Once Neovim is running inside a `dntw`-enabled `tmux` session, the first instance of Neovim that is running in a given `tmux` window will become the dedicated Neovim instance for that window. Subsequent invocations of Neovim from other panes in the same window will reuse the dedicated instance.

## Why

Any time I used `tmux` and Neovim together for software development, new panes I created in `tmux` inevitably became filled with redundant instances of Neovim.

I made `dntw` with the hope that it would automatically save me from myself.

## How

### Install

If you're comfortable in Neovim/`tmux`/editing your shell configuration, `dntw` is for you!

Here's how to install it:

1. `tmux` and `nvim` are required for `dntw` to work. If you're not already using them, `dntw` may not be for you.

2. Install [neovim-remote](https://github.com/mhinz/neovim-remote), which is required for `dntw` to work.

    ```shell
    pip3 install neovim-remote
    ```

    If you have issues with this step, refer to [neovim-remote's installation documentation](https://github.com/mhinz/neovim-remote/blob/master/INSTALLATION.md) for assistance.

3. Clone the `dntw` git repository somewhere.

    ```shell
    $ git clone git://github.com/joshdick/dntw.git ~/.dntw
    ```

4. Add the following line somewhere in your shell configuration (`.zshrc`/`.bashrc`/etc) to source `dntw.sh`, adjusting the path accordingly for whatever you chose in the previous step.

    ```shell
    . ~/.dntw/dntw.sh
    ```

    This configuration adds the `dntw` and `dntw_edit` functions to your shell.

5. Create a function in your shell configuration that you will use to invoke `dntw_edit` as if it were Neovim.

    If you want to name the function `nvim`, or instruct `dntw` to use a specific `nvim` binary, you can set the environment variable `$DNTW_NVIM_CMD` to the location of your `nvim` binary.

    Here's an example:

    ```shell
    # If you need to bypass this function and run the real `nvim`
    # for some reason, just run `command nvim` instead.
    function nvim () {
      if [[ "$TERM_PROGRAM" == "vscode" ]]; then
        # If we typed "nvim" while inside the integrated Visual Studio Code terminal,
        # open the file in Code instead.
        code "$@"
      else
        # Invoke `dntw_edit` with an explicit `$DNTW_NVIM_CMD` since this function's
        # name conflicts with the real `nvim`.
        DNTW_NVIM_CMD=/usr/local/bin/nvim dntw_edit "$@"
      fi
    }

    # These convenience aliases simply invoke the function above.
    alias vi='nvim'
    alias vim='nvim'
    ```

6. Re-source your shell configuriation/restart your shell, or open a new shell. You're now ready to use `dntw`.

### Use

Start a new `dntw`-enabled `tmux` session by running `dntw`.

Once `tmux` is running, start Neovim inside `tmux` by invoking the function you added during [install](#install).

Neovim will behave as described in the [what](#what) section.

That's it!

## FAQ

Click on a question to see the answer.

<details>
<summary>Does this work with standard Vim?</summary>
<br />

Nope. `dntw` requires [neovim-remote](https://github.com/mhinz/neovim-remote), which itself only works with Neovim.

Although `neovim-remote` emulates standard Vim's `--servername` feature in Neovim, the standard Vim feature has a [bunch of caveats](https://vim.fandom.com/wiki/Enable_servername_capability_in_vim/xterm) including a [dependency on X11, even for CLI Vim](https://vi.stackexchange.com/a/5479).

I made `dntw` for my own use, and because I don't personally plan to use Vim this way, I have no plans to add support for standard Vim.

That said, pull requests are welcome.
</details>

<details>
<summary>Does this work on Windows?</summary>
<br />

Nope. I tried it in [Ubuntu on Windows](https://www.microsoft.com/en-us/p/ubuntu/9nblggh4msv6) but `neovim-remote` is currently not compatible with it.
</details>

<details>
<summary>Why do I see an error that starts with 'dntw error: "neovim-remote" is required, but does not appear to be installed.'?</summary>
<br />

This error happens when `neovim-remote` is either not installed or is installed incorrectly.

Bugs filed against `dntw` that mention this error are very likely to be closed, since the issue is likely with your environment and not with `dntw`.

Refer to [neovim-remote's installation documentation](https://github.com/mhinz/neovim-remote/blob/master/INSTALLATION.md) for assistance.
</details>

## License

MIT.

## Miscellany

The demo recording was created with [asciinema](https://asciinema.org/) and [svg-term-cli](https://github.com/marionebl/svg-term-cli).
