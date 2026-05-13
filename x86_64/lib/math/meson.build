# x86_64/lib/math/meson.build

# 1. Define the files
source_files = [
    'fisher_yates_shuffle',
    'merge_shuffle',
    'nlz',
    'popcount',
    'sattolo_shuffle',
    'signed_rotate'
]

rel_path = meson.current_source_dir().replace(meson.project_source_root() + '/', '')
target_id = rel_path.replace('/', '_')

temp_lib = {}

foreach name : source_files
    s_file = files(name + '.s')
    temp_lib += { name : s_file }
    custom_target(
        target_id + name,
        input: s_file,
        output: ['@BASENAME@.o', '@BASENAME@.lst'],
        command: [as, as_flags, '-al=@OUTPUT1@', '@INPUT@', '-o', '@OUTPUT0@'],
        build_by_default: true
    )
endforeach

asm_libs += temp_lib