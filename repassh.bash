#!/bin/bash

# RePassh: repassh.bash
# Client script to easily connect to the RePassh server

# Usage:
# repassh server-addr [command]
#
# Alternatively, set socket paths as:
# REPASSH_GPG_SOCK_LOCAL="/local/gnupg/path/file.socket" REPASSH_GPG_SOCK_REMOTE="/remote/gnupg/path/file.socket" repassh server-addr [command]
# or, export the variable prior calling repassh.
#
# Also, set remote username as:
# REPASSH_REMOTE_USERNAME="app" repassh server-addr [command]
# or, export the variable prior calling repassh.
#
# Finally, set the passh/pass binary as:
# REPASSH_PASSHBIN="pass" repassh server-addr [command]
# or, export the variable prior calling repassh.
#
###

declare -r VERSION="0.2"

show_help() {
	cat <<-_EOF
	RePassh v${VERSION}
	by HacKan (https://hackan.net) under GNU GPL v3.0+

	Usage:
	    repassh server-addr [command]

	There are some settings to tune with environment variables:
	    REPASSH_GPG_SOCK_LOCAL		Set local gnupg agent socket path.
	    REPASSH_GPG_SOCK_REMOTE		Set remote gnupg agent socket path.
	    REPASSH_REMOTE_USERNAME		Set remote server username.
	    REPASSH_PASSHBIN			Set the binary path, or name, for passh or pass.
	Set them in the same line as the repassh execution, or export them prior it.
	Several, even all of them, can be set in the same line.

	GPG Agent sockets are set automatically, but if it fails or you want to set it
	manually, do as:
	    REPASSH_GPG_SOCK_LOCAL="/local/gpg.socket" repassh server-addr [command]
	    REPASSH_GPG_SOCK_REMOTE="/remote/gpg.socket" repassh server-addr [command]

	Username is 'passh' by default, change it as:
	    REPASSH_REMOTE_USERNAME="app" repassh server-addr [command]

	The passh binary is used by default, change it as:
	    REPASSH_PASSHBIN="pass" repassh server-addr [command]
	_EOF
}

# Main

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	show_help
	exit 0
fi

REMOTE_HOST="$1"
shift
ARGS=( $@ )

if [[ -z "$REMOTE_HOST" ]]; then
	echo "Error: remote host not set!"
	echo "Try: $0 --help"
	exit 1
fi

# Binary to use: passh or pass
PASSHBIN="${REPASSH_PASSHBIN:-passh}"
# Remote user name
LOGIN_NAME="${REPASSH_REMOTE_USERNAME:-passh}"

if [[ -n "$REPASSH_GPG_SOCK_REMOTE" ]]; then
	GPG_SOCK_REMOTE="$REPASSH_GPG_SOCK_REMOTE"
else
	GPG_SOCK_REMOTE="$(ssh -o ConnectTimeout=1 -q -l "$LOGIN_NAME" "$REMOTE_HOST" gpgconf --list-dir agent-extra-socket)"
	GPG_SOCK_REMOTE="${GPG_SOCK_REMOTE:-/run/user/1000/gnupg/S.gpg-agent.extra}"
fi

if [[ -n "$REPASSH_GPG_SOCK_LOCAL" ]]; then
	GPG_SOCK_LOCAL="$REPASSH_GPG_SOCK_LOCAL"
else
	GPG_SOCK_LOCAL="$(gpgconf --list-dir agent-socket)"
	GPG_SOCK_LOCAL="${GPG_SOCK_LOCAL:-/run/user/$UID/gnupg/S.gpg-agent}"
fi

# shellcheck disable=SC2029
ssh \
	-qt \
	-l "$LOGIN_NAME" \
	-R "${GPG_SOCK_LOCAL}:${GPG_SOCK_REMOTE}" \
	"$REMOTE_HOST" \
    "$PASSHBIN" \
	"${ARGS[*]}"
