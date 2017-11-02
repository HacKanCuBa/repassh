# RePassh

This project is about using [passh](https://passh.hackan.net/) or [pass](https://www.passwordstore.org/), both unix password managers, in a remote server so you can access it from everywhere, plus work in teams.

It uses standar tools, nothing fancy: just ssh+gpg. There's no http(s) front-end nor anything like that. As a matter of fact, please **DO NOT LINK PASS/PASSH TO THE WEB!!** It has infinite command injection vulns and those are irreparable, because it was made to be run in the local terminal. So that's what this is doing: executing it in the terminal through ssh.

## Requirements

* OpenSSH Server v6.7+ (remotely)
* GnuPG v2.1.1+ (locally and remotely)
* Pass or Passh, any version (remotely)

## How does it work

Here you have a [client script](repassh.bash), that executes all of the ssh commands and it's very easy to understand, based on [GnuPG agent forwarding](https://wiki.gnupg.org/AgentForwarding), and some server-side configs. You will need to be root in a remote server to apply all of the necessary settings.

So, the basic workflow is: execute a `passh` command remotely through ssh, and use the local gpg agent forwarded to the remote server, so that decryption/signing operations can take place.

## Deploy and setup

This guide is oriented for users with some experience installing Linux distros and working remotely with ssh. If you have no idea about this, please ask for help in you local LUG or surf the web!.

I used *Debian 9 netinstall* as the base system, but you can use any distro of your preference since all of them have gpg and ssh. Just make sure to check the versions required.

### Setup remote server

Run as *root*:

1. Install openssh-server, gpg (it comes by default), dirmngr (to get keys from keyservers) and pass or [passh](https://passh.hackan.net/): `apt install openssh-server gpg dirmngr pass`.
2. Create an unprivileged user for the app, named *passh*: `useradd -s /bin/bash -m passh`.
3. Edit ssh daemon settings (`/etc/ssh/sshd_config`):

 * Set `StreamLocalBindUnlink yes`.
 * Conveniently restrict the application user, particularly set `ForceCommand /usr/bin/ssh2passh.bash`.\*
 * Change any other ssh setting you consider necessary, like disabling password login (heavily recommended).

It should look something like:

```
PasswordAuthentication no

StreamLocalBindUnlink yes

Match User passh
    # Jailing takes some time...
    #ChrootDirectory /home/passh
    ForceCommand /usr/local/bin/ssh2passh.bash
    X11Forwarding no
    PermitTTY yes
    PermitUserRC no
    AllowAgentForwarding no
    AllowTcpForwarding no
    PermitTunnel no
```

\*: *Note that this is not a big security setting: simply calling ssh and writing a second command after a semicolon (`;`), executes this second command no matter what: `ssh remote-server echo hello; pwd` will print the path to the current directory.*

4. Reload ssh daemon: `systemctl reload ssh`.
5. Copy the script [ssh2passh.bash](ssh2passh.bash) to `/usr/local/bin/ssh2passh.bash`.
6. Edit `/usr/local/bin/ssh2passh.bash` accordingly to set the correct binary (passh or pass).
7. Login as passh user: `su passh`.

Run as *passh*:

1. Import or download the gpg public keys of the users (or just yours): `gpg --recv-keys gpg-id1 ... gpg-idN`.
2. Edit (or create) `~/.gnupg/gpg.conf` with the following content: `trust-model always`. This is due to the public keys not being signed in the server. Optionally, you can create a key pair and use it to locally sign the public keys, it would be a more secure approach.
3. Find the path for the gpg agent extra socket, run: `gpgconf --list-dir agent-extra-socket`. It should be similar to `/run/user/1000/gnupg/S.gpg-agent.extra` (where `1000` is the user id, run `id` or `echo $UID`).
4. Edit (or create) `~/.gnupg/gpg-agent.conf` with the following content: `extra-socket <path of gpg agent extra socket>`. It should end up similar to `extra-socket /run/user/1000/gnupg/S.gpg-agent.extra`.
5. Edit `repassh.bash` script with the correct gpg agent extra socket path.
6. Copy the ssh key public key of every application user into `~/.ssh/authorized_keys`.
7. Set any relevant pass/passh environment variable, if any.
8. Initialize pass/passh with the gpg keys id of the users (or just yours): `passh init gpg-id1 ... gpg-idN`.

That's it! It seems long, but it took me about 15' to do it... And like several hours to write all of this!.

## Usage

With the server up and online, use the [repassh](repassh.bash) script to issue passh commands. Install it in `/usr/local/bin` or `~/.local/bin`, conveniently as simply `repassh`.

**Show version**:

```bash
:~$ repassh 192.168.1.250 version
============================================
=                  passh                   =
=    the standard unix password manager    =
=                                          =
=       by HacKan under GNU GPL v3.0+      =
=                  v1.7.2                  =
=                                          =
=  a fork from pass by Jason A. Donenfeld  =
============================================
```

**List store**:

```bash
:~$ repassh 192.168.1.250
Password Store
├── asd
├── blah
└── test
```

**Add a new entry to the store**:

```bash
:~$ repassh 192.168.1.250 insert new-entry
Enter password for new-entry: 
Retype password for new-entry: 
```

And so on and so fort, every command you give to `repassh` is passed directly to passh. Check the [passh manpage](https://passh.hackan.net/man.html) or [pass manpage](https://git.zx2c4.com/password-store/about) for more information.


## License

**RePassh** is made by [HacKan](https://hackan.net) under GNU GPL v3.0+. You are free to use, share, modify and share modifications under the terms of that [license](LICENSE).

    Copyright (C) 2017 HacKan (https://hackan.net)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
