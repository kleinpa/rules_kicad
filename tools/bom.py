"""Convert a .kicad_pcb file into a gerber archive ready for manufacturing."""

import csv
import io
import logging
import os
import shutil
from typing import OrderedDict, TextIO, List, Dict, Tuple

import sys

import pcbnew
from absl import app, flags

FLAGS = flags.FLAGS
flags.DEFINE_string('input', '', 'Path to .kicad_pcb file')
flags.DEFINE_string('output', '', 'Path to write .zip file containing gerbers')
flags.DEFINE_enum('format', 'csv', ['csv'], "Output format")

# A data file can be provided that contains additional fields for the
# BOM like manufacturer-specific part numbers. The CSV file must have
# columns 'Package' and 'Value' which will be used as a composite key
# to match against parts from the PCB. Parts that don't match a line
# this file will be excluded from the BOM.
flags.DEFINE_string(
    'component_file', '',
    'Path to .csv file containing extra information about parts to include on bom'
)

# Fields must be either listed in get_builtin_fields() below or
# provided by the component_file.
flags.DEFINE_list('fields', ['Designator', 'Package', 'Value'], '')

key_fields = ["Package", "Value"]

ComponentInfo = Dict[Tuple[str, ...], OrderedDict[str, str]]


def layer_to_name(layer: int):
    if layer == pcbnew.F_Cu:
        return "top"
    elif layer == pcbnew.B_Cu:
        return "bottom"
    else:
        raise ValueError(
            f"unknown name for layer: {pcbnew.BOARD_GetStandardLayerName(layer)}"
        )


def read_component_file(f: TextIO, key_fields=key_fields) -> ComponentInfo:
    """Read a CSV file and split fields into a composite key and remaining data."""
    component = {}
    reader = csv.DictReader(f)
    for field in key_fields:
        if not field in reader.fieldnames:
            raise ValueError(
                f"{f.name} does not contain required field {field}")
    for row in reader:
        key = tuple(row.pop(f) for f in key_fields)
        component[key] = row
    return component


def get_builtin_fields(footprint):
    return {
        'Designator': str(footprint.GetReference()),
        'Package': str(footprint.GetFPID().GetLibItemName()),
        'Value': str(footprint.GetValue()),
        'Mid X': str(footprint.GetPosition().x / pcbnew.PCB_IU_PER_MM),
        'Mid Y': str(-footprint.GetPosition().y / pcbnew.PCB_IU_PER_MM),
        'Rotation': str(footprint.GetOrientationDegrees()),
        'Layer': layer_to_name(footprint.GetLayer()),
    }


def make_bom(board: pcbnew.BOARD,
             field_names: List[str],
             component_info: ComponentInfo = {}):

    fp = io.StringIO()
    writer = csv.DictWriter(fp, fieldnames=field_names)
    writer.writeheader()

    for footprint in board.GetFootprints():
        bom_info = get_builtin_fields(footprint)
        key = tuple(bom_info[f] for f in key_fields)

        component_file_fields = {}
        if component_info:
            if key in component_info:
                # This is a hack, but treat Rotation as a special
                # column and add it's value to the value from KiCAD.
                for offset_field in ["Rotation"]:
                    bom_info[offset_field] = str(
                        float(bom_info[offset_field]) +
                        float(component_info[key].pop(offset_field, 0)))
                bom_info.update(component_info[key])
            else:
                logging.warning(f"missing part information for {key}")
                continue

        row = OrderedDict()

        # Copy requested fields to CSV file
        for field_name in field_names:
            if field_name in bom_info:
                row[field_name] = bom_info[field_name]
            else:
                raise ValueError(
                    f"unknown field '{field_name}' must be one of {list(bom_info.keys())}"
                )
        writer.writerow(row)

    fp.seek(0)
    return fp.read()


def main(argv):
    board = pcbnew.LoadBoard(FLAGS.input)
    if FLAGS.format == 'csv':
        component_info = {}
        if FLAGS.component_file:
            with open(FLAGS.component_file, "r") as f:
                component_info = read_component_file(f)
        with open(FLAGS.output, "w") as f:
            f.write(
                make_bom(board,
                         field_names=FLAGS.fields,
                         component_info=component_info))
    else:
        raise ValueError("unknown --format value")


if __name__ == "__main__":
    app.run(main)
