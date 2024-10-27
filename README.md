# setenv

Export environment variables from file.

## Description

Utility shell script for loading environment variables defined in `.env` files, with support for automatic expansion of relative paths into absolute paths.

## Dependencies

Currently the script is only available for command line interpreters compatible with [`bash`](https://www.gnu.org/software/bash/) syntax.

Tested with `bash` on Linux, but should work out of the box on any UNIX-like operating system on a variety of shells.

## Usage

This script was **not** designed to be invoked directly, instead use the [`source`](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-source) builtin command to ensure the variables are [exported](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-export) into the current shell session instead of just the script's subshell.
Because of this design, the script file doesn't need execute permissions, and uses `return` statements instead of `exit` for implementing control flow.

To load the variables, simply invoke the script through the `source` command in the same directory the `.env` file is located. If no `<filename>` is given, it defaults to a `dev.env` file located in the current directory. The file must exist.

```sh
# Load variables from `dev.env`
source setenv.sh [options]

# Load variables from <filename>
source setenv.sh [options] <filename>
```

For the full documentation, see the script source file.

## Installing

The recommended way to install the script is to clone the repo locally, copy the scrip to a separate directory, then create an [alias](https://www.gnu.org/software/bash/manual/html_node/Aliases.html) for the script with the `source` command already added.

```sh
# 1. Clone the repository
SETENV_REPO="./scripts/setenv"
git clone git@github.com:fabberr/setenv.git $SETENV_REPO

# 2. Install
SETENV_ROOT="./dev-tools"
mkdir -p $SETENV_ROOT && cd $SETENV_ROOT
cp "$SETENV_REPO/src/setenv.sh" .

# 3. Register alias
echo "alias 'setenv'='source $(realpath setenv.sh)'" >> ~/.bash_aliases
source ~/.bash_aliases
```

## Updating

To update the script, pull any changes from `origin/master` into your local repo and repeat only step 2 of the installation process.

```sh
# Pull changes from origin
git switch master
git pull origin master
```
