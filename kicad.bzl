# TODO(kleinpa): refactor to download files when loading repository.

_KICAD_INSTALL_BUILD_WINDOWS = """
load("@rules_python//python:defs.bzl", "py_runtime", "py_runtime_pair")

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
    visibility = ["//visibility:public"],
)
"""

_KICAD_INSTALL_BUILD_LINUX = """
load("@rules_python//python:defs.bzl", "py_runtime", "py_runtime_pair")

py_runtime(
    name = "python3",
    interpreter_path = "/usr/bin/python3",
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
    visibility = ["//visibility:public"],
)
"""

def _find_kicad_install_windows(ctx):
    """Find the newest KiCad installation on Windows, checking both user and system locations."""
    localappdata = ctx.os.environ.get("LOCALAPPDATA", "").replace("\\", "/")
    search_paths = ["C:/Program Files/KiCad"]
    if localappdata:
        search_paths = [localappdata + "/Programs/KiCad"] + search_paths

    result = ctx.execute([
        "powershell", "-NoProfile", "-NonInteractive", "-Command",
        " ".join([
            "$bases = @(" + ", ".join(["'" + p + "'" for p in search_paths]) + ");",
            "$bases | Where-Object { Test-Path $_ } |",
            "ForEach-Object { Get-ChildItem $_ -Directory } |",
            "Where-Object { Test-Path (Join-Path $_.FullName 'bin') } |",
            "Sort-Object { try { [version]$_.Name } catch { [version]'0.0' } } -Descending |",
            "Select-Object -First 1 |",
            "ForEach-Object { Join-Path $_.FullName 'bin' }",
        ]),
    ])
    if result.return_code == 0:
        path = result.stdout.strip().replace("\\", "/")
        if path:
            return path
    return None

def _kicad_repo_impl(ctx):
    ctx.file("WORKSPACE", "workspace(name = \"{name}\")".format(name = ctx.name))
    if ctx.os.name == "linux":
        ctx.file("BUILD.bazel", _KICAD_INSTALL_BUILD_LINUX)
    else:
        install_path = ctx.os.environ.get("KICAD_INSTALL_PATH", "")
        if not install_path:
            install_path = _find_kicad_install_windows(ctx)
        if not install_path:
            fail("KiCad not found. Set KICAD_INSTALL_PATH to the KiCad bin directory.")
        ctx.file("BUILD.bazel", _KICAD_INSTALL_BUILD_WINDOWS)
        ctx.symlink(install_path, "install")

kicad_repo = repository_rule(
    implementation = _kicad_repo_impl,
    environ = ["KICAD_INSTALL_PATH", "LOCALAPPDATA"],
)

def _kicad_module_impl(_):
    kicad_repo(name = "kicad")

kicad = module_extension(implementation = _kicad_module_impl)
