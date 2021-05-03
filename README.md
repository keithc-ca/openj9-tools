Developing OpenJDK with OpenJ9
==============================

This repository includes a number of scripts that simplify command-line
interaction with the stacks of repositories required to develop and
build OpenJDK with OpenJ9.

The following shows how those scripts are put to use, starting with a
minimal Ubuntu 16.04 system. There are few differences between ppc64le,
s390x and x64 architectures: sample commands are for an x64 system.

Create a Regular User
=====================

It is recommended that you create an unprivileged user for normal
activity, using `sudo` only as necessary. Replace 'keithc' with a
user-id of your choice, and you'll probably want to use your full name
rather than mine.

```sh
# useradd -m -s /bin/bash -G sudo -c 'Keith W. Campbell' keithc
```

Set the password for your new account.

```sh
# passwd keithc
```

Now log into your new account to initialize and customize it.

```sh
# su -l keithc
```

Identify yourself for `git`:

```
$ cat > ~/.gitconfig
[user]
	email = keithc@ca.ibm.com
	name = Keith W. Campbell
[ctrl+D]
```

Install Your SSH Key
====================

Copy the private part of your SSH key to the clipboard and store it
securely on your new system.

```sh
$ umask 077
$ mkdir ~/.ssh
$ cat > ~/.ssh/id_rsa
[paste][ctrl+D]
```

Prepare the System
==================

What follows assumes you'll organize your work in a directory called
'space' within your home directory. You can put it wherever you want,
but if you put it elsewhere, remember to adjust the commands shown
accordingly.

```sh
$ mkdir -p ~/space
$ cd ~/space
```

You may not even have `git` installed on your system yet: that's OK,
simply copy [system-setup.sh](system-setup.sh) from this repository
to the clipboard and paste into a file.

```sh
$ cat > system-setup.sh
[paste][ctrl+D]
```

Now you're ready to prepare your system with most of the tools you'll need.

```sh
$ sudo bash system-setup.sh
```

The intent is that future versions of this script will be able to update
a system that was prepared using an older version and that repeated use
is safe.

Fetch Git Repositories
======================

Now that your system has git and your SSH key is installed, clone this
repository for local use.

```sh
$ git clone https://github.com/keithc-ca/openj9-tools.git tools
```

Create symbolic links to the scripts and the file containing the list
of active repositories.

```sh
$ ln -s tools/repos tools/*.sh .
```

Prepare your workspace by fetching freemarker.jar and boot JDKs.

```sh
$ bash work-setup.sh
```

Now clone the OpenJDK extension repositories (omit any you don't immediately need).

```sh
$ git clone https://github.com/ibmruntimes/openj9-openjdk-jdk8.git jdk08
$ git clone https://github.com/ibmruntimes/openj9-openjdk-jdk11.git jdk11
$ git clone https://github.com/ibmruntimes/openj9-openjdk-jdk16.git jdk16
$ git clone https://github.com/ibmruntimes/openj9-openjdk-jdk.git jdk17
```

You could follow the instructions included in the OpenJ9 repository to
use the `get_j9_source.sh` within each extension repository, but you
would end up with multiple copies of OMR and OpenJ9. I prefer to work
with a single copy of those repositories and the scripts here reflect
that choice: clone OMR and OpenJ9 and create symbolic links to satisfy
the extension repositories.

```sh
$ git clone https://github.com/eclipse-openj9/openj9-omr.git omr
$ git clone https://github.com/eclipse-openj9/openj9.git openj9
$ ln -s ../omr ../openj9 jdk08
$ ln -s ../omr ../openj9 jdk11
$ ln -s ../omr ../openj9 jdk16
$ ln -s ../omr ../openj9 jdk17
```

Ongoing Activity
================

Now you're ready to configure and build any of the extension repositories
you've cloned. Simply go the root working directory of an extension
repository and run `configure.sh` which will configure OpenJDK in
preparation for building.

```sh
$ cd ~/space/jdk11
$ ../configure.sh
```

Now you can build OpenJDK with OpenJ9:

```sh
$ make images
```

To update all the clones with commits from remote repositories use the
`fetch.sh` script. It expects the list of repositories (in `repos`) to
be in the same directory where it lives, which may not be your current
directory.

```sh
../fetch.sh
```

To see whether there are changes that you might want to include in your
clones, use `status.sh`:

```sh
$ ../status.sh
```

If you make changes to any of the three repositories that contributes
to a given version of OpenJDK, you may need to reconfigure. In version
9 and later, you can say:

```sh
$ make reconfigure
```

You can reconfigure all versions of OpenJDK with a single command
(including version 8):

```sh
$ ../reconfigure-all.sh
```

Note that, like `make reconfigure` this replays the most configure
arguments which might be different than the defaults applied by
`configure.sh`.

After reconfiguring, you're advised to `make clean`. If you're only
working with one OpenJDK version, you can do just that. If you have
several versions on the go, you can clean them all with:

```sh
$ ../clean-all.sh
```

With everything clean and ready for the next build, you can build all
versions with:

```sh
$ ../images-all.sh
```

By default, git uses heuristics to decide when a clone needs garbage
collection. You might not always like when git decides to do that because
it can take considerable time for the large repositories we're using. To
disable automatic garbage collection globally, use the following command:

```sh
$ git config --global gc.auto 0
```

When you're ready, you can trigger garbage collection of all repositories
with the `gc.sh` script.

```sh
$ ../gc.sh
```
