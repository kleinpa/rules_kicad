def _gerbers_from_kicad(ctx):
    output_file = ctx.actions.declare_file("{}.zip".format(ctx.label.name))
    ctx.actions.run(
        inputs = [ctx.file.src],
        outputs = [output_file],
        arguments = [
            "--input={}".format(ctx.file.src.path),
            "--output={}".format(output_file.path),
        ],
        env = {"LD_LIBRARY_PATH": ctx.executable.kicad_to_gerber_tool.path + ".runfiles/com_gitlab_kicad_kicad"},
        executable = ctx.executable.kicad_to_gerber_tool,
    )
    return DefaultInfo(
        files = depset([output_file]),
        runfiles = ctx.runfiles([output_file]),
    )

gerbers_from_kicad = rule(
    implementation = _gerbers_from_kicad,
    attrs = {
        "src": attr.label(
            allow_single_file = [".kicad_pcb"],
            mandatory = True,
        ),
        "kicad_to_gerber_tool": attr.label(
            default = Label("//tools:kicad_to_gerber"),
            executable = True,
            cfg = "exec",
        ),
    },
)
