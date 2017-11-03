#!/bin/bash

# RePassh: repassh.bash
# Client script to easily connect to the RePassh server

# Usage:
# repassh server-addr[:port] [command]
#
# Alternatively, set socket paths as:
# REPASSH_GPG_SOCK_LOCAL="/local/gnupg/path/file.socket" REPASSH_GPG_SOCK_REMOTE="/remote/gnupg/path/file.socket" repassh server-addr[:port] [command]
# or, export the variable prior calling repassh.
#
# Also, set remote username as:
# REPASSH_REMOTE_USERNAME="app" repassh server-addr[:port] [command]
# or, export the variable prior calling repassh.
#
# Finally, set the passh/pass binary as:
# REPASSH_PASSHBIN="pass" repassh server-addr[:port] [command]
# or, export the variable prior calling repassh.
#
###

declare -r VERSION="0.3"

show_help() {
	cat <<-_EOF
	RePassh v${VERSION}
	by HacKan (https://hackan.net) under GNU GPL v3.0+

	Usage:
	    repassh server-addr[:port] [command]

	    Arguments:
	        server-addr			Address of remote server (IP or URL).
	    Optional arguments:
	        port				Port number, defaults to 22.
	        command				A passh or pass command.

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

case "$REMOTE_HOST" in
	*:*)
		SERVER_ADDR="${REMOTE_HOST%%:*}"
		SERVER_PORT="${REMOTE_HOST#*:}"
		;;

	*)
		SERVER_ADDR="$REMOTE_HOST"
		SERVER_PORT="22"
		;;
esac



# Binary to use: passh or pass
PASSHBIN="${REPASSH_PASSHBIN:-passh}"
# Remote user name
LOGIN_NAME="${REPASSH_REMOTE_USERNAME:-passh}"

if [[ -n "$REPASSH_GPG_SOCK_REMOTE" ]]; then
	GPG_SOCK_REMOTE="$REPASSH_GPG_SOCK_REMOTE"
else
	GPG_SOCK_REMOTE="$(ssh -o ConnectTimeout=1 -l "$LOGIN_NAME" -p "$SERVER_PORT" "$SERVER_ADDR" gpgconf --list-dir agent-extra-socket)"
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
	-l "$LOGIN_NAME" \
	-R "${GPG_SOCK_LOCAL}:${GPG_SOCK_REMOTE}" \
	-p "$SERVER_PORT" \
	"$SERVER_ADDR" \
	"$PASSHBIN" \
	"${ARGS[*]}"
