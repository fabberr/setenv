#!/usr/bin/env sh

##
## FILE: setenv.sh
##
##     Export environment variables from file.
##
## USAGE:
##
##     source setenv.sh [options]
##     source setenv.sh [options] <filename>
##
## DESCRIPTION:
##
##     Exports environment variables defined in <filename> to the current shell
##     session. If <filename> is not present a default `./dev.env` file is used.
## 
##     The variables in the file are expected to be defined in the following
##     format, one per line.
##
##         <key>=<value>
##
##     The key may only consist of uppercase alphanumeric characters or
##     underscores (`_`).
##
##     Values that start with either `.`, `..` or `~` are treated as relative
##     paths and are automatically expanded to their absolute paths using
##     REALPATH(1) before being exported.
##
##     Lines starting with a `#` are treated as comments and are igonred.
##     Empty lines are also ignored.
##
## ARGUMENTS:
##
##     <filename>
##         Path to a file containing the environment variables to export.
##         The file pointed by the path must exist and not be empty.
##
## OPTIONS:
##
##     --verbosity=<log-level>
##         Sets verbosity of the log messages to one of the following levels:
##
##         none         Disables all logging (default option).
##         info         Logs information messages.
##         warning      Logs information and warning messages.
##         error        Enables logging of all messages.
##
##         Note: warning and error messages are also logged to stderr.
##
##     --verbose, -v
##         Alias for `--verbosity=error` option.
##         Additionally, every exported variable will also be logged.
##
##         Note: Passing this option will overide any value set with a preceding
##         --verbosity option.
##
## VERSION: 1.0.4
##
## DEPENDENCIES:
##
##     GREP(1)      Pattern matching for parsing logic.
##     CUT(1)       Splitting key-value pairs read from the file.
##     REALPATH(1)  Expanding relative into absolute paths.
##
## AUTHORS:
##
##     Fabrício Milanez (https://github.com/fabberr)
##

################################################################################
############################### CONTROL VARIABLES ##############################
################################################################################

# Simulating boolean values
true=1
false=0

# Log Level enum
LOG_LEVEL_NONE=0    # Logging is disabled.
LOG_LEVEL_INFO=1    # Only information messages will be logged. 
LOG_LEVEL_WARNING=2 # Only information and warning messages will be logged.
LOG_LEVEL_ERROR=3   # All messages will be logged.

# Initialize control variables with default values
ENV_FILE="./dev.env"            # Path to the file to load the variables from.
LOG_LEVEL="$LOG_LEVEL_NONE"     # Determines the log level.
LOG_EXPORTED_VARIABLES="$false" # Enables logging of exported variables.

################################################################################
################################## FUNCTIONS ###################################
################################################################################

# Summary:
#
#     Logs messages to standard output streams, depending on the current value
#     of $LOG_LEVEL.
#
#     If $LOG_LEVEL is set to LOG_LEVEL_NONE, the function is a no-op.
#
# Arguments:
#
#     $1: level - LOG_LEVEL_INFO | LOG_LEVEL_WARNING | LOG_LEVEL_ERROR
#         The level of the message.
#
#     $2: message - string
#         The message to be logged to stdout.
#         If `level` is set to LOG_LEVEL_WARNING or LOG_LEVEL_ERROR, the message
#         will also be logged to stderr.
log() {
    local level="$1"
    local message="$2"

    if [ "$level" -le "$LOG_LEVEL" ]; then
        case "$level" in
            "$LOG_LEVEL_INFO")
                printf "[setenv] [INFO] %s\n" "$message"
                ;;
            "$LOG_LEVEL_WARNING")
                printf "[setenv] [WARNING] %s\n" "$message" >&2
                ;;
            "$LOG_LEVEL_ERROR")
                printf "[setenv] [ERROR] %s\n" "$message" >&2
                ;;
        esac
    fi
}

# Summary:
#     Logs an information message to stdout.
#
# Arguments:
#     $1: message - string
#         The information message to be logged.
log_info() {
    log "$LOG_LEVEL_INFO" "$1"
}

# Summary:
#     Logs a warning message to stdout and stderr.
#
# Arguments:
#     $1: message - string
#         The warning message to be logged.
log_warning() {
    log "$LOG_LEVEL_WARNING" "$1"
}

# Summary:
#     Logs an error message to stdout and stderr.
#
# Arguments:
#     $1: message - string
#         The error message to be logged.
log_error() {
    log "$LOG_LEVEL_ERROR" "$1"
}

# Summary:
#     Checks if the specified command exists.
#
# Arguments:
#     $1: command_name - string
#         Name of the command to check availability.
#
# return status:
#     Success (0) when the command exists, failure (1) otherwise.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

################################################################################
############################### DEPENDENCY CHECK ###############################
################################################################################

required_commands=(
    "grep"
    "cut"
    "realpath"
)
missing_commands=()

for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
        missing_commands+=("$cmd")
    fi
done

if [ "${#missing_commands[@]}" -ne 0 ]; then
    printf "The following commands are required but were not found: %s\n" "${missing_commands[*]}" >&2
    return 1
fi

################################################################################
################### EXTRACT AND PARSE COMMAND LINE ARGUMENTS ###################
################################################################################

while [ $# -gt 0 ]; do
    case $1 in
        --verbosity=*)
            case "${1#*=}" in
                none)
                    LOG_LEVEL="$LOG_LEVEL_NONE"
                    ;;
                info)
                    LOG_LEVEL="$LOG_LEVEL_INFO"
                    ;;
                warning)
                    LOG_LEVEL="$LOG_LEVEL_WARNING"
                    ;;
                error)
                    LOG_LEVEL="$LOG_LEVEL_ERROR"
                    ;;
                *)
                    printf "Unknown log level provided for --verbosity option: %s.\n" "${1#*=}" >&2
                    return 1
            esac
            shift
            ;;
        -v|--verbose)
            LOG_LEVEL="$LOG_LEVEL_ERROR"
            LOG_EXPORTED_VARIABLES=1
            shift
            ;;
        *)
            # Parse <filename>
            ENV_FILE="$1"

            if [ ! -f "$ENV_FILE" ]; then
                printf "Invalid value for <filename> argument: file %s not found.\n" "$ENV_FILE" >&2
                return 1
            fi
            shift
            ;;
    esac
done

################################################################################
#################################### SCRIPT ####################################
################################################################################

# Ensure ENV_FILE is not empty
if [ ! -s "$ENV_FILE" ]; then
    printf "Invalid value for <filename> argument: file %s is empty.\n" "$ENV_FILE" >&2
    return 1
fi

log_info "Loading environment variables from $ENV_FILE"
if [ "$LOG_EXPORTED_VARIABLES" -eq $true ]; then
    log_info "Verbose mode is enabled, exported variables will be logged."
fi

EXPORTED_COUNT=0
while IFS= read -r line; do
    
    # Ignore commented out or empty lines
    if echo "$line" | grep -qE '^\s*#' || [ -z "$line" ]; then
        continue
    fi

    # Extract the key and value
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2-)

    # Ensure key is valid
    if ! echo "$key" | grep -qE '^[A-Z0-9_]+$'; then
        log_warning "Invalid key $key. Skipping."
        continue
    fi

    # Ensure the value is not empty
    if [ -z "$value" ]; then
        log_warning "Invalid value for $key: The value cannot be empty. Skipping."
        continue
    fi

    # Check if the value is a relative path and expand it
    if echo "$value" | grep -qE '^(~|\.\.?(/|$))'; then
        value=$(realpath "$value" 2>/dev/null)
    fi

    # All good, export the variable and log it if needed
    export "$key=$value"
    (( EXPORTED_COUNT++ ))

    if [ "$LOG_EXPORTED_VARIABLES" -eq $true ]; then
        log_info "Exported variable: $key=$value"
    fi
done < "$ENV_FILE" || {
    log_error "Failed to read $ENV_FILE."
    return 1
}

log_info "Done! Exported $EXPORTED_COUNT variable(s)."
