"""
This module is responsible for extracting translatable strings from source files.
"""

import os
import re
from typing import Dict, Any, Tuple, List

from ..models.types import ExtractionRule
from ..utils.file_utils import ReadTextFile, WriteTextFile, ReadJsonFile, WriteJsonFile
from ..utils.helpers import GenerateRandomKey


def ExtractStringsFromFile(
    src_path_ExtractStringsFromFile: str,
    intl_path_ExtractStringsFromFile: str,
    extraction_rules_ExtractStringsFromFile: List[ExtractionRule],
    source_lang_ExtractStringsFromFile: str,
    config_path_ExtractStringsFromFile: str,
) -> Tuple[str, Dict[str, Any], Dict[str, str]]:
    """
    Extracts strings from a source file based on rules, replaces them with keys,
    updates a JSON file, and creates an internationalized template file.

    Args:
        src_path_ExtractStringsFromFile (str): Relative path to the source file.
        intl_path_ExtractStringsFromFile (str): Relative path for the output internationalized template.
        extraction_rules_ExtractStringsFromFile (List[ExtractionRule]): The regex-based rules for extraction.
        source_lang_ExtractStringsFromFile (str): The source language code.
        config_path_ExtractStringsFromFile (str): The absolute path to the config file, used to resolve relative paths.

    Returns:
        Tuple[str, Dict[str, Any]]: A tuple containing:
            - The absolute path to the updated JSON file.
            - The dictionary of all translations (updated with new strings).
    """
    # The base directory for resolving file_mapping paths should be the parent of the .ogos directory
    config_parent_dir = os.path.dirname(
        os.path.dirname(config_path_ExtractStringsFromFile)
    )

    # Construct absolute paths for both source and internationalized template files
    abs_src_path_ExtractStringsFromFile = os.path.abspath(
        os.path.join(config_parent_dir, src_path_ExtractStringsFromFile)
    )
    abs_intl_path_ExtractStringsFromFile = os.path.abspath(
        os.path.join(config_parent_dir, intl_path_ExtractStringsFromFile)
    )
    json_path_ExtractStringsFromFile = f"{abs_intl_path_ExtractStringsFromFile}.json"

    print(
        f"--- Processing file: {abs_src_path_ExtractStringsFromFile.replace('\\', '/')} ---"
    )

    content_ExtractStringsFromFile = ReadTextFile(abs_src_path_ExtractStringsFromFile)
    translations_ExtractStringsFromFile = ReadJsonFile(json_path_ExtractStringsFromFile)

    if source_lang_ExtractStringsFromFile not in translations_ExtractStringsFromFile:
        translations_ExtractStringsFromFile[source_lang_ExtractStringsFromFile] = {}

    source_translations_ExtractStringsFromFile = translations_ExtractStringsFromFile[
        source_lang_ExtractStringsFromFile
    ]
    value_to_key_map_ExtractStringsFromFile: Dict[str, str] = {
        v: k for k, v in source_translations_ExtractStringsFromFile.items()
    }

    updated_content_ExtractStringsFromFile = content_ExtractStringsFromFile
    new_strings_found_ExtractStringsFromFile = False
    new_strings_report = {}

    for rule_ExtractStringsFromFile in extraction_rules_ExtractStringsFromFile:
        pattern_ExtractStringsFromFile = re.compile(
            rule_ExtractStringsFromFile["pattern"]
        )
        for match_ExtractStringsFromFile in pattern_ExtractStringsFromFile.finditer(
            content_ExtractStringsFromFile
        ):
            original_string_ExtractStringsFromFile: str = (
                match_ExtractStringsFromFile.group(
                    rule_ExtractStringsFromFile["capture_group"]
                )
            )

            if not original_string_ExtractStringsFromFile:
                print(
                    f"Warning: Empty string captured by pattern: {rule_ExtractStringsFromFile['pattern']}. Skipping."
                )
                continue

            # Check if the string is a pure variable (e.g., $VAR, ${VAR})
            if re.fullmatch(r"\$\w+|\$\{\w+\}", original_string_ExtractStringsFromFile):
                print(
                    f"Info: Skipping pure variable: {original_string_ExtractStringsFromFile}"
                )
                continue

            if (
                original_string_ExtractStringsFromFile
                in value_to_key_map_ExtractStringsFromFile
            ):
                key_ExtractStringsFromFile: str = (
                    value_to_key_map_ExtractStringsFromFile[
                        original_string_ExtractStringsFromFile
                    ]
                )
            else:
                while True:
                    key_ExtractStringsFromFile = GenerateRandomKey()
                    if (
                        key_ExtractStringsFromFile
                        not in source_translations_ExtractStringsFromFile
                    ):
                        break
                source_translations_ExtractStringsFromFile[
                    key_ExtractStringsFromFile
                ] = original_string_ExtractStringsFromFile
                value_to_key_map_ExtractStringsFromFile[
                    original_string_ExtractStringsFromFile
                ] = key_ExtractStringsFromFile
                new_strings_found_ExtractStringsFromFile = True
                new_strings_report[key_ExtractStringsFromFile] = (
                    original_string_ExtractStringsFromFile
                )

            full_match_ExtractStringsFromFile: str = match_ExtractStringsFromFile.group(
                0
            )
            # A more robust replacement to handle different quoting styles
            replacement_ExtractStringsFromFile: (
                str
            ) = full_match_ExtractStringsFromFile.replace(
                f'"{original_string_ExtractStringsFromFile}"',
                f'"*#{key_ExtractStringsFromFile}#*"',
            ).replace(
                f"'{original_string_ExtractStringsFromFile}'",
                f'"*#{key_ExtractStringsFromFile}#*"',
            )
            updated_content_ExtractStringsFromFile = (
                updated_content_ExtractStringsFromFile.replace(
                    full_match_ExtractStringsFromFile,
                    replacement_ExtractStringsFromFile,
                )
            )

    WriteTextFile(
        abs_intl_path_ExtractStringsFromFile, updated_content_ExtractStringsFromFile
    )
    print(
        f"Generated internationalized file: {abs_intl_path_ExtractStringsFromFile.replace('\\', '/')}"
    )

    if new_strings_found_ExtractStringsFromFile:
        WriteJsonFile(
            json_path_ExtractStringsFromFile, translations_ExtractStringsFromFile
        )
        print(
            f"Updated translation JSON: {json_path_ExtractStringsFromFile.replace('\\', '/')}"
        )

    return (
        json_path_ExtractStringsFromFile,
        translations_ExtractStringsFromFile,
        new_strings_report,
    )
