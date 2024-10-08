"""Convert a .kicad_pcb file into a gerber archive ready for manufacturing."""

import io
import os
import shutil
import tempfile
import zipfile

import pcbnew
from absl import app, flags

FLAGS = flags.FLAGS
flags.DEFINE_string('input', '', 'Path to .kicad_pcb file')
flags.DEFINE_string('output', '', 'Path to write .zip file containing gerbers')


def kicad_file_to_gerber_archive_file(input_path, output_path):
    board = pcbnew.LoadBoard(input_path)

    pctl = pcbnew.PLOT_CONTROLLER(board)

    popt = pctl.GetPlotOptions()
    popt.SetPlotFrameRef(False)
    popt.SetAutoScale(False)
    popt.SetScale(1)
    popt.SetMirror(False)
    popt.SetUseGerberAttributes(False)
    popt.SetScale(1)
    popt.SetUseAuxOrigin(True)
    popt.SetNegative(False)
    popt.SetPlotReference(True)
    popt.SetPlotValue(True)
    popt.SetPlotInvisibleText(False)
    popt.SetSubtractMaskFromSilk(True)
    popt.SetMirror(False)
    popt.SetDrillMarksType(pcbnew.DRILL_MARKS_NO_DRILL_SHAPE)

    # TODO(kleinpa): Will JLCPCB accept file without this set?
    popt.SetUseGerberProtelExtensions(True)

    plot_plan = [("F_Cu", pcbnew.F_Cu, "Top layer"),
                 ("B_Cu", pcbnew.B_Cu, "Bottom layer"),
                 ("B_Mask", pcbnew.B_Mask, "Mask Bottom"),
                 ("F_Mask", pcbnew.F_Mask, "Mask top"),
                 ("B_Paste", pcbnew.B_Paste, "Paste Bottom"),
                 ("F_Paste", pcbnew.F_Paste, "Paste Top"),
                 ("F_SilkS", pcbnew.F_SilkS, "Silk Top"),
                 ("B_SilkS", pcbnew.B_SilkS, "Silk Bottom"),
                 ("Edge_Cuts", pcbnew.Edge_Cuts, "Edges")]

    for layer in range(1, board.GetCopperLayerCount() - 1):
        plot_plan += (f"inner{layer}", layer, "inner")

    with tempfile.TemporaryDirectory() as temp_path:
        popt.SetOutputDirectory(temp_path)

        # Plot layers
        for suffix, layer, description in plot_plan:
            pctl.SetLayer(layer)
            pctl.OpenPlotfile(suffix, pcbnew.PLOT_FORMAT_GERBER, description)
            pctl.PlotLayer()
            pctl.ClosePlot()

        # Generate drill file
        drlwriter = pcbnew.EXCELLON_WRITER(board)
        drlwriter.SetMapFileFormat(aMapFmt=pcbnew.PLOT_FORMAT_GERBER)
        drlwriter.SetOptions(aMirror=False,
                             aMinimalHeader=False,
                             aOffset=pcbnew.VECTOR2I(0, 0),
                             aMerge_PTH_NPTH=True)
        formatMetric = True
        drlwriter.SetFormat(formatMetric)
        drlwriter.CreateDrillandMapFilesSet(aPlotDirectory=temp_path,
                                            aGenDrill=True,
                                            aGenMap=False)

        # Copy files from output directory to in-memory zip file
        fp = io.BytesIO()
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as z:
            for root, dirs, files in os.walk(temp_path):
                for file in files:
                    z.write(
                        os.path.join(root, file),
                        # TODO(kleinpa): Required for JLCPCB, any alternative?
                        file.replace("gm1", "gko"))
        fp.seek(0)
        return fp


def main(argv):
    output = kicad_file_to_gerber_archive_file(FLAGS.input, FLAGS.output)


if __name__ == "__main__":
    app.run(main)
