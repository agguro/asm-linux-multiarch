# AVX Assembly Examples

This directory contains $$scalar$$; **AVX**, **AVX2**, and **AVX-512** assembly examples written in pure **gnu as**. Each example typically includes a `main.s` wrapper used to interface with the assembly routines and demonstrate SIMD operations.

These examples demonstrate SIMD (Single Instruction, Multiple Data) vector operations and are intended as low-level reference material, not as portable binaries.

---

## ⚠️ Important: CPU Feature Requirements

AVX instructions are hardware-dependent. If your CPU does not support a specific instruction set (e.g., AVX2 or AVX-512), executing the binary will result in:

`Illegal instruction (core dumped)`

**This is expected behavior and not a build error.** Typical situations where this occurs:
* **Hardware Mismatch:** Running AVX2 code on an older, AVX-only CPU.
* **Consumer Limitations:** Running AVX-512 code on consumer CPUs that lack these specific extensions.
* **Virtualization:** Running AVX code inside virtual machines without proper CPU feature pass-through (Nested Virtualization).

### How to check your local CPU support:
Run the following command in your terminal to see which flags your CPU supports:
grep -E 'avx|avx2|avx512' /proc/cpuinfo

---

## 🛠 Intel® Software Development Emulator (SDE)

To allow testing on systems without native AVX support, this archive supports execution using the **Intel® Software Development Emulator (SDE)**. SDE emulates modern Intel CPUs and instruction sets entirely in software.

**Download:** [Intel® SDE Official Page](https://www.intel.com/content/www/us/en/developer/articles/tool/software-development-emulator.html)

### Why SDE is useful here:
* **Hardware Independence:** Test AVX / AVX2 / AVX-512 without compatible hardware.
* **Verification:** Verify the logical correctness of assembly routines.
* **Preservation:** Test historical examples without modifying the code.
* **Longevity:** Keep this archive buildable and testable on future hardware.

### Running AVX Examples with SDE
After downloading and extracting Intel SDE, use `sde64` to launch the binaries:

# Basic AVX2 testing
./sde64 -- ./avx2_addArrays

# Explicitly select a CPU model (e.g., Skylake-X for AVX-512)
./sde64 -skx -- ./avx512_addArrays

**Common CPU options:**
* `-hsw` — Haswell (AVX2)
* `-skx` — Skylake-X (AVX-512)
* `--` — Separator between SDE options and the binary path.

> **Note:** SDE is an emulator; execution will be significantly slower than native hardware.

---

## 📂 Examples

Each folder contains the NASM source, the C++ wrapper, and a specific README/Makefile.

* [avx_addArrays](./avx_addArrays) — Standard 128/256-bit AVX operations.
* [avx2_addArrays](./avx2_addArrays) — 256-bit integer and floating-point operations.
* [avx512_addArrays](./avx512_addArrays) — 512-bit vector operations (Requires SKX or SDE).

---

## 📚 Summary
* **"Illegal instruction"** means the hardware lacks the required feature.
* **Use Intel SDE** to bridge the gap if your CPU is older.
* **Alignment is critical:** Most SIMD instructions require 16, 32, or 64-byte alignment.
