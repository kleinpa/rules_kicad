# rules_kicad

This repository makes it easy to use limited KiCad automation into the
build process of other Bazel-based projects using it's [python
scripting
interface](https://docs.kicad.org/doxygen-python/index.html).

These rules expect your operating system to have KiCad installed.

## Usage

In `MODULE.bazel` add:

```
bazel_dep(name = "rules_kicad")
git_override(
    module_name = "rules_kicad",
    remote = "https://github.com/kleinpa/rules_kicad",
    commit = "...",
)
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
