project('netorcai-client', 'd', version: '2.0.0')

src = [
    'src/netorcai/client.d',
    'src/netorcai/json_util.d',
    'src/netorcai/message.d',
    'src/netorcai/package.d',
    'src/netorcai/test.d'
]

# Explictly link standard library if ldc is used
if meson.get_compiler('d').get_id() == 'llvm'
  extra_args = ['-link-defaultlib-shared']
else
  extra_args = []
endif

incdir = include_directories('src')

lib = library('netorcai-client',
    src,
    include_directories: [incdir],
    install: true, install_dir: 'lib',
    link_args : extra_args
)

pkgc = import('pkgconfig')
pkgc.generate(name: 'netorcai-client-d',
    libraries: lib,
    subdirs: 'd/netorcai',
    version: meson.project_version(),
    description: 'A netorcai client library.'
)
install_subdir('src/netorcai/', install_dir: 'include/d/netorcai/')
