"""
This module is responsible for compiling localized files by injecting
translated strings into template files.
"""

import os
import json
from typing import Dict, Any, Optional
from ..utils.file_utils import ReadTextFile, WriteTextFile, ReadJsonFile


def CompileFile(
    template_path_CompileFile: str,
    output_base_dir_CompileFile: str,
    custom_output_path_CompileFile: Optional[str] = None,
):
    """
    Generates a set of localized files from a single template file and its
    corresponding JSON translation file.

    Args:
        template_path_CompileFile (str): The absolute path to the internationalized template file.
        output_base_dir_CompileFile (str): The base directory where the 'localized' folder should be created.
    """
    # Ensure the template path is absolute by joining it with the output base directory if it's not already.
    if not os.path.isabs(template_path_CompileFile):
        template_path_CompileFile = os.path.join(
            output_base_dir_CompileFile, template_path_CompileFile
        )

    json_path_CompileFile = f"{template_path_CompileFile}.json"

    if not os.path.exists(template_path_CompileFile):
        print(f"Error: Template file not found at {template_path_CompileFile}")
        return
    if not os.path.exists(json_path_CompileFile):
        print(f"Error: JSON file not found at {json_path_CompileFile}")
        return

    print(
        f"--- Compiling localized files for: {os.path.basename(template_path_CompileFile)} ---"
    )

    template_content_CompileFile = ReadTextFile(template_path_CompileFile)
    translations_CompileFile = ReadJsonFile(json_path_CompileFile)

    base_dir_CompileFile = os.path.dirname(template_path_CompileFile)
    filename_CompileFile = os.path.basename(template_path_CompileFile)
    name_CompileFile, ext_CompileFile = os.path.splitext(filename_CompileFile)

    for (
        lang_CompileFile,
        lang_translations_CompileFile,
    ) in translations_CompileFile.items():
        localized_content_CompileFile = template_content_CompileFile

        # Replace all keys with the translations for the current language
        for key_CompileFile, text_CompileFile in lang_translations_CompileFile.items():
            placeholder_CompileFile = f'"*#{key_CompileFile}#*"'
            # Ensure the replacement text is properly escaped for a string context
            replacement_text_CompileFile = json.dumps(
                text_CompileFile, ensure_ascii=False
            )
            localized_content_CompileFile = localized_content_CompileFile.replace(
                placeholder_CompileFile, replacement_text_CompileFile
            )

        # Determine the final output directory.
        if custom_output_path_CompileFile:
            # If a custom path is provided, use it directly.
            # It's assumed to be relative to the project root, so we make it absolute.
            output_dir_CompileFile = os.path.abspath(custom_output_path_CompileFile)
        else:
            # Otherwise, use the default 'localized' subdirectory logic.
            output_dir_CompileFile = os.path.join(
                output_base_dir_CompileFile, "localized"
            )
        os.makedirs(output_dir_CompileFile, exist_ok=True)

        # Construct the new filename format: {name}_{lang}.{ext}
        name_part, ext_part = os.path.splitext(
            os.path.basename(template_path_CompileFile)
        )
        output_filename_CompileFile = f"{name_part}_{lang_CompileFile}{ext_part}"
        output_path_CompileFile = os.path.join(
            output_dir_CompileFile, output_filename_CompileFile
        )

        WriteTextFile(output_path_CompileFile, localized_content_CompileFile)
        print(f"Generated: {output_path_CompileFile.replace('\\', '/')}")
