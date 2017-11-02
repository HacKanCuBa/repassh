#!/bin/bash

# RePassh: ssh2passh.bash
# Wraps pass/h so it's forced by sshd.

# Set the path to the pass or passh binary
#PASSHBIN="/usr/bin/pass"
PASSHBIN="/usr/bin/passh"

## For some reason, I can't seem to make that regex work, so screw it.

# Set to false to skip command check
#declare -r CHECK=true

#if "$CHECK" && [[ -n "$SSH_ORIGINAL_COMMAND" ]]; then
        ### Feel free to remove this entire check.
        # Simple check, THIS IS INSECURE! It can be bypassed, but that's not
        # the point of this project. It's merely to prevent unwanted mistakes.
#       pattern="^[a-zA-Z0-9 \-\_\.\,\@\=]*$"
#       if ! [[ "$SSH_ORIGINAL_COMMAND" =~ $pattern ]]; then
#               echo "Invalid arguments!"
#               exit 1
#       fi
        ###
#fi
##

IFS=' ' read -ra ARGS <<<"$SSH_ORIGINAL_COMMAND"

"$PASSHBIN" "${ARGS[@]}"
