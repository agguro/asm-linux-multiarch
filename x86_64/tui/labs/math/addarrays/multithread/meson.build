# x86_64/labs/math/addarrays/threaded/meson.build

project_name = 'threaded_avx2_addarrays'
libs = []

# 1. Namespace Automation
rel_path = meson.current_source_dir().replace(meson.project_source_root() + '/', '')
target_id = rel_path.replace('/', '_')

# 2. Define all required source files
sources = files(
    'main_threaded.s',           # The Thread Manager
    'avx2_thread_bridge.s',      # The Glue/Wrapper
    'generate_data.s',           # The Data Initializer
    'avx2_addarrays_float.s'     # The Reused AVX2 Worker
)

# 3. Handle Linker Flags
# Use a local variable so we don't accidentally pollute the global ld_flags for other labs
local_ld_flags = ld_flags + ['-lpthread', '-lc']

# 4. Assemble Phase
objs = []
counter = 0
foreach s : sources
    counter += 1
    # Use target_id to prevent global object collisions
    obj_id = target_id + '_obj_' + counter.to_string()

    # Build targets and commands safely
    target_outputs = ['@BASENAME@.o']
    asm_cmd = [as]

    if is_debug
        target_outputs += ['@BASENAME@.lst']
        # ONLY add @OUTPUT1@ when is_debug is True
        asm_cmd += ['-g', '-al=@OUTPUT1@']
    endif

    asm_cmd += ['@INPUT@', '-o', '@OUTPUT0@']

    objs += custom_target(
        obj_id,
        input: s,
        output: target_outputs,
        command: asm_cmd
    )
endforeach

# 5. Link Inputs
link_inputs = []
foreach o : objs
    link_inputs += o[0]
endforeach

# 6. Final Linking
executable_bin = custom_target(
    target_id,              # Internal Unique ID
    input: link_inputs,
    output: project_name,   # Filename on disk
    command: [ld, local_ld_flags, '-o', '@OUTPUT@', '@INPUT@'],
    install: true,
    install_dir: install_path,
    build_by_default: true
)

# 7. Run Target
run_target('run-' + target_id, command: [executable_bin])