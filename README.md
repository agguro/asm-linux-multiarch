# Linux Assembly Programming (Multi-Arch)

A modern approach to low-level Linux programming. This repository focuses on pure assembly and GPU acceleration using the native GNU toolchain and the Meson Build system.

---

## 🏗 Supported Architectures
* **x86_64:** Current implementation.
* **ARM / RISC-V:** Planned support for a truly multi-architectural codebase.

## 🛠 Modern Toolchain
This project has been rebuilt to remove legacy dependencies. It relies exclusively on:

* **Assembler:** `as` (The GNU Assembler)
* **Linker:** `ld` (The GNU Linker)
* **GPU:** `nvcc` (NVIDIA CUDA)
* **Build System:** **Meson** (with `ninja` backend)

---

## 🚀 Why Meson?
The move to Meson replaces the previous mix of Make, QMake, CMake, and Autotools. 
* **Speed:** Faster builds via Ninja.
* **Native Multi-arch:** Cleaner handling of cross-compilation and architecture-specific flags.
* **Simplicity:** No more complex M4 macros or fragile Makefiles.

## 📂 Project Structure
### Include Files
Direct conversions of C header files for use with the GNU Assembler.
> **⚠️ Warning:** These files are provided "as-is." While I've worked to eliminate typos, not all includes are fully tested. Use at your own risk.


## 🌐 Legacy Archive
Contains examples from the original **linuxnasm.be** collection, ported for the GNU toolchain and optimized for the new build flow.

---

## ⚙️ Build Instructions
To build the project, ensure you have `meson` and `ninja-build` installed.

```bash
# Setup the build directory
meson setup build

# Compile all targets
meson compile -C build
