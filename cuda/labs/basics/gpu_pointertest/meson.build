# cuda/labs/basics/gpu_pointer_test/meson.build

# Skip entirely if CUDA is not available
if not cuda_found
    message('Skipping CUDA lab: ' + meson.current_source_dir())
    subdir_done()
endif

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================
name      = 'gpu_pointer_test'
main_src  = 'main.s'
ptx_src   = 'kernel.ptx'
gpu_arch  = 'sm_61'

libs = []

main_base = main_src.split('.')[0]
ptx_base  = ptx_src.split('.')[0]

rel_path = meson.current_source_dir().replace(meson.project_source_root() + '/', '')
target_id = rel_path.replace('/', '_')

# =============================================================================
# 1. CUBIN GENERATION
# =============================================================================
ptxas_cmd = []
if ptxas.found()
    ptxas_cmd = [
        ptxas,
        '-v',
        '-arch=' + gpu_arch,
        '@INPUT@',
        '-o', '@OUTPUT@'
    ]
endif

gen_cubin = custom_target(
    target_id + '_cubin',
    input: ptx_src,
    output: ptx_base + '.cubin',
    command: ptxas_cmd
)

# =============================================================================
# 2. MAIN ASSEMBLY
# =============================================================================
gen_main_obj = custom_target(
    target_id + '_main_obj',
    input: main_src,
    output: [main_base + '.o', main_base + '.lst'],
    command: [
        as, as_flags,
        '-I', meson.current_build_dir(),
        '-al=@OUTPUT1@', '@INPUT@',
        '-o', '@OUTPUT0@'
    ],
    depends: [gen_cubin]
)

# =============================================================================
# 3. UTILITY LIBS
# =============================================================================
objs_targets = [gen_main_obj]
i = 0
foreach l : libs
    i += 1
    objs_targets += custom_target(
        target_id + '_' + i.to_string() + '_obj',
        input: asm_libs[l],
        output: ['@BASENAME@.o', '@BASENAME@.lst'],
        command: [as, as_flags, '-al=@OUTPUT1@', '@INPUT@', '-o', '@OUTPUT0@']
    )
endforeach

# =============================================================================
# 4. LINKING
# =============================================================================
link_inputs = []
foreach t : objs_targets
    link_inputs += t[0]
endforeach

executable_bin = custom_target(
    target_id,
    input: link_inputs,
    output: name,
    command: [
        ld, ld_flags,
        '-o', '@OUTPUT@',
        '@INPUT@',
        cuda_lib_path,
        '-lcuda',
        '-lc',
        '-rpath', '$ORIGIN',
        '-z', 'origin'
    ],
    build_by_default: true,
    install: true,
    install_dir: install_path
)

# =============================================================================
# 5. DEBUG EXTRAS
# =============================================================================
if get_option('buildtype') == 'debug'
    custom_target(target_id + '_sass',
        input: gen_cubin,
        output: name + '.sass',
        command: ['cuobjdump', '-sass', '@INPUT@'],
        capture: true,
        build_by_default: true
    )

    custom_target(target_id + '_res',
        input: gen_cubin,
        output: name + '.res',
        command: ['cuobjdump', '-res-usage', '@INPUT@'],
        capture: true,
        build_by_default: true
    )
endif

run_target('run-' + target_id, command: [executable_bin])
