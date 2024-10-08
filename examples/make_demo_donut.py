import shutil
import tempfile

import pcbnew
from absl import app, flags

FLAGS = flags.FLAGS
flags.DEFINE_string('output', '', 'Output path.')


def kicad_circle(x, y, diameter, layer=pcbnew.Edge_Cuts):
    """Create and return a KiCad circle centered at x, y."""

    item = pcbnew.PCB_SHAPE()
    item.SetShape(pcbnew.S_CIRCLE)
    item.SetCenter(pcbnew.VECTOR2I(x, y))
    item.SetRadius(diameter)
    item.SetLayer(layer)
    return item


def polygon_to_kicad_file():
    """Build a kicad file containing an empty PCB with the provided shape."""
    board = pcbnew.BOARD()

    board.Add(kicad_circle(0, 0, 100))

    board.Add(kicad_circle(0, 0, 50))

    tf = tempfile.NamedTemporaryFile()
    board.Save(tf.name)
    return tf


def main(argv):
    with open(FLAGS.output, 'wb') as output:
        shutil.copyfileobj(polygon_to_kicad_file(), output)


if __name__ == "__main__":
    app.run(main)
