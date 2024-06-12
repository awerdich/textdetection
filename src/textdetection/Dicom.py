"""
Andreas Werdich
Dicom Data Operations
"""

# Imports
import os
import numpy as np
import pandas as pd
import logging
import pydicom

from textdetection.fileutils import FileOP

# Logging
logger = logging.getLogger(__name__)



class DicOP:
    """
    Dicom File Operations
    """

    def __init__(self, image_dir=None, output_dir=None):
        self.image_dir = image_dir
        self.output_dir = output_dir

    def convert_type(self, val):
        """ Convert special pydicom types into python types
        Parameters:
            val, pydicom type object
        Returns:
            out, python type object
        """
        out = val
        if isinstance(val, pydicom.valuerep.PersonName):
            out = val.family_comma_given()
        if isinstance(val, pydicom.uid.UID):
            out = val.name
        if isinstance(val, pydicom.multival.MultiValue):
            out = tuple(val)
        return out

    def is_pydicom(self, ds):
        """ Check if ds object is pydicom dataset
        Parameters:
            ds, pydicom dataset
        Returns:
            is_dcm, bool
        """
        is_dcm = False
        try:
            assert isinstance(ds, pydicom.dataset.Dataset)
        except AssertionError as er:
            msg = f'Object is not a pydicom dataset.'
            logger.exception(msg)
        else:
            is_dcm = True
        return is_dcm

    def get_attribs_from_file(self, file, attrib_list):
        """
        Extract attributes from dicom file
        Parameters:
            file: list, file path to .dcm file
            attrib_list: list of dicom attributes
        Returns:
            output_dict, attribute:value pairs
        """
        dc = FileOP().load_file(file=file, kind='dicom')
        output_dict = {}
        if dc is not None and DicOP().is_pydicom(dc):
            for key in attrib_list:
                val = dc.get(key)
                if val is not None:
                    val = DicOP().convert_type(val=val)
                else:
                    val = np.nan
                output_dict.update({key: [val]})
        return output_dict
