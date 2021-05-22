def _kicad_gerbers(ctx):
    output_file = ctx.actions.declare_file("{}.zip".format(ctx.label.name))
    ctx.actions.run(
        inputs = [ctx.file.src],
        outputs = [output_file],
        arguments = [
            "--input={}".format(ctx.file.src.path),
            "--output={}".format(output_file.path),
        ],
        env = {"LD_LIBRARY_PATH": ctx.executable.gerbers_tool.path + ".runfiles/com_gitlab_kicad_kicad"},
        executable = ctx.executable.gerbers_tool,
    )
    return DefaultInfo(
        files = depset([output_file]),
        runfiles = ctx.runfiles([output_file]),
    )

kicad_gerbers = rule(
    implementation = _kicad_gerbers,
    attrs = {
        "src": attr.label(
            allow_single_file = [".kicad_pcb"],
            mandatory = True,
        ),
        "gerbers_tool": attr.label(
            default = Label("//tools:gerbers"),
            executable = True,
            cfg = "exec",
        ),
    },
)
