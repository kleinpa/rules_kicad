load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def kicadbazel_repos():
    if not native.existing_rule("rules_python"):
        http_archive(
            name = "rules_python",
            sha256 = "b6d46438523a3ec0f3cead544190ee13223a52f6a6765a29eae7b7cc24cc83a0",
            url = "https://github.com/bazelbuild/rules_python/releases/download/0.1.0/rules_python-0.1.0.tar.gz",
        )
    if not native.existing_rule("com_gitlab_kicad_kicad"):
        http_archive(
            name = "com_gitlab_kicad_kicad",
            build_file = "@com_github_kleinpa_kicadbazel//external:kicad-BUILD.bazel",
            patch_args = ["-p1"],
            patches = ["@com_github_kleinpa_kicadbazel//external:kicad.patch"],
            sha256 = "8e10e556e45aebb73a75f67801bca27241a747ed7bd4e06ab4eff330ae16b6c8",
            strip_prefix = "kicad-320ca5a0d0df232455718dffe9d62e05d5122ac7",
            url = "https://gitlab.com/kicad/code/kicad/-/archive/320ca5a0d0df232455718dffe9d62e05d5122ac7/kicad-320ca5a0d0df232455718dffe9d62e05d5122ac7.tar.gz",
        )
    if not native.existing_rule("rules_foreign_cc"):
        http_archive(
            name = "rules_foreign_cc",
            sha256 = "59d33bcee9e5d06e5e00a2dcb00d6ea2b5304f3d22c81a659e70702edf3a56fc",
            strip_prefix = "rules_foreign_cc-cef5ee61ffc8ebf947291dccb1f35258b42a42f2",
            url = "https://github.com/bazelbuild/rules_foreign_cc/archive/cef5ee61ffc8ebf947291dccb1f35258b42a42f2.zip",
        )
