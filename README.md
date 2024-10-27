# setenv

Export environment variables from file.

## Description

Utility shell script for loading environment variables defined in `.env` files, with support for automatic expansion of relative paths into absolute paths.

## Dependencies

Currently the script is only available for UNIX-like operating systems with a command line interpreter compatible with [`bash`](https://www.gnu.org/software/bash/) syntax.

Tested on Arch Linux with `bash`, but should work out of the box on BSD and MacOS on a variety of shells

## Usage

This script was **not** designed to be invoked directly, instead use the [`source`](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-source) builtin command to ensure the variables are [`export`](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-export)ed into the current shell session instead of just the script's subshell.
Because of this design, the script doesn't need execute permissions and uses `return` statements instead of `exit` for implementing control flow.

To load the variables, simply invoke the script through the `source` command in the same directory the `.env` file is located.

```sh
# Load variables from `dev.env`
source setenv.sh [options]

# Load variables from <filename>
source setenv.sh [options] <filename>
```

For the full documentation, see the script source file.
