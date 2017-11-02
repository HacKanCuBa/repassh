#!/bin/bash

# RePassh: repassh.bash
# Client script to easily connect to the RePassh server

# Remote GPG socket
GPG_SOCK_REMOTE="/run/user/1000/gnupg/S.gpg-agent.extra"

# Local GPG socket (leave empty to be filled automatically)
GPG_SOCK_LOCAL="$(gpgconf --list-dir agent-socket)"
GPG_SOCK_LOCAL="${GPG_SOCK_LOCAL:-/run/user/$UID/gnupg/S.gpg-agent}"

# Remote user name
LOGIN_NAME="passh"

REMOTE_HOST="$1"
shift
ARGS=( $@ )

if [[ -z "$REMOTE_HOST" ]]; then
	echo "Error: remote host not set!"
	exit 1
fi

if [[ -z "$GPG_SOCK_LOCAL" ]]; then
	GPG_SOCK_LOCAL="$(gpgconf --list-dir agent-socket)"
	GPG_SOCK_LOCAL="${GPG_SOCK_LOCAL:-/run/user/$UID/gnupg/S.gpg-agent}"
fi

# shellcheck disable=SC2029
ssh -qt \
	-l "$LOGIN_NAME" \
	-R "${GPG_SOCK_LOCAL}:${GPG_SOCK_REMOTE}" \
	"$REMOTE_HOST" \
	"${ARGS[*]}"
