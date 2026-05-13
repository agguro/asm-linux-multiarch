# x86_64/labs/math/addarrays/meson.build

simd_install_path = 'labs/math/addarrays'

sse_as_args    = as_flags
avx_as_args    = as_flags + ['-march=corei7+avx']
avx2_as_args   = as_flags + ['-march=corei7+avx2']
avx512_as_args = as_flags + ['-march=corei7+avx512f']

ld_flags = ld_flags + ['-lc']

subdir('sse')
subdir('avx')
subdir('avx2')
subdir('avx512')
subdir('scalar')
subdir('fpu')
subdir('multithread')
