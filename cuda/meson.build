# cuda/meson.build

if not cuda_found
    message('CUDA not found — skipping CUDA build in x86_64/cuda')
    subdir_done()
endif

ptxas = find_program('ptxas', required: false)

# 1. Global CUDA Flags
cuda_flags = [
    '-gencode', 'arch=compute_61,code=sm_61',
    '-O3',
    '-Xcompiler', '-fPIC'
]

# 2. Release vs Debug Toggle
cpp_args = []
if get_option('buildtype') == 'release'
    cpp_args += '-DRELEASE_BUILD'
endif

# 3. Common Linker Args
cuda_libs = ['-lcuda', '-lcudart']

cuda_sep_comp = true

cuda_link_args = [
    cuda_lib_path,
    '-lcudart',
    '-lcuda'
] + standard_libs

subdir('labs')

