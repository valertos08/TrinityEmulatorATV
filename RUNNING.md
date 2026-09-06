# Running Trinity ATV Emulator on Debian/Ubuntu (prebuilt binaries)

## 1. Prerequisites

### Hardware

- x86_64 CPU with **VT-x / AMD-V** - enable virtualization in BIOS (required for KVM acceleration)
- **8 GB RAM** or more (8 GB is allocated to the VM)

### Software

Runtime libraries needed by the prebuilt binary:

```bash
sudo apt install libpixman-1-0 libglfw3 libepoxy0 libgbm1 libdrm2 \
  libvirglrenderer1 libsdl2-2.0-0 libslirp0 liblzo2-2 libcapstone4 \
  libaio1t64 libbz2-1.0 libzstd1 liblz4-1 libpulse0 \
  libasound2t64 libglib2.0-0t64
```

> On older Debian versions the `-t64` packages are named `libaio1`, `libasound2`, `libglib2.0-0`.

## 2. Check KVM

```bash
[ -r /dev/kvm ] && echo "OK: KVM available" || echo "No KVM - enable virtualization in BIOS"
```

## 3. Running

The `run-atv.sh` script is located in the emulator directory:

```bash
cd /path/to/emulator
./run-atv.sh -d /path/to/disk.img -i /path/to/lineage.iso
```

### Options

| Flag            | Purpose                                                        |
|-----------------|----------------------------------------------------------------|
| `-d PATH`       | path to disk image (qcow2/img) - always required               |
| `-i PATH`       | Android image (ISO) - for the first-time install               |
| `-D sdl\|gtk`   | window backend; `sdl` by default (renders virgl on NVIDIA)     |
| `-L/--legacy`   | direct-express mode (for the Trinity Android 9 image)          |

If the disk path is already set in the script, just run:

```bash
./run-atv.sh
```

## 4. Usage

- Mouse and keyboard work immediately in the window
- ADB is available on `localhost:5555`
- Graphics are accelerated via `virtio-gpu` + `virglrenderer` on your physical GPU

## Troubleshooting

| Problem                                              | Fix                       |
|------------------------------------------------------|---------------------------|
| `/usr/bin/ld: cannot find -lglfw` or binary fails    | install `libglfw3`        |
| `libvirglrenderer.so.1: cannot open shared object`   | install `libvirglrenderer1` |
| black screen in GTK window                           | use `-D sdl`              |
| slow performance                                     | check `/dev/kvm`          |