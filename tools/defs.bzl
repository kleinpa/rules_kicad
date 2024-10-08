def _kicad_gerbers(ctx):
    output_file = ctx.actions.declare_file("{}.zip".format(ctx.label.name))
    ctx.actions.run(
        inputs = [ctx.file.src],
        outputs = [output_file],
        arguments = [
            "--input={}".format(ctx.file.src.path),
            "--output={}".format(output_file.path),
        ],
        env = {"LD_LIBRARY_PATH": ctx.executable.gerbers_tool.path + ".runfiles/kicad"},
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

def _kicad_bom(ctx):
    bom_output = ctx.actions.declare_file("{}.csv".format(ctx.label.name))
    if ctx.file.component_file:
        ctx.actions.run(
            inputs = [ctx.file.src, ctx.file.component_file],
            outputs = [bom_output],
            arguments = [
                "--input={}".format(ctx.file.src.path),
                "--output={}".format(bom_output.path),
                "--component_file={}".format(ctx.file.component_file.path),
                "--fields={}".format(",".join(ctx.attr.fields)),
                "--format=csv",
            ],
            env = {"LD_LIBRARY_PATH": ctx.executable._bom.path + ".runfiles/kicad"},
            executable = ctx.executable._bom,
        )
    else:
        ctx.actions.run(
            inputs = [ctx.file.src],
            outputs = [bom_output],
            arguments = [
                "--input={}".format(ctx.file.src.path),
                "--output={}".format(bom_output.path),
                "--fields={}".format(",".join(ctx.attr.fields)),
                "--format=csv",
            ],
            env = {"LD_LIBRARY_PATH": ctx.executable._bom.path + ".runfiles/kicad"},
            executable = ctx.executable._bom,
        )
    return DefaultInfo(files = depset([bom_output]))

kicad_bom = rule(
    implementation = _kicad_bom,
    attrs = {
        "src": attr.label(
            allow_single_file = [".kicad_pcb"],
            mandatory = True,
        ),
        "component_file": attr.label(
            allow_single_file = [".csv"],
        ),
        "fields": attr.string_list(
            default = ["Designator", "Package", "Value"],
        ),
        "_bom": attr.label(
            default = Label("//tools:bom"),
            executable = True,
            cfg = "exec",
        ),
    },
)
