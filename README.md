# y-cca

An Arm CCA Architecture with **Planes** feature.

## 🛠️ Tools

Make sure that all the following tools are installed on your local:

- python3-pyelftools, python3-venv
- acpica-tools
- openssl (debian libssl-dev)
- libglib2.0-dev, libpixman-1-dev
- dtc (debian device-tree-compiler)
- flex, bison
- make, cmake, ninja (debian ninja-build), curl, rsync
- tmux
- aarch64 crossing-compilers

## 📌 Install

> ❗ Make sure you have **at least 40G** of disk space. After the compilation is complete, 25G of disk space will be consumed.

The deployment architecture is shown as the following figure:

<img src="https://raw.githubusercontent.com/YEWPO/yewpoblogonlinePic/main/cca-deploy.png" alt="cca-deploy" width=450px />

First, clone this repository to your local:

```shell
git clone https://github.com/YEWPO/y-cca.git
```

All dependencies list in `scripts/init.sh`, you can edit it when necessary.

Download dependencies by execute:

```shell
make init
```

Build all dependencies by execute (If you modified the codes, re-run this command is necessary):

```shell
make build
```

By default, the RMM version is v1.0. To build RMM v1.1, execute:

```shell
make build RMM_V1_1=ON
```

## 🚀 Launching System and Realm Guest

Run the CCA system by execute:

```shell
make run
```

We created scripts for QEMU and LKVM to launch Realm Guest, you can use it to launch guest.

Launching Realm Guest by QEMU:

```shell
/mnt/scripts/qemu_realm.sh
```

Launching Realm Guest by LKVM:

```shell
/mnt/scripts/lkvm_realm.sh
```

## 🔗 Code Base

- Our RMM based on [Linaro RMM](https://git.codelinaro.org/linaro/dcap/rmm), branch `cca/v4`.
- Our Linux based on [Linaro linux-cca](https://gitlab.arm.com/linux-arm/linux-cca), branch `cca-full/v5+v7`.
