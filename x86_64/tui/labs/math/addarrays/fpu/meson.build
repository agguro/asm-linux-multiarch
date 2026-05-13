# x86_64/labs/math/addarrays/fpu/meson.build

name = 'fpu_addarrays'
libs = []
sources = files(name + '.s','main.s')

rel_path = meson.current_source_dir().replace(meson.project_source_root() + '/', '')
target_id = rel_path.replace('/', '_')

foreach l : libs
    sources += asm_libs[l]
endforeach

objs = []
counter = 0
foreach s : sources
    counter += 1
    # Unique ID: x86_64_Labs_math_avx_addarrays_obj_1
    obj_id = target_id + '_obj_' + counter.to_string()
    
    # Define outputs: In release mode, we only output the .o file
    target_outputs = ['@BASENAME@.o']
    
    # Define the command base
    cmd = [as]
    
    # Add debug-specific outputs and flags
    if is_debug
        target_outputs += ['@BASENAME@.lst']
        cmd += ['-al=@OUTPUT1@'] # Only present when target_outputs has 2 items
    endif
    
    # Append input and primary output
    cmd += ['@INPUT@', '-o', '@OUTPUT0@']
    
    objs += custom_target(
        obj_id,
        input: s,
        output: target_outputs,
        command: cmd
    )
endforeach

link_inputs = []
foreach o : objs
    link_inputs += o[0] 
endforeach

executable_bin = custom_target(
    target_id,             # Internal handle: x86_64_Labs_math_avx_addarrays
    input: link_inputs,
    output: name,          # Filename on disk: avx_addarrays
    command: [ld, ld_flags, '-o', '@OUTPUT@', '@INPUT@'],
    install: true,
    install_dir: install_path,
    build_by_default: true
)

run_target('run-' + target_id, command: [executable_bin])

