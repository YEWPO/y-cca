# y-cca

An Arm CCA Architecture with **Planes** feature.

## Tools

Make sure that all the following tools are installed on your local:

- python3-pyelftools, python3-venv
- acpica-tools
- openssl (debian libssl-dev)
- libglib2.0-dev, libpixman-1-dev
- dtc (debian device-tree-compiler)
- flex, bison
- make, cmake, ninja (debian ninja-build), curl, rsync
- tmux
- aarch64 cross compilers
- socat

## Install

First, clone this repository to your local.

All dependencies list in `scripts/init.sh`, you can edit it when necessary.

Download dependencies by execute:

```shell
make init
```

Build all dependencies by execute:

```shell
make build
```

Run the CCA system by execute:

```shell
make run
```

## Launching Realm Guest

We created scripts for QEMU and LKVM to launch Realm Guest.

Launching Realm Guest by QEMU:

```shell
/mnt/scripts/qemu_realm.sh
```

Launching Realm Guest by LKVM:

```shell
/mnt/scripts/lkvm_realm.sh
```

