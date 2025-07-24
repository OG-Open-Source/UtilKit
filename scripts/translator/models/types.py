"""
This module defines the shared data models and type hints used across the translator application.
Using TypedDict ensures that configuration structures are consistent and provides static analysis benefits.
"""

from typing import Dict, List, TypedDict, Any

# Represents the configuration for a specific translator provider (e.g., OpenAI, Gemini).
# This is a flexible dictionary as different providers may have unique settings.
TranslatorConfig = Dict[str, Any]


class LanguageConfig(TypedDict):
    """
    Defines the source and target languages for translation.

    Attributes:
        source (str): The source language code (e.g., 'en').
        targets (List[str]): A list of target language codes (e.g., ['zh-Hant', 'ja']).
        map (Dict[str, str]): A mapping from local language codes to API-specific codes.
    """

    source: str
    targets: List[str]
    map: Dict[str, str]


class ExtractionRule(TypedDict):
    """
    Defines a rule for extracting a string from a file using regex.

    Attributes:
        pattern (str): The regular expression to find the string.
        capture_group (int): The index of the capturing group that contains the text to be translated.
    """

    pattern: str
    capture_group: int


class FileRule(TypedDict):
    """
    A complete rule set that associates files with extraction rules and a translator.

    Attributes:
        name (str): A descriptive name for this rule set.
        file_mapping (Dict[str, str]): A mapping from source file paths to their internationalized template paths.
        extraction_rules (List[ExtractionRule]): A list of rules to apply to the source files.
        translator (TranslatorConfig): The configuration for the translator to be used for this rule set.
    """

    name: str
    file_mapping: Dict[str, str]
    extraction_rules: List[ExtractionRule]
    translator: TranslatorConfig


class MainConfig(TypedDict, total=False):
    """
    Represents the top-level structure of the i18n-rules.yml configuration file.

    Attributes:
        languages (LanguageConfig): The global language settings.
        file_rules (List[FileRule]): A list of all file processing rules.
        output_dir (str): Optional. A custom output directory for compiled files.
    """

    languages: LanguageConfig
    file_rules: List[FileRule]
    output_dir: str
