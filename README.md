# setenv

Export environment variables from file.

## Description

Utility shell script for loading environment variables defined in `.env` files.

Currently only supports UNIX-like operating systems. Tested on Linux, but should work on BSD and MacOS as well.

## Dependencies

 - `bash`-compatible command line shell.

## Usage

To load the variables, simply invoke the script with the [`source`](https://man.archlinux.org/man/bash.1#source) builtin command in the same directory the `.env` file is located, or pass the `<filename>` argument.

Internally, the script will load the variables using the `export` builtin command, so unless the script is invoked with the `source` command, all variables will be exported in a subshell instead of the current session.
Because of this, execute (`x`) permission flag is not needed on the script file itself.

```sh
# Load variables from `dev.env`
source setenv.sh [options]

# Load variables from <filename>
source setenv.sh [options] <filename>
```

See the full documentation in the script source file.

