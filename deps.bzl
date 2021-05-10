load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")
load("@rules_python//python:pip.bzl", "pip_install")

def kicadbazel_deps():
    rules_foreign_cc_dependencies()

    pip_install(
        name = "com_github_kleinpa_kicadbazel_py_deps",
        requirements = "@com_github_kleinpa_kicadbazel//:requirements.txt",
    )
