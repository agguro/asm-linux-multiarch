# x86_64/tui/labs/basics/dealcards/meson.build

name = 'dealcards'
libs = ['u64toa','strlen','print_stringz','fisher_yates_shuffle','sattolo_shuffle','merge_shuffle','print_uint8array']
rel_path = meson.current_source_dir().replace(meson.project_source_root() + '/', '')
target_id = rel_path.replace('/', '_')

sources = files(name + '.s')
foreach l : libs
    sources += asm_libs[l]
endforeach

objs = []
i = 0
foreach s : sources
    i += 1
    objs += custom_target(
        target_id + '_' + i.to_string() + '_obj', 
        input: s,
        output: ['@BASENAME@.o', '@BASENAME@.lst'],
        command: [as, as_flags, '-al=@OUTPUT1@', '@INPUT@', '-o', '@OUTPUT0@']
    )
endforeach

# Filter: Object files only
link_inputs = []
foreach o : objs
    link_inputs += o[0]
endforeach

executable_bin = custom_target(
    target_id,             # The Meson Handle (Must be unique)
    input: link_inputs,
    output: name,          # The Filename on disk (Can stay 'arguments')
    command: [ld, ld_flags, '-o', '@OUTPUT@', '@INPUT@'],
    build_by_default: true,
    install: true,
    install_dir: install_path,
    install_mode: 'rwxr-xr-x',
)

# run-x86_64_labs_basics_arguments
run_target('run-' + target_id,
    command: [executable_bin]
)
