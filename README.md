# kicad-bazel

This repository makes it easy to use KiCad automation in the build
process of other Bazel-based projects using its [Python scripting
interface](https://docs.kicad.org/doxygen-python/index.html).

## Usage

Adding the following to your `MODULE.bazel` file will make this
repository available in your project:

```Starlark
bazel_dep(name = "rules_kicad", version = "0.0.0")
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
optional CSV file with additional information about each part like
manufacturer-specific part numbers. This CSV must have `Package`
and `Value` columns which are used to match parts from the KiCad file.

```Starlark
load("@rules_kicad//tools:defs.bzl", "kicad_bom")
kicad_bom(
    name = "comet_bom",
    src = "comet.kicad_pcb",
    component_file = "comet_parts.csv",
)
```

## Dependencies

KiCad 10 must be installed. On Windows the installation is detected
automatically from common install locations. On Linux, install via the
official KiCad PPA:

```bash
sudo add-apt-repository ppa:kicad/kicad-10.0-releases
sudo apt-get install kicad
```
