# kicad-bazel

This repository makes it easy to use limited KiCad automation into the
build process of other Bazel-based projects using it's [python
scripting
interface](https://docs.kicad.org/doxygen-python/index.html). The
version of KiCad is fixed to a development KiCad 6 snapshot to take
advantage of the recently improved scripting interface.

Under the hood, the KiCad dependency is handled by using
[`rules_foreign_cc` ](https://github.com/bazelbuild/rules_foreign_cc/)
to build it from source. Currently all of KiCad gets built even though
we really just need a couple binaries so it's painfully slow build but
Bazel's caching makes this bearable.

Only Linux and specifically Ubuntu have been tested so far. Other
distributions will probably work fine but exact dependencies will need
to be investigated.

## Usage

Adding the following to your `WORKSPACE` file will make this
repository available in your project:

```Starlark
http_archive(
    name = "rules_kicad",
    sha256 = "<sha>",
    url = "https://github.com/kleinpa/kicad-bazel/archive/<git-hash>.tar.gz",
    strip_prefix = "kicad-bazel-<git-hash>",
)

load("@rules_kicad//:deps.bzl", "kicadbazel_deps")
kicadbazel_deps()
```

A build rule is provided to create a Gerber archive from a
`.kicad_pcb` file. This script is tailored somewhat inflexibly to the
format accepted by JLCPCB.

```Starlark
load("@rules_kicad//tools:defs.bzl", "kicad_gerbers")
kicad_gerbers(
    name = "pcb",
    src = "pcb.kicad_pcb",
)
```

BOM generation is a work in progress but limited functionality is
available via the `kicad_bom()` build rule. This rule accepts an
optinal CSV file with additional information about each part like
manufacturer-specififc part numbers. This CSV must have a 'Footprint'
and 'Value' columns which are used to match parts from the kicad file.

```Starlark
load("@rules_kicad//tools:defs.bzl", "kicad_bom")
kicad_bom(
    name = "comet_bom",
    src = "comet.kicad_pcb",
    component_file = "comet_parts.csv",
)
```

One known issue is that one KiCad shared library is not placed in the
default search path by the Bazel build process. The solution for
fixing without moving that file is to override `LD_LIBRARY_PATH`. This
is needed both for [custom rules](tools/defs.bzl) and when using
genrule():

```Starlark
genrule(
    name = "foo",
    cmd = "LD_LIBRARY_PATH='$(execpath //:bin).runfiles/com_gitlab_kicad_kicad' ./$(location //:bin)",
    exec_tools = [
        "@com_gitlab_kleinpa_kicadbazel//:pcbnew",
    ],
    ...
)
```

## Dependencies

This library does it's own build of KiCad from source so shares KiCad
build dependencies. On debian, the packages required to use this
library are:

```sh
$ apt install build-essential cmake libboost-dev libboost-filesystem-dev libboost-test-dev libcairo2-dev libcurl4-openssl-dev libgl-dev libglew-dev libglm-dev libgtk-3-dev libpython3-dev libssl-dev libwxgtk3.0-gtk3-dev swig
```
