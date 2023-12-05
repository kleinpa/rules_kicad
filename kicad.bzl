# TODO(kleinpa): refactor to download files when loading repository.

_KICAD_INSTALL_BUILD = """
load("@rules_python//python:defs.bzl", "py_library", "py_runtime", "py_runtime_pair")

py_runtime(
    name = "python3",
    files = glob(["install/**"]),
    interpreter = "install/python.exe",
    python_version = "PY3",
)

py_runtime_pair(
    name = "python_pair",
    py3_runtime = ":python3",
)

toolchain(
    name = "python_toolchain",
    toolchain = ":python_pair",
    toolchain_type = "@bazel_tools//tools/python:toolchain_type",
)
"""

def _kicad_repo_impl(ctx):
    ctx.file("WORKSPACE", "workspace(name = \"{name}\")".format(name = ctx.name))
    ctx.file("BUILD.bazel", _KICAD_INSTALL_BUILD)
    ctx.symlink(ctx.attr.install_path, "install")

kicad_repo = repository_rule(
    implementation = _kicad_repo_impl,
    attrs = {
        "install_path": attr.string(default = "C:/Program Files/KiCad/7.0/bin/"),
    },
)

def _kicad_module_impl(_):
    kicad_repo(name = "kicad")

kicad = module_extension(implementation = _kicad_module_impl)
