# /meson.build

project('linux-multiarch-asm', ['c','cpp'], version: '0.1', default_options: ['warning_level=3'])

as = find_program('as')
ld = find_program('ld')

nvcc = find_program('nvcc', required: false)
cuda_found = nvcc.found()

inc_path = meson.current_source_dir() / 'x86_64/include'
asm_lib_dir = 'x86_64/lib'
cuda_lib_path = '-L/usr/local/cuda/lib64'
standard_libs = ['-lc', '-lpthread']

# The index using the base path - inherited by all subdirs
asm_libs = {}

# Base flags (Common to all builds)
as_flags = ['--64', '--noexecstack', '-I' + inc_path]
ld_flags = ['-m', 'elf_x86_64', '-pie', '-z', 'noexecstack', '--dynamic-linker', '/lib64/ld-linux-x86-64.so.2']

# Build-type specific flags
is_debug = get_option('buildtype') == 'debug'

if is_debug
    as_flags += ['-g', '--compress-debug-sections=none']
else
    ld_flags += ['-s']
endif

subdir('x86_64')
# Only dive into CUDA labs if CUDA was found at the root
if cuda_found
    subdir('cuda')
endif
