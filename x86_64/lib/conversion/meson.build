# x86_64/lib/conversion/meson.build

source_files = [
#  'atouint128.s',
#  'atouint16.s',
#  'atouint256.s',
#  'atouint32.s',
#  'atouint4.s',
#  'atouint512.s',
#  'atouint64.s',
#  'atouint8.s',
  'u64toa',
  'u64tobin',
  'u64tohex'
#  'uint128toa.s',
#  'uint16toa.s',
#  'uint256toa.s',
#  'uint32toa.s',
#  'uint4toa.s',
#  'uint512toa.s',
#  'uint64toa.s',
#  'uint8toa.s'
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
